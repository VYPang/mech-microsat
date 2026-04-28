"""Config-driven Power and Thermal modules for the Sol-Sentinel optimizer."""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

from .state import SystemState

_STEFAN_BOLTZMANN_W_PER_M2K4 = 5.6696e-8
_HOURS_PER_DAY = 24.0
_DEFAULT_SOLAR_ARRAY_CONVERSION_EFFICIENCY = 0.2586


def _require_positive(value: float, name: str) -> float:
    if value <= 0.0:
        raise ValueError(f"{name} must be positive; got {value}.")
    return value


def _require_non_negative(value: float, name: str) -> float:
    if value < 0.0:
        raise ValueError(f"{name} must be non-negative; got {value}.")
    return value


def _require_fraction(value: float, name: str) -> float:
    if not 0.0 <= value <= 1.0:
        raise ValueError(f"{name} must be between 0 and 1; got {value}.")
    return value


@dataclass(frozen=True)
class PowerConfig:
    """Fixed assumptions used by the first station-keeping EPS model."""

    stationkeeping_base_load_w: float
    solar_flux_w_per_m2: float
    battery_capacity_wh: float
    battery_max_discharge_current_a: float
    battery_min_soc_after_burn: float
    battery_support_voltage_v: float
    correction_cadence_days: float
    eta_cell: float
    eta_temp: float
    eta_rad: float
    eta_mppt: float
    eta_wiring: float
    solar_array_areal_mass_density_kg_per_m2: float
    minimum_solar_array_area_m2: float = 0.0
    dc_conversion_efficiency: float = 1.0
    eps_fixed_mass_kg: float = 0.0
    battery_mass_kg: float = 0.0
    eps_fixed_volume_u: float = 0.0
    battery_volume_u: float = 0.0
    solar_array_packed_volume_per_m2_u: float = 0.0

    def __post_init__(self) -> None:
        _require_non_negative(self.stationkeeping_base_load_w, "stationkeeping_base_load_w")
        _require_positive(self.solar_flux_w_per_m2, "solar_flux_w_per_m2")
        _require_positive(self.battery_capacity_wh, "battery_capacity_wh")
        _require_positive(self.battery_max_discharge_current_a, "battery_max_discharge_current_a")
        _require_fraction(self.battery_min_soc_after_burn, "battery_min_soc_after_burn")
        _require_positive(self.battery_support_voltage_v, "battery_support_voltage_v")
        _require_positive(self.correction_cadence_days, "correction_cadence_days")
        _require_fraction(self.eta_cell, "eta_cell")
        _require_fraction(self.eta_temp, "eta_temp")
        _require_fraction(self.eta_rad, "eta_rad")
        _require_fraction(self.eta_mppt, "eta_mppt")
        _require_fraction(self.eta_wiring, "eta_wiring")
        _require_non_negative(
            self.solar_array_areal_mass_density_kg_per_m2,
            "solar_array_areal_mass_density_kg_per_m2",
        )
        _require_non_negative(self.minimum_solar_array_area_m2, "minimum_solar_array_area_m2")
        _require_fraction(self.dc_conversion_efficiency, "dc_conversion_efficiency")
        _require_non_negative(self.eps_fixed_mass_kg, "eps_fixed_mass_kg")
        _require_non_negative(self.battery_mass_kg, "battery_mass_kg")
        _require_non_negative(self.eps_fixed_volume_u, "eps_fixed_volume_u")
        _require_non_negative(self.battery_volume_u, "battery_volume_u")
        _require_non_negative(
            self.solar_array_packed_volume_per_m2_u,
            "solar_array_packed_volume_per_m2_u",
        )

    @property
    def total_efficiency(self) -> float:
        efficiency = (
            self.eta_cell
            * self.eta_temp
            * self.eta_rad
            * self.eta_mppt
            * self.eta_wiring
        )
        _require_positive(efficiency, "total_efficiency")
        return efficiency

    @property
    def usable_battery_energy_wh(self) -> float:
        return (1.0 - self.battery_min_soc_after_burn) * self.battery_capacity_wh

    @property
    def battery_power_limit_w(self) -> float:
        return (
            self.dc_conversion_efficiency
            * self.battery_support_voltage_v
            * self.battery_max_discharge_current_a
        )

    @property
    def correction_cadence_h(self) -> float:
        return self.correction_cadence_days * _HOURS_PER_DAY

    @classmethod
    def from_mapping(cls, payload: dict) -> PowerConfig:
        return cls(
            stationkeeping_base_load_w=float(payload["stationkeeping_base_load_w"]),
            solar_flux_w_per_m2=float(payload["solar_flux_w_per_m2"]),
            battery_capacity_wh=float(payload["battery_capacity_wh"]),
            battery_max_discharge_current_a=float(payload["battery_max_discharge_current_a"]),
            battery_min_soc_after_burn=float(payload["battery_min_soc_after_burn"]),
            battery_support_voltage_v=float(payload["battery_support_voltage_v"]),
            correction_cadence_days=float(payload["correction_cadence_days"]),
            eta_cell=float(payload["eta_cell"]),
            eta_temp=float(payload["eta_temp"]),
            eta_rad=float(payload["eta_rad"]),
            eta_mppt=float(payload["eta_mppt"]),
            eta_wiring=float(payload["eta_wiring"]),
            solar_array_areal_mass_density_kg_per_m2=float(
                payload["solar_array_areal_mass_density_kg_per_m2"]
            ),
            minimum_solar_array_area_m2=float(payload.get("minimum_solar_array_area_m2", 0.0)),
            dc_conversion_efficiency=float(payload.get("dc_conversion_efficiency", 1.0)),
            eps_fixed_mass_kg=float(payload.get("eps_fixed_mass_kg", 0.0)),
            battery_mass_kg=float(payload.get("battery_mass_kg", 0.0)),
            eps_fixed_volume_u=float(payload.get("eps_fixed_volume_u", 0.0)),
            battery_volume_u=float(payload.get("battery_volume_u", 0.0)),
            solar_array_packed_volume_per_m2_u=float(
                payload.get("solar_array_packed_volume_per_m2_u", 0.0)
            ),
        )

    @classmethod
    def from_json(cls, path: Path) -> PowerConfig:
        payload = json.loads(Path(path).read_text())
        return cls.from_mapping(payload["power"])


