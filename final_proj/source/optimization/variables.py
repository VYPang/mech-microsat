"""Canonical optimization variables for the Sol-Sentinel XDSM."""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class VariableDefinition:
    """Metadata for one optimizer-level variable."""

    name: str
    symbol: str
    unit: str
    description: str
    producer: str | None = None


def _build_registry(definitions: tuple[VariableDefinition, ...]) -> dict[str, VariableDefinition]:
    registry: dict[str, VariableDefinition] = {}
    for definition in definitions:
        if definition.name in registry:
            raise ValueError(f"Duplicate variable name: {definition.name}")
        registry[definition.name] = definition
    return registry


SOL_SENTINEL_VARIABLES: tuple[VariableDefinition, ...] = (
    VariableDefinition("range_to_l4_m", "R_{L4}", "m", "Earth-to-L4 communication range.", "optimizer"),
    VariableDefinition("data_rate_bps", "DataRate", "bit/s", "Science or housekeeping downlink rate.", "optimizer"),
    VariableDefinition("payload_power_w", "P_{payload}", "W", "Payload electrical load.", "optimizer"),
    VariableDefinition("temperature_requirement_k", "T_{req}", "K", "Thermal design-point temperature.", "optimizer"),
    VariableDefinition("payload_mass_kg", "M_{payload}", "kg", "Payload mass carried into the budget loop.", "optimizer"),
    VariableDefinition("payload_volume_u", "V_{payload}", "U", "Payload volume carried into the budget loop.", "optimizer"),
    VariableDefinition("tx_power_w", "P_{tx}", "W", "Communications transmitter power.", "comms"),
    VariableDefinition("comms_mass_kg", "M_{com}", "kg", "Communications subsystem mass.", "comms"),
    VariableDefinition("comms_volume_u", "V_{com}", "U", "Communications subsystem volume.", "comms"),
    VariableDefinition("solar_array_area_m2", "A_{sa}", "m^2", "Solar-array area passed to power and orbit.", "power"),
    VariableDefinition("power_dissipated_w", "P_{dissipated}", "W", "Waste heat from the power subsystem.", "power"),
    VariableDefinition("power_mass_kg", "M_{pwr}", "kg", "Power subsystem mass.", "power"),
    VariableDefinition("power_volume_u", "V_{pwr}", "U", "Power subsystem volume.", "power"),
    VariableDefinition("effective_reflectivity", "\\rho_{s}", "-", "Equivalent surface reflectivity fraction used by Thermal; Orbit maps it to c_R = 1 + \\rho_s for the SRP model.", "thermal"),
    VariableDefinition("thermal_mass_kg", "M_{thm}", "kg", "Thermal subsystem mass.", "thermal"),
    VariableDefinition("thermal_volume_u", "V_{thm}", "U", "Thermal subsystem volume.", "thermal"),
    VariableDefinition("delta_v_mps_per_year", "\\Delta V_{avg}", "m/s/yr", "Orbit maintenance burden from the SRP surrogate.", "orbit"),
    VariableDefinition("ballistic_coefficient_m2_per_kg", "\\beta", "m^2/kg", "Collapsed SRP scaling variable.", "orbit"),
    VariableDefinition("orbit_mass_for_srp_kg", "M_{orb}", "kg", "Mass used internally by the orbit surrogate.", "orbit"),
    VariableDefinition("propulsion_power_w", "P_{ion}", "W", "Propulsion electrical draw.", "propulsion"),
    VariableDefinition("burn_duration_s", "t_{burn}", "s", "Station-keeping burn duration promoted from Propulsion for EPS sizing.", "propulsion"),
    VariableDefinition("propellant_mass_kg", "M_{prop}", "kg", "Propellant mass required by the propulsion model.", "propulsion"),
    VariableDefinition("propulsion_mass_kg", "M_{prop,sys}", "kg", "Propulsion hardware dry mass.", "propulsion"),
    VariableDefinition("propulsion_volume_u", "V_{prop}", "U", "Propulsion subsystem volume.", "propulsion"),
    VariableDefinition("total_wet_mass_kg", "M_{tot}", "kg", "Total spacecraft wet mass from the budget closure.", "budget"),
    VariableDefinition("total_volume_u", "V_{tot}", "U", "Total spacecraft packed volume from the budget closure.", "budget"),
)


VARIABLE_REGISTRY = _build_registry(SOL_SENTINEL_VARIABLES)