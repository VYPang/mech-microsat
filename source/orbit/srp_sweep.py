"""Full-factorial SRP parameter sweep over inclination, area, c_R, and mass.

The sweep is append-safe: existing rows in the output Parquet are
preserved and only missing grid points are simulated.  This lets the
team extend the design ranges later without re-running prior points.
"""

from __future__ import annotations

import itertools
from dataclasses import dataclass
from pathlib import Path

import numpy as np
import polars as pl
from rich.console import Console
from rich.progress import BarColumn, Progress, TextColumn, TimeElapsedColumn, TimeRemainingColumn

from .srp_sim import run_srp_drift

console = Console()

# Columns that uniquely identify a sweep sample.  Used for de-duplication
# when appending new runs to an existing Parquet.
_KEY_COLS = (
    "epoch_utc",
    "inclination_deg",
    "duration_years",
    "timestep_s",
    "area_m2",
    "cr",
    "mass_kg",
)


@dataclass(frozen=True)
class GridAxis:
    """Linear grid on a single design variable."""

    name: str
    minimum: float
    maximum: float
    n: int

    def values(self) -> np.ndarray:
        return np.linspace(self.minimum, self.maximum, self.n)


@dataclass(frozen=True)
class SweepSpec:
    """Everything needed to enumerate and execute the design grid."""

    epoch_utc: str
    inclination_values_deg: tuple[float, ...]
    duration_years: float
    timestep_s: float
    area: GridAxis
    cr: GridAxis
    mass: GridAxis


def _enumerate_grid(spec: SweepSpec) -> list[dict]:
    """Cartesian product of all sweep axes as a list of design points."""
    rows = []
    for inclination, a, c, m in itertools.product(
        spec.inclination_values_deg,
        spec.area.values(),
        spec.cr.values(),
        spec.mass.values(),
    ):
        rows.append(
            {
                "epoch_utc": spec.epoch_utc,
                "inclination_deg": float(inclination),
                "duration_years": float(spec.duration_years),
                "timestep_s": float(spec.timestep_s),
                "area_m2": float(a),
                "cr": float(c),
                "mass_kg": float(m),
            }
        )
    return rows


def _missing_points(grid: list[dict], existing: pl.DataFrame | None) -> list[dict]:
    """Return grid points whose key tuple is not already present."""
    if existing is None or existing.is_empty():
        return grid
    seen = {
        tuple(row[k] for k in _KEY_COLS)
        for row in existing.select(_KEY_COLS).iter_rows(named=True)
    }
    return [pt for pt in grid if tuple(pt[k] for k in _KEY_COLS) not in seen]


def run_sweep(spec: SweepSpec, output_path: Path) -> pl.DataFrame:
    """Run the full-factorial sweep, appending new points to *output_path*.

    :param spec: Grid specification.
    :param output_path: Parquet file accumulating all sweep samples.
    :return: The full DataFrame on disk after the run.
    """
    output_path = Path(output_path)
    existing = pl.read_parquet(output_path) if output_path.exists() else None

    grid = _enumerate_grid(spec)
    todo = _missing_points(grid, existing)

    n_total = len(grid)
    n_existing = n_total - len(todo)
    console.print(
        f"[bold]Sweep:[/bold] {n_total} grid points  "
        f"([green]{n_existing} cached[/green], [yellow]{len(todo)} new[/yellow])"
    )

    if not todo:
        return existing if existing is not None else pl.DataFrame()

    new_rows: list[dict] = []
    with Progress(
        TextColumn("[bold green]Sweep"),
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
                    "dv_total_mps": result.dv_total_mps,
                    "dv_per_year_mps": result.dv_per_year_mps,
                }
            )
            progress.advance(task)

    new_df = pl.DataFrame(new_rows)
    full_df = pl.concat([existing, new_df]) if existing is not None else new_df

    output_path.parent.mkdir(parents=True, exist_ok=True)
    full_df.write_parquet(output_path)
    console.print(f"[dim]Wrote {len(full_df)} samples → {output_path}[/dim]")
    return full_df
