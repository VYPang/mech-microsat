"""Fixed-thruster propulsion model for the Sol-Sentinel optimization loop."""

from __future__ import annotations

import json
import math
from dataclasses import dataclass
from pathlib import Path

from .state import SystemState

_G0_MPS2 = 9.80665
_SECONDS_PER_DAY = 86400.0
_SECONDS_PER_YEAR = 365.25 * _SECONDS_PER_DAY


def _require_positive(value: float, name: str) -> float:
    if value <= 0.0:
        raise ValueError(f"{name} must be positive; got {value}.")
    return value


@dataclass(frozen=True)
class MissionConfig:
    """Mission-level propulsion assumptions."""

    lifetime_years: float
    delta_v_margin_fraction: float
    correction_cadence_days: float

    def __post_init__(self) -> None:
        _require_positive(self.lifetime_years, "lifetime_years")
        if self.delta_v_margin_fraction < 0.0:
            raise ValueError(
                "delta_v_margin_fraction must be non-negative; "
                f"got {self.delta_v_margin_fraction}."
            )
        _require_positive(self.correction_cadence_days, "correction_cadence_days")

    @property
    def margin_scale(self) -> float:
        return 1.0 + self.delta_v_margin_fraction

    @property
    def correction_cadence_s(self) -> float:
        return self.correction_cadence_days * _SECONDS_PER_DAY

    @classmethod
    def from_mapping(cls, payload: dict) -> MissionConfig:
        return cls(
            lifetime_years=float(payload["lifetime_years"]),
            delta_v_margin_fraction=float(payload["delta_v_margin_fraction"]),
            correction_cadence_days=float(payload["correction_cadence_days"]),
        )


@dataclass(frozen=True)
class FixedThrusterSpec:
    """Published operating point and package data for one propulsion system."""

    name: str
    thrust_mn: float
    power_w: float
    specific_impulse_s: float
    wet_mass_kg: float
    volume_u: float
    total_impulse_ns: float
    hardware_mass_kg: float | None = None

    def __post_init__(self) -> None:
        _require_positive(self.thrust_mn, "thrust_mn")
        _require_positive(self.power_w, "power_w")
        _require_positive(self.specific_impulse_s, "specific_impulse_s")
        _require_positive(self.wet_mass_kg, "wet_mass_kg")
        _require_positive(self.volume_u, "volume_u")
        _require_positive(self.total_impulse_ns, "total_impulse_ns")
        if self.hardware_mass_kg is not None:
            _require_positive(self.hardware_mass_kg, "hardware_mass_kg")
        if self.resolved_hardware_mass_kg <= 0.0:
            raise ValueError(
                "Resolved hardware mass must be positive after subtracting inferred "
                f"propellant capacity; got {self.resolved_hardware_mass_kg}."
            )

    @property
    def thrust_n(self) -> float:
        return 1.0e-3 * self.thrust_mn

    @property
    def inferred_propellant_capacity_kg(self) -> float:
        return self.total_impulse_ns / (_G0_MPS2 * self.specific_impulse_s)

    @property
    def resolved_hardware_mass_kg(self) -> float:
        if self.hardware_mass_kg is not None:
            return self.hardware_mass_kg
        return self.wet_mass_kg - self.inferred_propellant_capacity_kg

    @classmethod
    def from_mapping(cls, payload: dict) -> FixedThrusterSpec:
        hardware_mass = payload.get("hardware_mass_kg")
        return cls(
            name=str(payload["selected_engine"]),
            thrust_mn=float(payload["thrust_mn"]),
            power_w=float(payload["power_w"]),
            specific_impulse_s=float(payload["specific_impulse_s"]),
            wet_mass_kg=float(payload["wet_mass_kg"]),
            volume_u=float(payload["volume_u"]),
            total_impulse_ns=float(payload["total_impulse_ns"]),
            hardware_mass_kg=None if hardware_mass is None else float(hardware_mass),
        )


@dataclass(frozen=True)
class PropulsionConfig:
    """Loaded propulsion assumptions for the fixed-thruster model."""

    mission: MissionConfig
    thruster: FixedThrusterSpec

    @classmethod
    def from_mapping(cls, payload: dict) -> PropulsionConfig:
        return cls(
            mission=MissionConfig.from_mapping(payload["mission"]),
            thruster=FixedThrusterSpec.from_mapping(payload["propulsion"]),
        )

    @classmethod
    def from_json(cls, path: Path) -> PropulsionConfig:
        payload = json.loads(Path(path).read_text())
        return cls.from_mapping(payload)


