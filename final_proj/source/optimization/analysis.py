"""Fixed-point multidisciplinary analysis loop for the preliminary optimizer."""

from __future__ import annotations

from collections.abc import Mapping, Sequence
from dataclasses import dataclass, field

from .modules import DisciplineModule
from .state import Number, SystemState


def _max_relative_residual(
    previous: Mapping[str, float | None],
    state: SystemState,
    variables: Sequence[str],
) -> float:
    residuals: list[float] = []
    for variable in variables:
        current = state.values.get(variable)
        old = previous.get(variable)
        if current is None or old is None:
            return float("inf")
        scale = max(1.0, abs(current))
        residuals.append(abs(current - old) / scale)
    return max(residuals, default=0.0)


@dataclass(frozen=True)
class FixedPointResult:
    """Outcome of one fixed-point multidisciplinary analysis."""

    state: SystemState
    iterations: int
    converged: bool
    residual_history: tuple[float, ...] = field(default_factory=tuple)


@dataclass(frozen=True)
class FixedPointAnalysis:
    """Gauss-Seidel style loop over the ordered subsystem chain."""

    modules: tuple[DisciplineModule, ...]
    coupled_variables: tuple[str, ...]
    tolerance: float = 1e-6
    max_iterations: int = 25

    @property
    def startup_inputs(self) -> tuple[str, ...]:
        required: list[str] = []
        produced: set[str] = set()
        for module in self.modules:
            for variable in module.required_inputs:
                if variable not in produced and variable not in required:
                    required.append(variable)
            produced.update(module.provided_outputs)
        return tuple(required)

    def run(self, initial_state: Mapping[str, Number]) -> FixedPointResult:
        state = SystemState.from_mapping(initial_state)
        previous = {name: state.values.get(name) for name in self.coupled_variables}
        residual_history: list[float] = []

        for iteration in range(1, self.max_iterations + 1):
            for module in self.modules:
                updates = module.evaluate(state)
                state = state.updated(updates)

            residual = _max_relative_residual(previous, state, self.coupled_variables)
            residual_history.append(residual)
            if residual <= self.tolerance:
                return FixedPointResult(
                    state=state,
                    iterations=iteration,
                    converged=True,
                    residual_history=tuple(residual_history),
                )

            previous = {name: state.values.get(name) for name in self.coupled_variables}

        return FixedPointResult(
            state=state,
            iterations=self.max_iterations,
            converged=False,
            residual_history=tuple(residual_history),
        )