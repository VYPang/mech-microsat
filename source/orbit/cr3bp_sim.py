"""Basilisk N-body simulation of a satellite near Sun-Earth L4.

Sets up Sun (central) + Earth (perturber) with SPICE ephemeris,
propagates the spacecraft, and returns the trajectory as a polars
DataFrame stored in Parquet.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import polars as pl
from rich.console import Console
from rich.progress import BarColumn, Progress, TextColumn, TimeElapsedColumn, TimeRemainingColumn

from Basilisk.simulation import spacecraft
from Basilisk.utilities import SimulationBaseClass, macros
from Basilisk.utilities.simIncludeGravBody import gravBodyFactory

from .initial_conditions import compute_l4_state

console = Console()

# Number of progress-bar steps per simulation run.
_PROGRESS_STEPS = 200


def run_cr3bp_baseline(
    epoch_utc: str = "2025 JAN 01 00:00:00.0 (UTC)",
    duration_years: float = 10.0,
    timestep_s: float = 300.0,
    inclination_deg: float = 14.5,
    output_path: Path | None = None,
) -> pl.DataFrame:
    """Propagate a satellite at L4 in the Sun-Earth N-body problem.

    No SRP or other perturbations — this is the unperturbed CR3BP baseline.

    :param epoch_utc: Simulation start epoch (SPICE UTC string).
    :param duration_years: Propagation duration in Earth years.
    :param timestep_s: Integration / recording timestep in seconds.
    :param inclination_deg: Out-of-plane inclination for L4 orbit.
    :param output_path: If given, save the trajectory as a Parquet file.
    :return: polars DataFrame with columns t_s, x, y, z, vx, vy, vz (SI).
    """
    # ------------------------------------------------------------------
    # 1. Initial conditions
    # ------------------------------------------------------------------
    ic = compute_l4_state(epoch_utc, inclination_deg)
    r_au = ic.position_m / 1.496e11
    v_kms = ic.velocity_ms / 1e3
    console.print(f"[bold]L4 initial position[/bold]: [{r_au[0]:.4f}, {r_au[1]:.4f}, {r_au[2]:.4f}] AU")
    console.print(f"[bold]L4 initial velocity[/bold]: [{v_kms[0]:.3f}, {v_kms[1]:.3f}, {v_kms[2]:.3f}] km/s")

    # ------------------------------------------------------------------
    # 2. Create simulation
    # ------------------------------------------------------------------
    sim = SimulationBaseClass.SimBaseClass()

    proc_name = "dynProcess"
    task_name = "dynTask"
    dt_nano = macros.sec2nano(timestep_s)
    proc = sim.CreateNewProcess(proc_name)
    proc.addTask(sim.CreateNewTask(task_name, dt_nano))

    # ------------------------------------------------------------------
    # 3. Gravity bodies (Sun + Earth via SPICE)
    # ------------------------------------------------------------------
    grav_factory = gravBodyFactory()
    sun = grav_factory.createSun()
    sun.isCentralBody = True
    grav_factory.createEarth()
    spice_obj = grav_factory.createSpiceInterface(time=epoch_utc)
    sim.AddModelToTask(task_name, spice_obj)

    # ------------------------------------------------------------------
    # 4. Spacecraft
    # ------------------------------------------------------------------
    sc = spacecraft.Spacecraft()
    sc.ModelTag = "solSentinel"
    sc.hub.r_CN_NInit = ic.position_m.tolist()
    sc.hub.v_CN_NInit = ic.velocity_ms.tolist()
    sc.hub.mHub = 24.0  # kg (12U placeholder)
    grav_factory.addBodiesTo(sc)
    sim.AddModelToTask(task_name, sc)

    # ------------------------------------------------------------------
    # 5. State recorder
    # ------------------------------------------------------------------
    rec = sc.scStateOutMsg.recorder(dt_nano)
    sim.AddModelToTask(task_name, rec)

    # ------------------------------------------------------------------
    # 6. Execute with progress bar
    # ------------------------------------------------------------------
    duration_s = duration_years * 365.25 * 86400.0
    sim.InitializeSimulation()

    # Break the run into sub-steps so we can show a progress bar.
    n_steps = min(_PROGRESS_STEPS, max(1, int(duration_years)))
    step_s = duration_s / n_steps

    with Progress(
        TextColumn("[bold green]{task.description}"),
        BarColumn(bar_width=40),
        TextColumn("[progress.percentage]{task.percentage:>3.0f}%"),
        TimeElapsedColumn(),
        TimeRemainingColumn(),
        console=console,
    ) as progress:
        task = progress.add_task(
            f"Propagating {duration_years:.0f} yr", total=n_steps,
        )
        for i in range(n_steps):
            stop_ns = macros.sec2nano(min((i + 1) * step_s, duration_s))
            sim.ConfigureStopTime(stop_ns)
            sim.ExecuteSimulation()
            progress.advance(task)

    console.print("[bold green]Simulation complete.[/bold green]")

    # ------------------------------------------------------------------
    # 7. Extract results
    # ------------------------------------------------------------------
    times_ns = rec.times()
    times_s = times_ns * macros.NANO2SEC

    r = rec.r_BN_N  # (N, 3) in metres
    v = rec.v_BN_N  # (N, 3) in m/s

    df = pl.DataFrame(
        {
            "t_s": times_s,
            "x": r[:, 0],
            "y": r[:, 1],
            "z": r[:, 2],
            "vx": v[:, 0],
            "vy": v[:, 1],
            "vz": v[:, 2],
        }
    )

    if output_path is not None:
        output_path = Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        df.write_parquet(output_path)
        console.print(f"[dim]Saved trajectory → {output_path}[/dim]")

    return df
