#!/usr/bin/env python
"""Run one config-driven sizing solve for the Sol-Sentinel framework."""

from __future__ import annotations

import sys
from pathlib import Path

# Ensure the project root is importable
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

import typer
from rich.console import Console
from rich.table import Table

from final_proj.source.optimization import (
    build_configured_objectives,
    build_sol_sentinel_analysis,
    load_optimizer_initial_state,
)

DEFAULT_CONFIG = Path("final_proj/config/optimization_npt30_low_inc.json")
_CUBESAT_1U_FACE_AREA_M2 = 0.01

app = typer.Typer(add_completion=False)
console = Console()


def _format_float(value: float) -> str:
    return f"{value:.6g}"


def _solar_array_area_u_face_equivalent(area_m2: float) -> float:
    return area_m2 / _CUBESAT_1U_FACE_AREA_M2


def _build_table(title: str, rows: list[tuple[str, str]]) -> Table:
    table = Table(title=title, show_header=True)
    table.add_column("Quantity", style="cyan")
    table.add_column("Value", style="bold")
    for label, value in rows:
        table.add_row(label, value)
    return table


@app.command()
def main(
    config: Path = typer.Option(
        DEFAULT_CONFIG,
        "--config",
        "-c",
        help="Path to the optimization JSON config.",
    ),
    range_to_l4_m: float | None = typer.Option(
        None,
        "--range-to-l4-m",
        help="Override the configured Earth-to-L4 range input.",
    ),
    data_rate_bps: float | None = typer.Option(
        None,
        "--data-rate-bps",
        help="Override the configured data-rate input.",
    ),
) -> None:
    """Solve the current config for one converged spacecraft sizing point."""

    analysis = build_sol_sentinel_analysis(propulsion_config_source=config)
    inputs = load_optimizer_initial_state(config)
    if range_to_l4_m is not None:
        inputs["range_to_l4_m"] = range_to_l4_m
    if data_rate_bps is not None:
        inputs["data_rate_bps"] = data_rate_bps

    missing = [name for name in analysis.startup_inputs if name not in inputs]
    if missing:
        raise typer.BadParameter(f"Missing required startup inputs: {missing}")

    result = analysis.run(inputs)
    if not result.converged:
        console.print("[red]Design-point evaluation did not converge.[/red]")
        raise typer.Exit(code=1)

    state = result.state
    modules_by_name = {module.name: module for module in analysis.modules}

    power_diag = modules_by_name["power"].diagnostics(state)
    thermal_diag = modules_by_name["thermal"].diagnostics(state)
    propulsion_diag = modules_by_name["propulsion"].diagnostics(state)
    objectives = build_configured_objectives(config)
    objective_values = [
        (objective.name, _format_float(float(objective.evaluator(state))))
        for objective in objectives
    ]

    console.print(
        _build_table(
            "Sizing Solver Summary",
            [
                ("Converged", str(result.converged)),
                ("Iterations", str(result.iterations)),
                ("Total wet mass [kg]", _format_float(state.get("total_wet_mass_kg"))),
                ("Total volume [U]", _format_float(state.get("total_volume_u"))),
                ("Solar array area [m^2]", _format_float(state.get("solar_array_area_m2"))),
                (
                    "Solar array area [1U-face eq.]",
                    _format_float(_solar_array_area_u_face_equivalent(state.get("solar_array_area_m2"))),
                ),
                ("Effective reflectivity [-]", _format_float(state.get("effective_reflectivity"))),
                ("Delta-v [m/s/yr]", _format_float(state.get("delta_v_mps_per_year"))),
                ("Propellant mass [kg]", _format_float(state.get("propellant_mass_kg"))),
            ],
        )
    )
    console.print(_build_table("Objective Values", objective_values))
    console.print(
        _build_table(
            "Power Diagnostics",
            [
                ("Station-keeping load [W]", _format_float(power_diag["stationkeeping_load_w"])),
                ("Solar-array power during burn [W]", _format_float(power_diag["solar_array_power_during_burn_w"])),
                ("Battery power during burn [W]", _format_float(power_diag["battery_power_during_burn_w"])),
                ("Battery energy during burn [Wh]", _format_float(power_diag["battery_energy_during_burn_wh"])),
                ("Battery SOC after burn [-]", _format_float(power_diag["battery_soc_after_burn"])),
            ],
        )
    )
    console.print(
        _build_table(
            "Thermal Diagnostics",
            [
                ("Solar-array absorbed heat [W]", _format_float(thermal_diag["solar_array_absorbed_heat_w"])),
                ("Radiator area [m^2]", _format_float(thermal_diag["radiator_area_m2"])),
                ("Radiator area with margin [m^2]", _format_float(thermal_diag["radiator_area_with_margin_m2"])),
                ("Weighted reflectivity [-]", _format_float(thermal_diag["weighted_reflectivity"])),
                ("Cannonball c_R [-]", _format_float(thermal_diag["cannonball_reflectivity_coefficient"])),
            ],
        )
    )
    console.print(
        _build_table(
            "Propulsion Diagnostics",
            [
                ("Burn duration [s]", _format_float(propulsion_diag["burn_duration_s"])),
                ("Duty cycle [-]", _format_float(propulsion_diag["duty_cycle"])),
                ("Effective delta-v [m/s/yr]", _format_float(propulsion_diag["delta_v_effective_mps_per_year"])),
                ("Burn energy [Wh]", _format_float(propulsion_diag["burn_energy_wh"])),
            ],
        )
    )


if __name__ == "__main__":
    app()