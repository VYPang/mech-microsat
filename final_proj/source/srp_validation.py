"""Same-β validation study for the SRP response-surface surrogate.

The 1-D surrogate in ``β = c_R · A / m`` rests on the assumption that
the integrated SRP-induced ΔV is a function of β alone.  This module
generates targeted Basilisk runs that hold β constant while varying
each design variable in turn, then checks how tightly the responses
collapse onto a single curve.

The validation is cached in its own Parquet file so re-running with
``--validate`` does not re-simulate previously verified points.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Literal

import numpy as np
import polars as pl
from rich.console import Console
from rich.progress import BarColumn, Progress, TextColumn, TimeElapsedColumn, TimeRemainingColumn

from .srp_sim import run_srp_drift
from .surrogate import ResponseSurface

console = Console()

Family = Literal["vary_area", "vary_cr", "vary_mass"]

_KEY_COLS = (
    "epoch_utc",
    "inclination_deg",
    "duration_years",
    "timestep_s",
    "family",
    "beta_target",
    "area_m2",
    "cr",
    "mass_kg",
)


@dataclass(frozen=True)
class ValidationSpec:
    """Inputs needed to enumerate the same-β sweep families."""

    epoch_utc: str
    inclination_deg: float
    duration_years: float
    timestep_s: float
    area_bounds: tuple[float, float]
    cr_bounds: tuple[float, float]
    mass_bounds: tuple[float, float]
    beta_targets: list[float]
    n_per_family: int


# ---------------------------------------------------------------------------
# Triplet construction
# ---------------------------------------------------------------------------


def _midpoint(bounds: tuple[float, float]) -> float:
    return 0.5 * (bounds[0] + bounds[1])


def _in_bounds(value: float, bounds: tuple[float, float]) -> bool:
    return bounds[0] <= value <= bounds[1]


def _build_family_points(spec: ValidationSpec, beta: float, family: Family) -> list[dict]:
    """Return the in-bounds (A, c_R, m) triplets for a single (β, family) pair.

    For each family we vary one design variable across its full range,
    fix a second variable at its mid-range value, and solve the third
    from the constraint ``c_R · A / m = β``.  Triplets that fall outside
    the configured design bounds are dropped.
    """
    rows: list[dict] = []
    n = spec.n_per_family

    if family == "vary_area":
        cr_fixed = _midpoint(spec.cr_bounds)
        for area in np.linspace(spec.area_bounds[0], spec.area_bounds[1], n):
            mass = cr_fixed * area / beta
            if _in_bounds(mass, spec.mass_bounds):
                rows.append({"area_m2": float(area), "cr": float(cr_fixed), "mass_kg": float(mass)})

    elif family == "vary_cr":
        area_fixed = _midpoint(spec.area_bounds)
        for cr in np.linspace(spec.cr_bounds[0], spec.cr_bounds[1], n):
            mass = cr * area_fixed / beta
            if _in_bounds(mass, spec.mass_bounds):
                rows.append({"area_m2": float(area_fixed), "cr": float(cr), "mass_kg": float(mass)})

    elif family == "vary_mass":
        cr_fixed = _midpoint(spec.cr_bounds)
        for mass in np.linspace(spec.mass_bounds[0], spec.mass_bounds[1], n):
            area = beta * mass / cr_fixed
            if _in_bounds(area, spec.area_bounds):
                rows.append({"area_m2": float(area), "cr": float(cr_fixed), "mass_kg": float(mass)})

    for r in rows:
        r["family"] = family
        r["beta_target"] = float(beta)
        r["epoch_utc"] = spec.epoch_utc
        r["inclination_deg"] = float(spec.inclination_deg)
        r["duration_years"] = float(spec.duration_years)
        r["timestep_s"] = float(spec.timestep_s)
    return rows


def _enumerate_validation_grid(spec: ValidationSpec) -> list[dict]:
    grid: list[dict] = []
    for beta in spec.beta_targets:
        for family in ("vary_area", "vary_cr", "vary_mass"):
            grid.extend(_build_family_points(spec, beta, family))  # type: ignore[arg-type]
    return grid


def _missing_points(grid: list[dict], existing: pl.DataFrame | None) -> list[dict]:
    if existing is None or existing.is_empty():
        return grid
    seen = {
        tuple(row[k] for k in _KEY_COLS)
        for row in existing.select(_KEY_COLS).iter_rows(named=True)
    }
    return [pt for pt in grid if tuple(pt[k] for k in _KEY_COLS) not in seen]


# ---------------------------------------------------------------------------
# Execution
# ---------------------------------------------------------------------------


def run_validation(spec: ValidationSpec, output_path: Path) -> pl.DataFrame:
    """Run the same-β validation study, appending to *output_path*."""
    output_path = Path(output_path)
    existing = pl.read_parquet(output_path) if output_path.exists() else None

    grid = _enumerate_validation_grid(spec)
    todo = _missing_points(grid, existing)
    n_total = len(grid)
    n_existing = n_total - len(todo)
    console.print(
        f"[bold]Validation:[/bold] {n_total} same-β points  "
        f"([green]{n_existing} cached[/green], [yellow]{len(todo)} new[/yellow])"
    )

    if not todo:
        return existing if existing is not None else pl.DataFrame()

    new_rows: list[dict] = []
    with Progress(
        TextColumn("[bold magenta]Validation"),
        BarColumn(bar_width=40),
        TextColumn("[progress.percentage]{task.percentage:>3.0f}%"),
        TextColumn("({task.completed}/{task.total})"),
        TimeElapsedColumn(),
        TimeRemainingColumn(),
        console=console,
    ) as progress:
        task = progress.add_task("running", total=len(todo))
        for pt in todo:
            result = run_srp_drift(
                epoch_utc=pt["epoch_utc"],
                duration_years=pt["duration_years"],
                timestep_s=pt["timestep_s"],
                inclination_deg=pt["inclination_deg"],
                mass_kg=pt["mass_kg"],
                area_m2=pt["area_m2"],
                cr=pt["cr"],
            )
            new_rows.append(
                {
                    **pt,
                    "beta_actual": pt["cr"] * pt["area_m2"] / pt["mass_kg"],
                    "dv_total_mps": result.dv_total_mps,
                    "dv_per_year_mps": result.dv_per_year_mps,
                }
            )
            progress.advance(task)

    new_df = pl.DataFrame(new_rows)
    full_df = pl.concat([existing, new_df]) if existing is not None else new_df

    output_path.parent.mkdir(parents=True, exist_ok=True)
    full_df.write_parquet(output_path)
    console.print(f"[dim]Wrote {len(full_df)} validation samples → {output_path}[/dim]")
    return full_df


# ---------------------------------------------------------------------------
# Plot (matplotlib, report-ready PNG)
# ---------------------------------------------------------------------------


_FAMILY_STYLE: dict[str, dict] = {
    "vary_area": {"label": r"vary $A$ (fix $c_R$, solve $m$)",   "marker": "o", "color": "#1f77b4"},
    "vary_cr":   {"label": r"vary $c_R$ (fix $A$, solve $m$)",   "marker": "s", "color": "#d62728"},
    "vary_mass": {"label": r"vary $m$ (fix $c_R$, solve $A$)",   "marker": "^", "color": "#2ca02c"},
}


def plot_validation(
    samples: pl.DataFrame,
    surrogate: ResponseSurface,
    output_path: Path,
) -> Path:
    """Two-panel academic PNG figure summarising the same-β study.

    Top panel: ΔV/yr vs β with the surrogate curve and per-family scatter.
    Bottom panel: relative residual of each Basilisk sample with respect
    to the surrogate prediction at the same β.
    """
    # Local import keeps matplotlib out of the import path for non-plot runs.
    import matplotlib.pyplot as plt

    plt.rcParams.update(
        {
            "font.family": "serif",
            "font.size": 11,
            "axes.labelsize": 12,
            "axes.titlesize": 13,
            "legend.fontsize": 10,
            "figure.dpi": 150,
            "savefig.dpi": 300,
            "axes.grid": True,
            "grid.alpha": 0.3,
        }
    )

    df = samples.sort("beta_actual")
    beta = df["beta_actual"].to_numpy()
    dv = df["dv_per_year_mps"].to_numpy()
    family_col = df["family"].to_numpy()

    beta_curve = np.linspace(beta.min(), beta.max(), 200)
    dv_curve = surrogate.predict_array(
        np.full_like(beta_curve, 1.0),
        beta_curve,
        np.full_like(beta_curve, 1.0),
    )

    dv_pred = surrogate.predict_array(
        np.full_like(beta, 1.0),
        beta,
        np.full_like(beta, 1.0),
    )
    # Avoid division-by-zero at β → 0 by clipping.
    safe_pred = np.where(np.abs(dv_pred) < 1e-12, 1e-12, dv_pred)
    rel_residual_pct = 100.0 * (dv - dv_pred) / safe_pred

    fig, (ax_top, ax_bot) = plt.subplots(
        2, 1, figsize=(7.5, 6.5), sharex=True,
        gridspec_kw={"height_ratios": [3, 1.4], "hspace": 0.08},
    )

    # ------- Top: response with surrogate -------
    ax_top.plot(
        beta_curve, dv_curve, color="black", lw=1.2, ls="--",
        label=f"Surrogate (deg {surrogate.degree}, $R^2={surrogate.r_squared:.4f}$)",
        zorder=1,
    )
    for family, style in _FAMILY_STYLE.items():
        mask = family_col == family
        if not mask.any():
            continue
        ax_top.scatter(
            beta[mask], dv[mask],
            marker=style["marker"], color=style["color"],
            edgecolor="black", linewidths=0.4, s=44,
            label=style["label"], zorder=3,
        )
    ax_top.set_ylabel(r"$\Delta V$ per year  [m/s/yr]")
    ax_top.set_title(
        r"Same-$\beta$ collapse test for the cannonball-SRP surrogate "
        r"($\beta = c_R\,A/m$)"
    )
    ax_top.legend(loc="upper left", framealpha=0.95)

    # ------- Bottom: relative residual -------
    ax_bot.axhline(0.0, color="black", lw=0.8)
    for family, style in _FAMILY_STYLE.items():
        mask = family_col == family
        if not mask.any():
            continue
        ax_bot.scatter(
            beta[mask], rel_residual_pct[mask],
            marker=style["marker"], color=style["color"],
            edgecolor="black", linewidths=0.4, s=36,
        )
    ax_bot.set_xlabel(r"$\beta = c_R\,A/m$  [m$^2$/kg]")
    ax_bot.set_ylabel(r"$(\Delta V - \widehat{\Delta V}) / \widehat{\Delta V}$  [%]")

    rms = float(np.sqrt(np.mean(rel_residual_pct ** 2)))
    max_abs = float(np.max(np.abs(rel_residual_pct)))
    ax_bot.text(
        0.99, 0.05,
        f"RMS deviation = {rms:.3f}%\nmax |dev| = {max_abs:.3f}%",
        transform=ax_bot.transAxes, ha="right", va="bottom",
        fontsize=9, family="serif",
        bbox=dict(facecolor="white", edgecolor="0.7", boxstyle="round,pad=0.3"),
    )

    fig.align_ylabels([ax_top, ax_bot])
    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_path, bbox_inches="tight")
    plt.close(fig)
    return output_path