def load_power_config(source: PowerConfig | Path) -> PowerConfig:
    if isinstance(source, PowerConfig):
        return source
    return PowerConfig.from_json(Path(source))


@dataclass(frozen=True)
class ThermalConfig:
    """Fixed assumptions used by the first hot-case thermal model."""

    solar_flux_w_per_m2: float
    temperature_requirement_k: float
    emissivity_osr: float
    absorptivity_osr: float
    solar_array_conversion_efficiency: float = _DEFAULT_SOLAR_ARRAY_CONVERSION_EFFICIENCY
    alpha_sa_front: float = 0.88
    alpha_sa_back: float = 0.08
    rho_sa_front: float = 0.12
    rho_sa_back: float = 0.92
    fixed_body_reflectivity_area_m2: float = 0.0
    fixed_body_exposed_area_m2: float = 0.0
    phi_sa_front: float = 1.0
    phi_sa_back: float = 0.0
    radiator_area_margin_fraction: float = 0.20
    mass_kg: float = 0.0
    volume_u: float = 0.0

    def __post_init__(self) -> None:
        _require_positive(self.solar_flux_w_per_m2, "solar_flux_w_per_m2")
        _require_positive(self.temperature_requirement_k, "temperature_requirement_k")
        _require_fraction(self.emissivity_osr, "emissivity_osr")
        _require_fraction(self.absorptivity_osr, "absorptivity_osr")
        _require_fraction(
            self.solar_array_conversion_efficiency,
            "solar_array_conversion_efficiency",
        )
        _require_fraction(self.alpha_sa_front, "alpha_sa_front")
        _require_fraction(self.alpha_sa_back, "alpha_sa_back")
        _require_fraction(self.rho_sa_front, "rho_sa_front")
        _require_fraction(self.rho_sa_back, "rho_sa_back")
        _require_non_negative(
            self.fixed_body_reflectivity_area_m2,
            "fixed_body_reflectivity_area_m2",
        )
        _require_non_negative(
            self.fixed_body_exposed_area_m2,
            "fixed_body_exposed_area_m2",
        )
        if self.fixed_body_reflectivity_area_m2 > self.fixed_body_exposed_area_m2:
            raise ValueError(
                "fixed_body_reflectivity_area_m2 must not exceed "
                f"fixed_body_exposed_area_m2; got {self.fixed_body_reflectivity_area_m2} "
                f"> {self.fixed_body_exposed_area_m2}."
            )
        _require_fraction(self.phi_sa_front, "phi_sa_front")
        _require_fraction(self.phi_sa_back, "phi_sa_back")
        _require_non_negative(
            self.radiator_area_margin_fraction,
            "radiator_area_margin_fraction",
        )
        _require_non_negative(self.mass_kg, "mass_kg")
        _require_non_negative(self.volume_u, "volume_u")

    @classmethod
    def from_mapping(cls, payload: dict) -> ThermalConfig:
        return cls(
            solar_flux_w_per_m2=float(payload["solar_flux_w_per_m2"]),
            temperature_requirement_k=float(payload["temperature_requirement_k"]),
            emissivity_osr=float(payload["emissivity_osr"]),
            absorptivity_osr=float(payload["absorptivity_osr"]),
            solar_array_conversion_efficiency=float(
                payload.get(
                    "solar_array_conversion_efficiency",
                    _DEFAULT_SOLAR_ARRAY_CONVERSION_EFFICIENCY,
                )
            ),
            alpha_sa_front=float(payload.get("alpha_sa_front", 0.88)),
            alpha_sa_back=float(payload.get("alpha_sa_back", 0.08)),
            rho_sa_front=float(payload.get("rho_sa_front", 0.12)),
            rho_sa_back=float(payload.get("rho_sa_back", 0.92)),
            fixed_body_reflectivity_area_m2=float(
                payload.get("fixed_body_reflectivity_area_m2", 0.0)
            ),
            fixed_body_exposed_area_m2=float(payload.get("fixed_body_exposed_area_m2", 0.0)),
            phi_sa_front=float(payload.get("phi_sa_front", 1.0)),
            phi_sa_back=float(payload.get("phi_sa_back", 0.0)),
            radiator_area_margin_fraction=float(payload.get("radiator_area_margin_fraction", 0.20)),
            mass_kg=float(payload.get("mass_kg", 0.0)),
            volume_u=float(payload.get("volume_u", 0.0)),
        )

    @classmethod
    def from_json(cls, path: Path) -> ThermalConfig:
        payload = json.loads(Path(path).read_text())
        thermal_payload = dict(payload["thermal"])
        if "solar_array_conversion_efficiency" not in thermal_payload:
            power_payload = payload.get("power", {})
            efficiency_keys = ("eta_cell", "eta_temp", "eta_rad", "eta_mppt", "eta_wiring")
            if all(key in power_payload for key in efficiency_keys):
                thermal_payload["solar_array_conversion_efficiency"] = (
                    float(power_payload["eta_cell"])
                    * float(power_payload["eta_temp"])
                    * float(power_payload["eta_rad"])
                    * float(power_payload["eta_mppt"])
                    * float(power_payload["eta_wiring"])
                )
        return cls.from_mapping(thermal_payload)


