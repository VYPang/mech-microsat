"""Equation primitives used by subsystem modules."""

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass

from .state import SystemState

EquationEvaluator = Callable[[SystemState], float]


@dataclass(frozen=True)
class Equation:
    """One explicit input-output relation inside a subsystem module."""

    name: str
    output: str
    inputs: tuple[str, ...]
    evaluator: EquationEvaluator
    description: str = ""

    def evaluate(self, state: SystemState) -> float:
        state.require(self.inputs)
        return float(self.evaluator(state))