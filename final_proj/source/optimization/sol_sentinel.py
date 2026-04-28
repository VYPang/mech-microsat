"""System-specific assembly helpers for the Sol-Sentinel optimization loop."""

from __future__ import annotations

from pathlib import Path

from final_proj.source.orbit.surrogate import ResponseSurface

from .analysis import FixedPointAnalysis
from .equations import Equation
from .modules import DisciplineModule, EquationModule, PlaceholderModule
from .orbit_module import OrbitSurrogateModule
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
    surrogate_source: ResponseSurface | Path,
    *,
    comms_module: DisciplineModule | None = None,
    power_module: DisciplineModule | None = None,
    thermal_module: DisciplineModule | None = None,
    propulsion_module: DisciplineModule | None = None,
    propulsion_config_source: PropulsionConfig | Path | None = None,
    budget_module: DisciplineModule | None = None,
    tolerance: float = 1e-6,
    max_iterations: int = 25,
) -> FixedPointAnalysis:
    orbit_module = OrbitSurrogateModule(_load_surrogate(surrogate_source))
    resolved_propulsion_module = propulsion_module
    if resolved_propulsion_module is None and propulsion_config_source is not None:
        resolved_propulsion_module = build_fixed_thruster_propulsion_module(propulsion_config_source)
    return FixedPointAnalysis(
        modules=(
            comms_module or build_comms_placeholder(),
            power_module or build_power_placeholder(),
            thermal_module or build_thermal_placeholder(),
            orbit_module,
            resolved_propulsion_module or build_propulsion_placeholder(),
            budget_module or build_budget_module(),
        ),
        coupled_variables=COUPLED_VARIABLES,
        tolerance=tolerance,
        max_iterations=max_iterations,
    )