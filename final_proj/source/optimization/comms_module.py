"""Config-driven fixed communications module for the Sol-Sentinel optimizer."""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

from .state import SystemState


def _require_non_negative(value: float, name: str) -> float:
    if value < 0.0:
        raise ValueError(f"{name} must be non-negative; got {value}.")
    return value


@dataclass(frozen=True)
class CommsConfig:
    """Fixed communications properties used by the preliminary optimizer."""

    tx_power_w: float = 0.0
    mass_kg: float = 0.0
    volume_u: float = 0.0

    def __post_init__(self) -> None:
        _require_non_negative(self.tx_power_w, "tx_power_w")
        _require_non_negative(self.mass_kg, "mass_kg")
        _require_non_negative(self.volume_u, "volume_u")

    @classmethod
    def from_mapping(cls, payload: dict) -> CommsConfig:
        return cls(
            tx_power_w=float(payload.get("tx_power_w", 0.0)),
            mass_kg=float(payload.get("mass_kg", 0.0)),
            volume_u=float(payload.get("volume_u", 0.0)),
        )

    @classmethod
    def from_json(cls, path: Path) -> CommsConfig:
        payload = json.loads(Path(path).read_text())
        return cls.from_mapping(payload.get("comms", {}))


def load_comms_config(source: CommsConfig | Path) -> CommsConfig:
    if isinstance(source, CommsConfig):
        return source
    return CommsConfig.from_json(Path(source))


@dataclass(frozen=True)
class FixedCommsModule:
    """Communications module with fixed outputs loaded from configuration."""

    config: CommsConfig
    name: str = "comms"
    range_variable: str = "range_to_l4_m"
    data_rate_variable: str = "data_rate_bps"
    tx_power_variable: str = "tx_power_w"
    comms_mass_variable: str = "comms_mass_kg"
    comms_volume_variable: str = "comms_volume_u"

    @classmethod
    def from_config_source(cls, source: CommsConfig | Path) -> FixedCommsModule:
        return cls(config=load_comms_config(source))

    @property
    def required_inputs(self) -> tuple[str, ...]:
        return (self.range_variable, self.data_rate_variable)

    @property
    def provided_outputs(self) -> tuple[str, ...]:
        return (
            self.tx_power_variable,
            self.comms_mass_variable,
            self.comms_volume_variable,
        )

    def evaluate(self, state: SystemState) -> dict[str, float]:
        state.require(self.required_inputs)
        return {
            self.tx_power_variable: self.config.tx_power_w,
            self.comms_mass_variable: self.config.mass_kg,
            self.comms_volume_variable: self.config.volume_u,
        }


def build_fixed_comms_module(source: CommsConfig | Path) -> FixedCommsModule:
    return FixedCommsModule.from_config_source(source)