def load_thermal_config(source: ThermalConfig | Path) -> ThermalConfig:
    if isinstance(source, ThermalConfig):
        return source
    return ThermalConfig.from_json(Path(source))


@dataclass(frozen=True)
class StationkeepingPowerModule:
    """Power module sized for the station-keeping burn mode."""

    config: PowerConfig
    name: str = "power"
    propulsion_power_variable: str = "propulsion_power_w"
    burn_duration_variable: str = "burn_duration_s"
    solar_array_area_variable: str = "solar_array_area_m2"
    power_dissipated_variable: str = "power_dissipated_w"
    power_mass_variable: str = "power_mass_kg"
    power_volume_variable: str = "power_volume_u"

    @classmethod
    def from_config_source(cls, source: PowerConfig | Path) -> StationkeepingPowerModule:
        return cls(config=load_power_config(source))

    @property
    def required_inputs(self) -> tuple[str, ...]:
        return (self.propulsion_power_variable, self.burn_duration_variable)

    @property
    def provided_outputs(self) -> tuple[str, ...]:
        return (
            self.solar_array_area_variable,
            self.power_dissipated_variable,
            self.power_mass_variable,
            self.power_volume_variable,
        )

    def _stationkeeping_load_w(self, state: SystemState) -> float:
        return self.config.stationkeeping_base_load_w + state.get(self.propulsion_power_variable)

    def _burn_duration_h(self, state: SystemState) -> float:
        return max(0.0, state.get(self.burn_duration_variable) / 3600.0)

    def _area_from_power_w(self, power_w: float) -> float:
        return max(0.0, power_w) / (self.config.solar_flux_w_per_m2 * self.config.total_efficiency)

    def _energy_limited_area_m2(self, state: SystemState) -> float:
        burn_duration_h = self._burn_duration_h(state)
        if burn_duration_h <= 0.0:
            return 0.0
        required_array_power = self._stationkeeping_load_w(state) - (
            self.config.usable_battery_energy_wh / burn_duration_h
        )
        return self._area_from_power_w(required_array_power)

    def _power_limited_area_m2(self, state: SystemState) -> float:
        required_array_power = self._stationkeeping_load_w(state) - self.config.battery_power_limit_w
        return self._area_from_power_w(required_array_power)

    def _recharge_limited_area_m2(self, state: SystemState) -> float:
        burn_duration_h = self._burn_duration_h(state)
        cadence_h = self.config.correction_cadence_h
        if cadence_h <= 0.0:
            return 0.0
        if burn_duration_h >= cadence_h:
            return self._area_from_power_w(self._stationkeeping_load_w(state))
        required_array_power = (
            self.config.stationkeeping_base_load_w * (cadence_h - burn_duration_h)
            + self._stationkeeping_load_w(state) * burn_duration_h
        ) / cadence_h
        return self._area_from_power_w(required_array_power)

    def _required_solar_array_area_m2(self, state: SystemState) -> float:
        return max(
            self.config.minimum_solar_array_area_m2,
            self._energy_limited_area_m2(state),
            self._power_limited_area_m2(state),
            self._recharge_limited_area_m2(state),
        )

    def diagnostics(self, state: SystemState) -> dict[str, float]:
        solar_array_area = self._required_solar_array_area_m2(state)
        stationkeeping_load = self._stationkeeping_load_w(state)
        solar_array_power = (
            self.config.solar_flux_w_per_m2
            * self.config.total_efficiency
            * solar_array_area
        )
        battery_power = max(0.0, stationkeeping_load - solar_array_power)
        burn_duration_h = self._burn_duration_h(state)
        battery_energy = battery_power * burn_duration_h
        battery_soc_after_burn = 1.0 - battery_energy / self.config.battery_capacity_wh
        cadence_h = self.config.correction_cadence_h
        recharge_power = max(0.0, solar_array_power - self.config.stationkeeping_base_load_w)
        recharge_energy = recharge_power * max(0.0, cadence_h - burn_duration_h)
        return {
            "stationkeeping_load_w": stationkeeping_load,
            "solar_array_power_during_burn_w": solar_array_power,
            "battery_power_during_burn_w": battery_power,
            "battery_energy_during_burn_wh": battery_energy,
            "battery_soc_after_burn": battery_soc_after_burn,
            "battery_recharge_margin_wh": recharge_energy - battery_energy,
            "area_lower_bound_energy_m2": self._energy_limited_area_m2(state),
            "area_lower_bound_power_m2": self._power_limited_area_m2(state),
            "area_lower_bound_recharge_m2": self._recharge_limited_area_m2(state),
        }

    def evaluate(self, state: SystemState) -> dict[str, float]:
        solar_array_area = self._required_solar_array_area_m2(state)
        stationkeeping_load = self._stationkeeping_load_w(state)
        return {
            self.solar_array_area_variable: solar_array_area,
            self.power_dissipated_variable: stationkeeping_load,
            self.power_mass_variable: (
                self.config.eps_fixed_mass_kg
                + self.config.battery_mass_kg
                + self.config.solar_array_areal_mass_density_kg_per_m2 * solar_array_area
            ),
            self.power_volume_variable: (
                self.config.eps_fixed_volume_u
                + self.config.battery_volume_u
                + self.config.solar_array_packed_volume_per_m2_u * solar_array_area
            ),
        }


