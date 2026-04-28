#!/usr/bin/env python
"""Run a first config-parameter optimization for the Sol-Sentinel framework."""

from __future__ import annotations

import copy
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

# Ensure the project root is importable
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

import typer
from rich.console import Console
from rich.table import Table
from scipy.optimize import minimize

from final_proj.source.optimization import (
    CommsConfig,
    PowerConfig,
    PropulsionConfig,
    ThermalConfig,
    build_configured_objectives,
    build_sol_sentinel_analysis,
    load_optimizer_initial_state,
    load_orbit_surrogate_path,
)

DEFAULT_CONFIG = Path("final_proj/config/optimization_npt30_low_inc.json")
_CUBESAT_1U_FACE_AREA_M2 = 0.01

app = typer.Typer(add_completion=False)
console = Console()


@dataclass(frozen=True)
class ConfigDesignVariable:
    name: str
    config_path: str
    lower: float
    upper: float
    initial: float


def _format_float(value: float) -> str:
    return f"{value:.6g}"


def _solar_array_area_u_face_equivalent(area_m2: float) -> float:
    return area_m2 / _CUBESAT_1U_FACE_AREA_M2


def _load_payload(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text())


def _load_design_variables(payload: dict[str, Any]) -> tuple[ConfigDesignVariable, ...]:
    raw_variables = payload.get("optimizer", {}).get("design_variables", [])
    if not raw_variables:
        raise ValueError(
            "optimizer.design_variables is empty. The current config is set up for the sizing solver only; "
            "run final_proj/scripts/run_design_point.py or add outer design variables before using run_optimization.py."
        )
    return tuple(
        ConfigDesignVariable(
            name=str(raw_variable["name"]),
            config_path=str(raw_variable["config_path"]),
            lower=float(raw_variable["lower"]),
            upper=float(raw_variable["upper"]),
            initial=float(raw_variable["initial"]),
        )
        for raw_variable in raw_variables
    )


def _set_nested_value(payload: dict[str, Any], dotted_path: str, value: float) -> None:
    keys = dotted_path.split(".")
    target = payload
    for key in keys[:-1]:
        target = target[key]
    target[keys[-1]] = value


def _build_analysis_from_payload(config_path: Path, payload: dict[str, Any]):
    return build_sol_sentinel_analysis(
        surrogate_source=load_orbit_surrogate_path(config_path),
        comms_config_source=CommsConfig.from_mapping(payload.get("comms", {})),
        power_config_source=PowerConfig.from_mapping(payload["power"]),
        thermal_config_source=ThermalConfig.from_mapping(payload["thermal"]),
        propulsion_config_source=PropulsionConfig.from_mapping(payload),
    )


def _evaluate_candidate(
    vector: list[float],
    *,
    config_path: Path,
    base_payload: dict[str, Any],
    design_variables: tuple[ConfigDesignVariable, ...],
    base_inputs: dict[str, float],
    objective_name: str,
) -> tuple[float, dict[str, Any]]:
    payload = copy.deepcopy(base_payload)
    for design_variable, value in zip(design_variables, vector, strict=True):
        _set_nested_value(payload, design_variable.config_path, float(value))

    analysis = _build_analysis_from_payload(config_path, payload)
    result = analysis.run(dict(base_inputs))
    if not result.converged:
        return 1.0e12, {"converged": False, "analysis_result": result, "payload": payload}

    objective_value = float(result.state.get("total_wet_mass_kg"))
    return objective_value, {
        "converged": True,
        "analysis_result": result,
        "payload": payload,
        "objective_name": objective_name,
        "objective_value": objective_value,
    }


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
    method: str = typer.Option(
        "SLSQP",
        "--method",
        help="SciPy optimizer method.",
    ),
    maxiter: int = typer.Option(
        40,
        "--maxiter",
        help="Maximum number of optimizer iterations.",
    ),
) -> None:
    """Optimize the current config-driven design variables."""

    base_payload = _load_payload(config)
    design_variables = _load_design_variables(base_payload)
    objectives = build_configured_objectives(config)
    primary_objective = objectives[0]
    objective_name = primary_objective.name

    base_inputs = load_optimizer_initial_state(config)
    if range_to_l4_m is not None:
        base_inputs["range_to_l4_m"] = range_to_l4_m
    if data_rate_bps is not None:
        base_inputs["data_rate_bps"] = data_rate_bps

    baseline_vector = [design_variable.initial for design_variable in design_variables]
    baseline_value, baseline_info = _evaluate_candidate(
        baseline_vector,
        config_path=config,
        base_payload=base_payload,
        design_variables=design_variables,
        base_inputs=base_inputs,
        objective_name=objective_name,
    )

    evaluation_counter = {"count": 0}
    latest_info: dict[str, Any] = baseline_info

    def objective_function(vector: list[float]) -> float:
        evaluation_counter["count"] += 1
        nonlocal latest_info
        value, info = _evaluate_candidate(
            list(vector),
            config_path=config,
            base_payload=base_payload,
            design_variables=design_variables,
            base_inputs=base_inputs,
            objective_name=objective_name,
        )
        latest_info = info
        return value

    optimization_result = minimize(
        objective_function,
        x0=baseline_vector,
        method=method,
        bounds=[(design_variable.lower, design_variable.upper) for design_variable in design_variables],
        options={"maxiter": maxiter, "disp": False},
    )

    final_value, final_info = _evaluate_candidate(
        [float(value) for value in optimization_result.x],
        config_path=config,
        base_payload=base_payload,
        design_variables=design_variables,
        base_inputs=base_inputs,
        objective_name=objective_name,
    )

    if not final_info["converged"]:
        console.print("[red]Optimization finished on a non-converged design point.[/red]")
        raise typer.Exit(code=1)

    final_state = final_info["analysis_result"].state
    console.print(
        _build_table(
            "Optimization Summary",
            [
                ("Method", method),
                ("SciPy success", str(bool(optimization_result.success))),
                ("SciPy status", str(optimization_result.status)),
                ("Message", str(optimization_result.message)),
                ("Function evaluations", str(evaluation_counter["count"])),
                ("Baseline objective [kg]", _format_float(float(baseline_value))),
                ("Optimized objective [kg]", _format_float(float(final_value))),
                ("Total wet mass [kg]", _format_float(final_state.get("total_wet_mass_kg"))),
                ("Total volume [U]", _format_float(final_state.get("total_volume_u"))),
            ],
        )
    )
    console.print(
        _build_table(
            "Optimized Design Variables",
            [
                (
                    f"{design_variable.name} ({design_variable.config_path})",
                    _format_float(float(value)),
                )
                for design_variable, value in zip(design_variables, optimization_result.x, strict=True)
            ],
        )
    )
    console.print(
        _build_table(
            "Optimized State Highlights",
            [
                ("Solar array area [m^2]", _format_float(final_state.get("solar_array_area_m2"))),
                (
                    "Solar array area [1U-face eq.]",
                    _format_float(_solar_array_area_u_face_equivalent(final_state.get("solar_array_area_m2"))),
                ),
                ("Effective reflectivity [-]", _format_float(final_state.get("effective_reflectivity"))),
                ("Delta-v [m/s/yr]", _format_float(final_state.get("delta_v_mps_per_year"))),
                ("Burn duration [s]", _format_float(final_state.get("burn_duration_s"))),
                ("Propellant mass [kg]", _format_float(final_state.get("propellant_mass_kg"))),
            ],
        )
    )


if __name__ == "__main__":
    app()