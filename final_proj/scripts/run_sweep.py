#!/usr/bin/env python
"""Run the SRP parameter sweep, fit the surrogate, and plot the response surface.

The sweep is append-safe: re-running with an extended grid only simulates
the new design points, leaving previously cached samples untouched.

Usage:
    uv run python final_proj/scripts/run_sweep.py --config final_proj/config/sweep_low_inc.json
    uv run python final_proj/scripts/run_sweep.py --config <cfg> --fit-only   # skip simulation
    uv run python final_proj/scripts/run_sweep.py --config <cfg> --plot-only  # skip sim + fit
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

# Ensure project root is importable when run as a plain script.
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

import polars as pl
import typer
from rich.console import Console
from rich.table import Table

console = Console()
app = typer.Typer(add_completion=False)


def _load_cfg(path: Path) -> dict:
    cfg = json.loads(path.read_text())

    table = Table(title=f"Sweep config — {path.name}")
    table.add_column("Section", style="cyan")
    table.add_column("Key", style="cyan")
    table.add_column("Value", style="bold")
    for section, body in cfg.items():
        for k, v in body.items():
            table.add_row(section, k, str(v))
    console.print(table)
    return cfg


def _has_inclination_sweep(cfg: dict) -> bool:
    return "inclination_deg" in cfg.get("grid", {})


def _build_inclination_values(cfg: dict) -> tuple[float, ...]:
    grid = cfg["grid"]
    if "inclination_deg" not in grid:
        return (float(cfg["simulation"]["inclination_deg"]),)

    raw_axis = grid["inclination_deg"]
    minimum = float(raw_axis["min"])
    maximum = float(raw_axis["max"])
    step = float(raw_axis["step"])
    if step <= 0.0:
        raise ValueError(f"grid.inclination_deg.step must be positive; got {step}.")
    if maximum < minimum:
        raise ValueError(
            f"grid.inclination_deg.max must be >= min; got {maximum} < {minimum}."
        )

    values = []
    current = minimum
    tolerance = 0.5 * step
    while current <= maximum + tolerance:
        values.append(round(current, 10))
        current += step
    return tuple(float(value) for value in values)


def _build_spec(cfg: dict):
    from final_proj.source.orbit.srp_sweep import GridAxis, SweepSpec

    sim = cfg["simulation"]
    g = cfg["grid"]
    return SweepSpec(
        epoch_utc=sim["epoch_utc"],
        inclination_values_deg=_build_inclination_values(cfg),
        duration_years=float(sim["duration_years"]),
        timestep_s=float(sim["timestep_s"]),
        area=GridAxis("area_m2", g["area_m2"]["min"], g["area_m2"]["max"], int(g["area_m2"]["n"])),
        cr=GridAxis("cr",        g["cr"]["min"],      g["cr"]["max"],      int(g["cr"]["n"])),
        mass=GridAxis("mass_kg", g["mass_kg"]["min"], g["mass_kg"]["max"], int(g["mass_kg"]["n"])),
    )


@app.command()
def main(
    config: Path = typer.Option(..., "--config", "-c", help="Sweep config JSON."),
    fit_only: bool = typer.Option(False, "--fit-only", help="Skip simulation; refit from existing parquet."),
    plot_only: bool = typer.Option(False, "--plot-only", help="Skip simulation and fitting."),
    validate: bool = typer.Option(
        False, "--validate",
        help="Run same-β validation study and produce the academic PNG figure.",
    ),
    validate_plot_only: bool = typer.Option(
        False, "--validate-plot-only",
        help="Skip validation simulations; regenerate the validation PNG only.",
    ),
) -> None:
    from final_proj.source.orbit.srp_sweep import run_sweep
    from final_proj.source.orbit.srp_validation import (
        ValidationSpec,
        plot_validation,
        run_validation,
    )
    from final_proj.source.orbit.surrogate import ResponseSurface, fit_response_surface
    from final_proj.source.orbit.surrogate_plot import plot_response_surface, plot_response_surface_png

    cfg = _load_cfg(config)
    samples_path = Path(cfg["output"]["samples_parquet"])
    surrogate_path = Path(cfg["output"]["surrogate_json"])
    plot_path = Path(cfg["output"]["plot_html"])
    plot_png_path = Path(cfg["output"].get("plot_png", str(plot_path.with_suffix(".png"))))
    degree = int(cfg["surrogate"]["degree"])
    inclination_values = _build_inclination_values(cfg)

    # ----- Validation-only fast paths --------------------------------
    if validate or validate_plot_only:
        if _has_inclination_sweep(cfg):
            console.print(
                "[red]Same-β validation currently supports a single inclination only. "
                "Use a fixed simulation.inclination_deg config for validation runs.[/red]"
            )
            raise typer.Exit(code=1)
        if "validation" not in cfg:
            console.print("[red]Config has no 'validation' section.[/red]")
            raise typer.Exit(code=1)
        if not surrogate_path.exists():
            console.print(
                f"[red]Cannot run validation without a fitted surrogate at {surrogate_path}. "
                "Run the main sweep first.[/red]"
            )
            raise typer.Exit(code=1)

        # The drift metric ΔV/yr produced by run_srp_drift depends on the
        # propagation horizon (TotalAccumDV oscillates with the orbit), so the
        # validation must use the same `duration_years` as the training sweep.
        if samples_path.exists():
            train_durations = (
                pl.read_parquet(samples_path)
                .select("duration_years")
                .unique()
                .to_series()
                .to_list()
            )
            sim_dur = float(cfg["simulation"]["duration_years"])
            mismatch = [d for d in train_durations if abs(float(d) - sim_dur) > 1e-9]
            if mismatch:
                console.print(
                    f"[red]Validation duration_years={sim_dur} does not match the "
                    f"surrogate's training durations {train_durations}. "
                    "Set the same duration_years in the sweep config and retry.[/red]"
                )
                raise typer.Exit(code=1)

        sim = cfg["simulation"]
        g = cfg["grid"]
        v = cfg["validation"]
        spec = ValidationSpec(
            epoch_utc=sim["epoch_utc"],
            inclination_deg=float(sim["inclination_deg"]),
            duration_years=float(sim["duration_years"]),
            timestep_s=float(sim["timestep_s"]),
            area_bounds=(float(g["area_m2"]["min"]), float(g["area_m2"]["max"])),
            cr_bounds=(float(g["cr"]["min"]), float(g["cr"]["max"])),
            mass_bounds=(float(g["mass_kg"]["min"]), float(g["mass_kg"]["max"])),
            beta_targets=[float(b) for b in v["beta_targets"]],
            n_per_family=int(v["n_per_family"]),
        )
        val_samples_path = Path(v["samples_parquet"])
        val_plot_path = Path(v["plot_png"])

        if validate_plot_only:
            if not val_samples_path.exists():
                console.print(f"[red]No validation samples at {val_samples_path}.[/red]")
                raise typer.Exit(code=1)
            val_df = pl.read_parquet(val_samples_path)
        else:
            val_df = run_validation(spec, val_samples_path)

        surrogate = ResponseSurface.from_json(surrogate_path)
        out = plot_validation(val_df, surrogate, val_plot_path)
        console.print(f"[dim]Wrote validation figure → {out}[/dim]")
        console.print("[bold green]Validation done.[/bold green]")
        raise typer.Exit()

    # 1. Sweep (or load).
    if plot_only or fit_only:
        if not samples_path.exists():
            console.print(f"[red]No samples at {samples_path}[/red]")
            raise typer.Exit(code=1)
        df = pl.read_parquet(samples_path)
    else:
        spec = _build_spec(cfg)
        df = run_sweep(spec, samples_path)

    # 2. Fit (or load).
    if plot_only:
        surrogate = ResponseSurface.from_json(surrogate_path)
    else:
        surrogate = fit_response_surface(df, degree=degree)
        surrogate.to_json(surrogate_path)
        if len(inclination_values) > 1:
            console.print(
                f"[bold green]Surrogate surface:[/bold green] degree {surrogate.degree}, "
                f"R²={surrogate.r_squared:.4f}, n={surrogate.n_samples}, "
                f"inclinations={len(surrogate.inclination_nodes_deg)} "
                f"({surrogate.inclination_nodes_deg[0]:.3f}° → "
                f"{surrogate.inclination_nodes_deg[-1]:.3f}°)"
            )
        else:
            console.print(
                f"[bold green]Surrogate:[/bold green] degree {surrogate.degree}, "
                f"R²={surrogate.r_squared:.4f}, n={surrogate.n_samples}, "
                f"coeffs={[f'{c:.4e}' for c in surrogate.coefficients]}"
            )
        console.print(f"[dim]Wrote surrogate → {surrogate_path}[/dim]")

    # 3. Plot.
    out_html = plot_response_surface(df, surrogate, plot_path)
    out_png = plot_response_surface_png(df, surrogate, plot_png_path)
    console.print(f"[dim]Wrote interactive plot → {out_html}[/dim]")
    console.print(f"[dim]Wrote static figure → {out_png}[/dim]")
    console.print("[bold green]All done.[/bold green]")


if __name__ == "__main__":
    app()