def build_stationkeeping_power_module(source: PowerConfig | Path) -> StationkeepingPowerModule:
    return StationkeepingPowerModule.from_config_source(source)


@dataclass(frozen=True)
class HotCaseThermalModule:
    """Thermal module for the first hot-case-only implementation."""

    config: ThermalConfig
    name: str = "thermal"
    power_dissipated_variable: str = "power_dissipated_w"
    solar_array_area_variable: str = "solar_array_area_m2"
    temperature_requirement_variable: str = "temperature_requirement_k"
    effective_reflectivity_variable: str = "effective_reflectivity"
    thermal_mass_variable: str = "thermal_mass_kg"
    thermal_volume_variable: str = "thermal_volume_u"

    @classmethod
    def from_config_source(cls, source: ThermalConfig | Path) -> HotCaseThermalModule:
        return cls(config=load_thermal_config(source))

    @property
    def required_inputs(self) -> tuple[str, ...]:
        return (self.power_dissipated_variable, self.solar_array_area_variable)

    @property
    def provided_outputs(self) -> tuple[str, ...]:
        return (
            self.effective_reflectivity_variable,
            self.thermal_mass_variable,
            self.thermal_volume_variable,
        )

    def _temperature_requirement_k(self, state: SystemState) -> float:
        return float(state.values.get(self.temperature_requirement_variable, self.config.temperature_requirement_k))

    def _solar_array_absorbed_heat_w(self, state: SystemState) -> float:
        solar_array_area = state.get(self.solar_array_area_variable)
        net_solar_array_heat_fraction = (
            self.config.alpha_sa_front * self.config.phi_sa_front
            + self.config.alpha_sa_back * self.config.phi_sa_back
            - self.config.solar_array_conversion_efficiency
        )
        return self.config.solar_flux_w_per_m2 * solar_array_area * net_solar_array_heat_fraction

    def _weighted_reflectivity(self, state: SystemState) -> float:
        solar_array_area = state.get(self.solar_array_area_variable)
        total_exposed_area = 2.0 * solar_array_area + self.config.fixed_body_exposed_area_m2
        if total_exposed_area <= 0.0:
            raise ValueError(
                "Thermal weighted reflectivity requires positive total exposed area; "
                f"got {total_exposed_area}."
            )

        weighted_reflectivity = (
            (self.config.rho_sa_front + self.config.rho_sa_back) * solar_array_area
            + self.config.fixed_body_reflectivity_area_m2
        ) / total_exposed_area

        if not 0.0 <= weighted_reflectivity <= 1.0:
            raise ValueError(
                "Thermal weighted reflectivity must remain within [0, 1]; "
                f"got {weighted_reflectivity}."
            )
        return weighted_reflectivity

    def diagnostics(self, state: SystemState) -> dict[str, float]:
        temperature_requirement = self._temperature_requirement_k(state)
        denominator = (
            self.config.emissivity_osr
            * _STEFAN_BOLTZMANN_W_PER_M2K4
            * temperature_requirement**4
            - self.config.absorptivity_osr * self.config.solar_flux_w_per_m2
        )
        if denominator <= 0.0:
            raise ValueError(
                "Thermal radiator denominator must remain positive; "
                f"got {denominator}."
            )
        solar_array_absorbed_heat = self._solar_array_absorbed_heat_w(state)
        total_thermal_load = state.get(self.power_dissipated_variable) + solar_array_absorbed_heat
        radiator_area = total_thermal_load / denominator
        weighted_reflectivity = self._weighted_reflectivity(state)
        return {
            "radiator_area_m2": radiator_area,
            "radiator_area_with_margin_m2": (
                (1.0 + self.config.radiator_area_margin_fraction) * radiator_area
            ),
            "hot_case_temperature_limit_k": temperature_requirement,
            "solar_array_absorbed_heat_w": solar_array_absorbed_heat,
            "hot_case_total_thermal_load_w": total_thermal_load,
            "weighted_reflectivity": weighted_reflectivity,
            "effective_reflectivity": weighted_reflectivity,
            "cannonball_reflectivity_coefficient": 1.0 + weighted_reflectivity,
        }

    def evaluate(self, state: SystemState) -> dict[str, float]:
        diagnostics = self.diagnostics(state)
        return {
            self.effective_reflectivity_variable: diagnostics["effective_reflectivity"],
            self.thermal_mass_variable: self.config.mass_kg,
            self.thermal_volume_variable: self.config.volume_u,
        }


def build_hot_case_thermal_module(source: ThermalConfig | Path) -> HotCaseThermalModule:
    return HotCaseThermalModule.from_config_source(source)