#!/usr/bin/env python
"""Run the CR3BP baseline simulation and produce rotating-frame plots.

Reads parameters from a JSON config file so you can tune inclination,
duration, etc. by editing the config rather than retyping CLI flags.

Usage:
    uv run python final_proj/scripts/run_baseline.py
    uv run python final_proj/scripts/run_baseline.py --config final_proj/config/config.json
    uv run python final_proj/scripts/run_baseline.py --help
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

# Ensure the project root is importable
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

import numpy as np
import typer
from rich.console import Console
from rich.table import Table

_DEFAULT_CONFIG = Path("final_proj/config/config.json")

console = Console()

app = typer.Typer(add_completion=False)


def _load_config(path: Path) -> dict:
    """Load and return the JSON config, printing a summary table."""
    with open(path) as f:
        cfg = json.load(f)

    for section_name in ("simulation", "visualization"):
        section = cfg.get(section_name, {})
        if not section:
            continue
        table = Table(title=f"{section_name.capitalize()} — {path.name}", show_header=True)
        table.add_column("Parameter", style="cyan")
        table.add_column("Value", style="bold")
        for k, v in section.items():
            table.add_row(k, str(v))
        console.print(table)
    return cfg


def _print_orbit_info(epoch_utc: str, inclination_deg: float) -> None:
    """Compute and print L4 + Earth state vectors for transfer orbit design."""
    from final_proj.source.orbit.initial_conditions import compute_l4_state

    ic = compute_l4_state(epoch_utc, inclination_deg)

    _AU = 1.496e11  # m

    table = Table(
        title=f"Orbit Info — epoch {epoch_utc}, inc {inclination_deg}°",
        show_header=True,
    )
    table.add_column("Quantity", style="cyan")
    table.add_column("x", style="bold", justify="right")
    table.add_column("y", style="bold", justify="right")
    table.add_column("z", style="bold", justify="right")
    table.add_column("|mag|", style="bold", justify="right")

    def _row(label: str, vec: np.ndarray, unit: str, scale: float = 1.0) -> None:
        v = vec / scale
        mag = float(np.linalg.norm(v))
        table.add_row(
            f"{label} ({unit})",
            f"{v[0]:.6f}",
            f"{v[1]:.6f}",
            f"{v[2]:.6f}",
            f"{mag:.6f}",
        )

    _row("L4 position",      ic.position_m,       "AU",   _AU)
    _row("L4 position",      ic.position_m,       "km",   1e3)
    _row("L4 velocity",      ic.velocity_ms,      "km/s", 1e3)
    _row("Earth position",   ic.earth_position_m, "AU",   _AU)
    _row("Earth position",   ic.earth_position_m, "km",   1e3)
    _row("Earth velocity",   ic.earth_velocity_ms,"km/s", 1e3)

    console.print(table)

    # Separation
    sep_m = np.linalg.norm(ic.position_m - ic.earth_position_m)
    console.print(
        f"\n[bold]Earth → L4 separation[/bold]: {sep_m / _AU:.6f} AU  "
        f"({sep_m / 1e3:.1f} km)"
    )
    dv = np.linalg.norm(ic.velocity_ms - ic.earth_velocity_ms)
    console.print(
        f"[bold]ΔV (Earth → L4)[/bold]: {dv / 1e3:.3f} km/s"
    )


@app.command()
def main(
    config: Path = typer.Option(
        _DEFAULT_CONFIG, "--config", "-c",
        help="Path to JSON config file.",
    ),
    viz_only: bool = typer.Option(
        False, "--viz-only",
        help="Skip simulation; load existing parquet and just re-plot.",
    ),
    info: bool = typer.Option(
        False, "--info",
        help="Print L4 initial state and Earth state, then exit.",
    ),
) -> None:
    """Simulate a CubeSat at Sun-Earth L4, transform to rotating frame, and plot."""
    import polars as pl
    import spiceypy as spice

    from final_proj.source.orbit.cr3bp_sim import run_cr3bp_baseline
    from final_proj.source.orbit.initial_conditions import _ensure_spice_kernels, compute_l4_state
    from final_proj.source.orbit.rotating_frame import to_rotating_frame
    from final_proj.source.orbit.visualize import create_all_plots

    cfg = _load_config(config)

    sim = cfg["simulation"]
    viz = cfg["visualization"]

    epoch = sim["epoch_utc"]
    duration_years = sim["duration_years"]
    timestep = sim["timestep_s"]
    inclination = sim["inclination_deg"]

    # --info: print orbital data and exit
    if info:
        _print_orbit_info(epoch, inclination)
        raise typer.Exit()

    output_dir = Path(viz["output_dir"])
    inertial_pts = viz.get("inertial_3d_points", 2000)
    rotating_pts = viz.get("rotating_3d_points", 50000)

    parquet_path = output_dir / "cr3bp_baseline.parquet"
    plot_dir = output_dir / "plots"

    # 1. Simulate or load existing data
    if viz_only:
        console.print(f"[yellow]Loading saved data from {parquet_path}[/yellow]")
        df = pl.read_parquet(parquet_path)
    else:
        df = run_cr3bp_baseline(
            epoch_utc=epoch,
            duration_years=duration_years,
            timestep_s=timestep,
            inclination_deg=inclination,
            output_path=parquet_path,
        )

    # 2. Transform to rotating frame
    # Reset SPICE state in case BSK left it dirty after a long run.
    spice.reset()
    import final_proj.source.orbit.initial_conditions as _ic_mod
    _ic_mod._KERNELS_LOADED = False
    _ensure_spice_kernels()
    epoch_et = spice.str2et(epoch)
    console.print("Transforming to rotating frame …")
    df = to_rotating_frame(df, epoch_et)

    # 3. Generate plots
    console.print("Generating plots …")
    paths = create_all_plots(
        df, plot_dir, inclination,
        inertial_max_points=inertial_pts,
        rotating_max_points=rotating_pts,
    )
    for p in paths:
        console.print(f"  [dim]{p}[/dim]")
    console.print("[bold green]All done.[/bold green]")


if __name__ == "__main__":
    app()
