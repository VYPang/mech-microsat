"""CLI entrypoint for Sol-Sentinel CR3BP baseline simulation.

Usage:
    uv run python -m final_proj.source.cli simulate --duration-years 10
    uv run python -m final_proj.source.cli visualize --data-path output/cr3bp_baseline.parquet
"""

from __future__ import annotations

from pathlib import Path
from typing import Annotated

import typer
from rich.console import Console

app = typer.Typer(
    name="sol-sentinel",
    help="CR3BP baseline orbit simulation for a CubeSat at Sun-Earth L4.",
    no_args_is_help=True,
)

console = Console()


# -- Shared option aliases ---------------------------------------------------

DurationYears = Annotated[
    float,
    typer.Option("--duration-years", "-d", help="Propagation duration in Earth years."),
]
InclinationDeg = Annotated[
    float,
    typer.Option("--inclination", "-i", help="Out-of-plane inclination in degrees."),
]
Timestep = Annotated[
    float,
    typer.Option("--timestep", "-t", help="Integration / recording timestep in seconds."),
]
Epoch = Annotated[
    str,
    typer.Option("--epoch", "-e", help="Simulation start epoch (SPICE UTC string)."),
]
OutputDir = Annotated[
    Path,
    typer.Option("--output-dir", "-o", help="Directory for output files."),
]


# -- Commands ----------------------------------------------------------------


@app.command()
def simulate(
    duration_years: DurationYears = 10.0,
    inclination: InclinationDeg = 14.5,
    timestep: Timestep = 300.0,
    epoch: Epoch = "2025 JAN 01 00:00:00.0 (UTC)",
    output_dir: OutputDir = Path("final_proj/output"),
) -> None:
    """Run the CR3BP baseline simulation and save trajectory."""
    from .cr3bp_sim import run_cr3bp_baseline

    parquet_path = output_dir / "cr3bp_baseline.parquet"

    run_cr3bp_baseline(
        epoch_utc=epoch,
        duration_years=duration_years,
        timestep_s=timestep,
        inclination_deg=inclination,
        output_path=parquet_path,
    )
    console.print(f"[bold green]Done.[/bold green] Trajectory saved to {parquet_path}")


@app.command()
def visualize(
    data_path: Annotated[
        Path,
        typer.Option("--data-path", "-f", help="Path to the trajectory Parquet file."),
    ] = Path("final_proj/output/cr3bp_baseline.parquet"),
    output_dir: OutputDir = Path("final_proj/output/plots"),
    inclination: InclinationDeg = 14.5,
    epoch: Epoch = "2025 JAN 01 00:00:00.0 (UTC)",
) -> None:
    """Transform trajectory to rotating frame and produce Plotly plots."""
    import polars as pl
    import spiceypy as spice

    from .initial_conditions import _ensure_spice_kernels
    from .rotating_frame import to_rotating_frame
    from .visualize import create_all_plots

    if not data_path.exists():
        console.print(f"[red]File not found:[/red] {data_path}")
        raise typer.Exit(code=1)

    console.print(f"Loading trajectory from {data_path} …")
    df = pl.read_parquet(data_path)

    _ensure_spice_kernels()
    epoch_et = spice.str2et(epoch)

    console.print("Transforming to rotating frame …")
    df = to_rotating_frame(df, epoch_et)

    console.print("Generating plots …")
    paths = create_all_plots(df, output_dir, inclination)
    for p in paths:
        console.print(f"  [dim]{p}[/dim]")
    console.print("[bold green]Visualisation complete.[/bold green]")


@app.command()
def run_all(
    duration_years: DurationYears = 10.0,
    inclination: InclinationDeg = 14.5,
    timestep: Timestep = 300.0,
    epoch: Epoch = "2025 JAN 01 00:00:00.0 (UTC)",
    output_dir: OutputDir = Path("final_proj/output"),
) -> None:
    """Simulate, transform, and visualise in one go."""
    import spiceypy as spice

    from .cr3bp_sim import run_cr3bp_baseline
    from .initial_conditions import _ensure_spice_kernels
    from .rotating_frame import to_rotating_frame
    from .visualize import create_all_plots

    parquet_path = output_dir / "cr3bp_baseline.parquet"
    plot_dir = output_dir / "plots"

    # 1. Simulate
    df = run_cr3bp_baseline(
        epoch_utc=epoch,
        duration_years=duration_years,
        timestep_s=timestep,
        inclination_deg=inclination,
        output_path=parquet_path,
    )

    # 2. Rotating frame
    _ensure_spice_kernels()
    epoch_et = spice.str2et(epoch)
    console.print("Transforming to rotating frame …")
    df = to_rotating_frame(df, epoch_et)

    # 3. Plots
    console.print("Generating plots …")
    paths = create_all_plots(df, plot_dir, inclination)
    for p in paths:
        console.print(f"  [dim]{p}[/dim]")
    console.print("[bold green]All done.[/bold green]")


if __name__ == "__main__":
    app()
