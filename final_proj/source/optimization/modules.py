"""Subsystem module interfaces for the preliminary MDO scaffold."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol

from .equations import Equation
from .state import SystemState


class DisciplineModule(Protocol):
    """Protocol shared by all subsystem models."""

    name: str
    required_inputs: tuple[str, ...]
    provided_outputs: tuple[str, ...]

    def evaluate(self, state: SystemState) -> dict[str, float]:
        """Return the module outputs for the current state."""


@dataclass(frozen=True)
class EquationModule:
    """Ordered set of explicit equations evaluated within one discipline."""

    name: str
    equations: tuple[Equation, ...]
    description: str = ""

    @property
    def required_inputs(self) -> tuple[str, ...]:
        required: list[str] = []
        produced: set[str] = set()
        for equation in self.equations:
            for variable in equation.inputs:
                if variable not in produced and variable not in required:
                    required.append(variable)
            produced.add(equation.output)
        return tuple(required)

    @property
    def provided_outputs(self) -> tuple[str, ...]:
        return tuple(equation.output for equation in self.equations)

    def evaluate(self, state: SystemState) -> dict[str, float]:
        local_state = state
        updates: dict[str, float] = {}
        for equation in self.equations:
            value = equation.evaluate(local_state)
            updates[equation.output] = value
            local_state = local_state.updated({equation.output: value})
        return updates


@dataclass(frozen=True)
class PlaceholderModule:
    """Module shell used until a teammate delivers explicit equations."""

    name: str
    required_inputs: tuple[str, ...]
    provided_outputs: tuple[str, ...]
    note: str = ""

    def evaluate(self, state: SystemState) -> dict[str, float]:
        state.require(self.required_inputs)
        missing = [name for name in self.provided_outputs if not state.has(name)]
        if missing:
            raise KeyError(
                f"Placeholder module '{self.name}' has no equations for {missing}. "
                "Seed those outputs in the startup state or replace the module with an EquationModule."
            )
        return state.subset(self.provided_outputs)