"""System-specific assembly helpers for the Sol-Sentinel optimization loop."""

from __future__ import annotations

import json
from pathlib import Path

from final_proj.source.orbit.surrogate import ResponseSurface

from .analysis import FixedPointAnalysis
from .comms_module import CommsConfig, build_fixed_comms_module
from .equations import Equation
from .modules import DisciplineModule, EquationModule, PlaceholderModule
from .orbit_module import OrbitSurrogateModule
from .power_thermal_module import (
    PowerConfig,
    ThermalConfig,
    build_hot_case_thermal_module,
    build_stationkeeping_power_module,
)
from .problem import Objective
from .propulsion_module import PropulsionConfig, build_fixed_thruster_propulsion_module
from .state import SystemState

OPTIMIZER_INPUTS: tuple[str, ...] = (
    "range_to_l4_m",
    "data_rate_bps",
    "payload_power_w",
    "temperature_requirement_k",
    "payload_mass_kg",
    "payload_volume_u",
)

COUPLED_VARIABLES: tuple[str, ...] = (
    "tx_power_w",
    "solar_array_area_m2",
    "power_dissipated_w",
    "effective_reflectivity",
    "delta_v_mps_per_year",
    "propulsion_power_w",
    "burn_duration_s",
    "propellant_mass_kg",
    "propulsion_mass_kg",
    "propulsion_volume_u",
    "total_wet_mass_kg",
    "total_volume_u",
)

_MASS_INPUTS: tuple[str, ...] = (
    "payload_mass_kg",
    "comms_mass_kg",
    "power_mass_kg",
    "thermal_mass_kg",
    "propulsion_mass_kg",
    "propellant_mass_kg",
)

_VOLUME_INPUTS: tuple[str, ...] = (
    "payload_volume_u",
    "comms_volume_u",
    "power_volume_u",
    "thermal_volume_u",
    "propulsion_volume_u",
)


def _sum_variables(state: SystemState, variables: tuple[str, ...]) -> float:
    return sum(state.get(variable) for variable in variables)


def _load_surrogate(source: ResponseSurface | Path) -> ResponseSurface:
    if isinstance(source, ResponseSurface):
        return source
    return ResponseSurface.from_json(Path(source))


def _load_optimizer_payload(source: Path) -> dict:
    return json.loads(Path(source).read_text())


def _resolve_config_path(config_source: Path, raw_path: str | Path) -> Path:
    candidate = Path(raw_path)
    if candidate.is_absolute():
        return candidate

    search_roots = [config_source.parent, *config_source.parents]
    for root in search_roots:
        resolved = root / candidate
        if resolved.exists():
            return resolved
    return config_source.parent / candidate


def _build_state_metric_objective(metric_name: str) -> Objective:
    return Objective(
        name=f"minimize_{metric_name}",
        evaluator=lambda state, name=metric_name: state.get(name),
        sense="min",
    )


def load_optimizer_fixed_inputs(source: Path) -> dict[str, float]:
    payload = _load_optimizer_payload(source)
    fixed_inputs: dict[str, float] = {}

    optimizer_section = payload.get("optimizer", {})
    analysis_inputs_section = optimizer_section.get("analysis_inputs", {})
    if "range_to_l4_m" in analysis_inputs_section:
        fixed_inputs["range_to_l4_m"] = float(analysis_inputs_section["range_to_l4_m"])
    if "data_rate_bps" in analysis_inputs_section:
        fixed_inputs["data_rate_bps"] = float(analysis_inputs_section["data_rate_bps"])

    payload_section = payload.get("payload", {})
    if "power_w" in payload_section:
        fixed_inputs["payload_power_w"] = float(payload_section["power_w"])
    if "mass_kg" in payload_section:
        fixed_inputs["payload_mass_kg"] = float(payload_section["mass_kg"])
    if "volume_u" in payload_section:
        fixed_inputs["payload_volume_u"] = float(payload_section["volume_u"])

    thermal_section = payload.get("thermal", {})
    if "temperature_requirement_k" in thermal_section:
        fixed_inputs["temperature_requirement_k"] = float(thermal_section["temperature_requirement_k"])

    return fixed_inputs


def load_orbit_surrogate_path(source: Path) -> Path:
    payload = _load_optimizer_payload(source)
    orbit_section = payload.get("orbit", {})
    raw_path = orbit_section.get("surrogate_json_path")
    if raw_path is None:
        raise KeyError(
            "Optimizer config is missing orbit.surrogate_json_path needed to load the SRP surrogate."
        )
    return _resolve_config_path(Path(source), str(raw_path))


def load_optimizer_startup_seeds(source: Path) -> dict[str, float]:
    payload = _load_optimizer_payload(source)
    seed_payload = payload.get("optimizer", {}).get("startup_seed", {})
    return {str(name): float(value) for name, value in seed_payload.items()}


def load_optimizer_initial_state(source: Path) -> dict[str, float]:
    initial_state = load_optimizer_fixed_inputs(source)
    initial_state.update(load_optimizer_startup_seeds(source))
    return initial_state


def build_configured_objectives(source: Path) -> tuple[Objective, ...]:
    payload = _load_optimizer_payload(source)
    objective_payload = payload.get("optimizer", {}).get("objective", {})
    primary_metric = str(objective_payload.get("primary_metric", "total_wet_mass_kg"))
    include_total_volume_objective = bool(
        objective_payload.get("include_total_volume_objective", False)
    )

    supported_metrics = {"total_wet_mass_kg", "total_volume_u"}
    if primary_metric not in supported_metrics:
        raise ValueError(
            f"Unsupported optimizer primary_metric '{primary_metric}'. "
            f"Expected one of {sorted(supported_metrics)}."
        )

    objectives = [_build_state_metric_objective(primary_metric)]
    if include_total_volume_objective and primary_metric != "total_volume_u":
        objectives.append(_build_state_metric_objective("total_volume_u"))
    return tuple(objectives)