def load_propulsion_config(source: PropulsionConfig | Path) -> PropulsionConfig:
    if isinstance(source, PropulsionConfig):
        return source
    return PropulsionConfig.from_json(Path(source))


@dataclass(frozen=True)
class FixedThrusterPropulsionModule:
    """Propulsion discipline for a preselected electric propulsion unit."""

    config: PropulsionConfig
    name: str = "propulsion"
    delta_v_variable: str = "delta_v_mps_per_year"
    total_mass_variable: str = "total_wet_mass_kg"
    propulsion_power_variable: str = "propulsion_power_w"
    burn_duration_variable: str = "burn_duration_s"
    propellant_mass_variable: str = "propellant_mass_kg"
    propulsion_mass_variable: str = "propulsion_mass_kg"
    propulsion_volume_variable: str = "propulsion_volume_u"

    @classmethod
    def from_config_source(
        cls,
        source: PropulsionConfig | Path,
    ) -> FixedThrusterPropulsionModule:
        return cls(config=load_propulsion_config(source))

    @property
    def required_inputs(self) -> tuple[str, ...]:
        return (self.delta_v_variable, self.total_mass_variable)

    @property
    def provided_outputs(self) -> tuple[str, ...]:
        return (
            self.propulsion_power_variable,
            self.burn_duration_variable,
            self.propellant_mass_variable,
            self.propulsion_mass_variable,
            self.propulsion_volume_variable,
        )

    def _effective_delta_v_per_year(self, state: SystemState) -> float:
        delta_v_per_year = state.get(self.delta_v_variable)
        return self.config.mission.margin_scale * delta_v_per_year

    def _mission_delta_v(self, state: SystemState) -> float:
        return self._effective_delta_v_per_year(state) * self.config.mission.lifetime_years

    def _propellant_mass_required(self, state: SystemState) -> float:
        total_mass = state.get(self.total_mass_variable)
        delta_v_life = self._mission_delta_v(state)
        exponent = -delta_v_life / (_G0_MPS2 * self.config.thruster.specific_impulse_s)
        return total_mass * (1.0 - math.exp(exponent))

    def _burn_duration_s(self, state: SystemState) -> float:
        total_mass = state.get(self.total_mass_variable)
        delta_v_effective = self._effective_delta_v_per_year(state)
        delta_v_cycle = delta_v_effective * self.config.mission.correction_cadence_s / _SECONDS_PER_YEAR
        cycle_impulse_required = total_mass * delta_v_cycle
        return cycle_impulse_required / self.config.thruster.thrust_n

    def diagnostics(self, state: SystemState) -> dict[str, float]:
        total_mass = state.get(self.total_mass_variable)
        delta_v_effective = self._effective_delta_v_per_year(state)
        delta_v_cycle = delta_v_effective * self.config.mission.correction_cadence_s / _SECONDS_PER_YEAR
        cycle_impulse_required = total_mass * delta_v_cycle
        burn_duration_s = self._burn_duration_s(state)
        duty_cycle = burn_duration_s / self.config.mission.correction_cadence_s
        mission_delta_v = self._mission_delta_v(state)
        mission_total_impulse = total_mass * mission_delta_v
        burn_energy_wh = self.config.thruster.power_w * burn_duration_s / 3600.0
        return {
            "delta_v_effective_mps_per_year": delta_v_effective,
            "delta_v_cycle_mps": delta_v_cycle,
            "burn_duration_s": burn_duration_s,
            "duty_cycle": duty_cycle,
            "required_total_impulse_ns": mission_total_impulse,
            "burn_energy_wh": burn_energy_wh,
        }

    def evaluate(self, state: SystemState) -> dict[str, float]:
        return {
            self.propulsion_power_variable: self.config.thruster.power_w,
            self.burn_duration_variable: self._burn_duration_s(state),
            self.propellant_mass_variable: self._propellant_mass_required(state),
            self.propulsion_mass_variable: self.config.thruster.resolved_hardware_mass_kg,
            self.propulsion_volume_variable: self.config.thruster.volume_u,
        }


def build_fixed_thruster_propulsion_module(
    source: PropulsionConfig | Path,
) -> FixedThrusterPropulsionModule:
    return FixedThrusterPropulsionModule.from_config_source(source)