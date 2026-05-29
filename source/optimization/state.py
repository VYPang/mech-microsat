"""Immutable container for optimizer state variables."""

from __future__ import annotations

from collections.abc import Iterable, Mapping
from dataclasses import dataclass, field

Number = int | float


@dataclass(frozen=True)
class SystemState:
    """Current values carried through the fixed-point analysis."""

    values: dict[str, float] = field(default_factory=dict)

    @classmethod
    def from_mapping(cls, values: Mapping[str, Number]) -> SystemState:
        return cls({name: float(value) for name, value in values.items()})

    def has(self, name: str) -> bool:
        return name in self.values

    def get(self, name: str) -> float:
        if name not in self.values:
            raise KeyError(f"State is missing required variable '{name}'.")
        return self.values[name]

    def require(self, names: Iterable[str]) -> dict[str, float]:
        return {name: self.get(name) for name in names}

    def subset(self, names: Iterable[str]) -> dict[str, float]:
        return {name: self.get(name) for name in names}

    def updated(self, updates: Mapping[str, Number]) -> SystemState:
        merged = dict(self.values)
        merged.update({name: float(value) for name, value in updates.items()})
        return SystemState(merged)

    def as_dict(self) -> dict[str, float]:
        return dict(self.values)