def build_comms_placeholder() -> PlaceholderModule:
    return PlaceholderModule(
        name="comms",
        required_inputs=("range_to_l4_m", "data_rate_bps"),
        provided_outputs=("tx_power_w", "comms_mass_kg", "comms_volume_u"),
        note="Replace with the link-budget equations once the comms team finishes the module.",
    )


def build_power_placeholder() -> PlaceholderModule:
    return PlaceholderModule(
        name="power",
        required_inputs=("payload_power_w", "tx_power_w", "propulsion_power_w"),
        provided_outputs=(
            "solar_array_area_m2",
            "power_dissipated_w",
            "power_mass_kg",
            "power_volume_u",
        ),
        note="Replace with power-generation and storage sizing equations.",
    )


def build_thermal_placeholder() -> PlaceholderModule:
    return PlaceholderModule(
        name="thermal",
        required_inputs=("temperature_requirement_k", "solar_array_area_m2", "power_dissipated_w"),
        provided_outputs=("effective_reflectivity", "thermal_mass_kg", "thermal_volume_u"),
        note="Replace with radiator sizing and optical-property equations.",
    )


def build_propulsion_placeholder() -> PlaceholderModule:
    return PlaceholderModule(
        name="propulsion",
        required_inputs=("delta_v_mps_per_year", "total_wet_mass_kg"),
        provided_outputs=(
            "propulsion_power_w",
            "burn_duration_s",
            "propellant_mass_kg",
            "propulsion_mass_kg",
            "propulsion_volume_u",
        ),
        note="Replace with thruster, tank, and propellant sizing equations.",
    )


def build_budget_module() -> EquationModule:
    return EquationModule(
        name="budget",
        description="Closes the mass and volume totals used in the fixed-point loop.",
        equations=(
            Equation(
                name="total wet mass",
                output="total_wet_mass_kg",
                inputs=_MASS_INPUTS,
                evaluator=lambda state: _sum_variables(state, _MASS_INPUTS),
            ),
            Equation(
                name="total packed volume",
                output="total_volume_u",
                inputs=_VOLUME_INPUTS,
                evaluator=lambda state: _sum_variables(state, _VOLUME_INPUTS),
            ),
        ),
    )


def build_sol_sentinel_analysis(
    surrogate_source: ResponseSurface | Path | None = None,
    *,
    comms_module: DisciplineModule | None = None,
    comms_config_source: CommsConfig | Path | None = None,
    power_module: DisciplineModule | None = None,
    thermal_module: DisciplineModule | None = None,
    propulsion_module: DisciplineModule | None = None,
    power_config_source: PowerConfig | Path | None = None,
    thermal_config_source: ThermalConfig | Path | None = None,
    propulsion_config_source: PropulsionConfig | Path | None = None,
    budget_module: DisciplineModule | None = None,
    tolerance: float = 1e-6,
    max_iterations: int = 25,
) -> FixedPointAnalysis:
    shared_config_source = next(
        (
            source
            for source in (
                comms_config_source,
                power_config_source,
                thermal_config_source,
                propulsion_config_source,
            )
            if isinstance(source, Path)
        ),
        None,
    )

    resolved_surrogate_source = surrogate_source
    if resolved_surrogate_source is None:
        if shared_config_source is None:
            raise ValueError(
                "build_sol_sentinel_analysis requires either surrogate_source or a config path "
                "that defines orbit.surrogate_json_path."
            )
        resolved_surrogate_source = load_orbit_surrogate_path(shared_config_source)

    orbit_module = OrbitSurrogateModule(_load_surrogate(resolved_surrogate_source))

    resolved_comms_module = comms_module
    if resolved_comms_module is None and comms_config_source is not None:
        resolved_comms_module = build_fixed_comms_module(comms_config_source)
    elif resolved_comms_module is None and shared_config_source is not None:
        resolved_comms_module = build_fixed_comms_module(shared_config_source)

    resolved_power_module = power_module
    if resolved_power_module is None and power_config_source is not None:
        resolved_power_module = build_stationkeeping_power_module(power_config_source)
    elif resolved_power_module is None and shared_config_source is not None:
        resolved_power_module = build_stationkeeping_power_module(shared_config_source)

    resolved_thermal_module = thermal_module
    if resolved_thermal_module is None and thermal_config_source is not None:
        resolved_thermal_module = build_hot_case_thermal_module(thermal_config_source)
    elif resolved_thermal_module is None and shared_config_source is not None:
        resolved_thermal_module = build_hot_case_thermal_module(shared_config_source)

    resolved_propulsion_module = propulsion_module
    if resolved_propulsion_module is None and propulsion_config_source is not None:
        resolved_propulsion_module = build_fixed_thruster_propulsion_module(propulsion_config_source)
    return FixedPointAnalysis(
        modules=(
            resolved_comms_module or build_comms_placeholder(),
            resolved_power_module or build_power_placeholder(),
            resolved_thermal_module or build_thermal_placeholder(),
            orbit_module,
            resolved_propulsion_module or build_propulsion_placeholder(),
            budget_module or build_budget_module(),
        ),
        coupled_variables=COUPLED_VARIABLES,
        tolerance=tolerance,
        max_iterations=max_iterations,
    )