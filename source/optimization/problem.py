"""Problem-level dataclasses that sit above the fixed-point analysis."""

from __future__ import annotations

from collections.abc import Callable, Sequence
from dataclasses import dataclass, field
from typing import Literal

from .analysis import FixedPointAnalysis, FixedPointResult
from .state import Number, SystemState

Metric = Callable[[SystemState], float]
ConstraintRelation = Literal["<=", ">=", "="]
ObjectiveSense = Literal["min", "max"]


@dataclass(frozen=True)
class DesignVariable:
    """One optimizer-controlled scalar variable with bounds."""

    name: str
    lower: float
    upper: float
    initial: float


@dataclass(frozen=True)
class Objective:
    """Scalar objective evaluated on the converged system state."""

    name: str
    evaluator: Metric
    sense: ObjectiveSense = "min"


@dataclass(frozen=True)
class Constraint:
    """Constraint evaluated on the converged system state."""

    name: str
    evaluator: Metric
    relation: ConstraintRelation
    target: float

    def residual(self, state: SystemState) -> float:
        value = float(self.evaluator(state))
        if self.relation == "<=":
            return value - self.target
        if self.relation == ">=":
            return self.target - value
        return value - self.target


@dataclass(frozen=True)
class ProblemEvaluation:
    """Full evaluation record for one design vector."""

    analysis_result: FixedPointResult
    objectives: dict[str, float]
    constraint_residuals: dict[str, float]


@dataclass(frozen=True)
class OptimizationProblem:
    """Bundle of analysis, design variables, objectives, and constraints."""

    analysis: FixedPointAnalysis
    design_variables: tuple[DesignVariable, ...]
    objectives: tuple[Objective, ...]
    constraints: tuple[Constraint, ...] = ()
    fixed_inputs: dict[str, float] = field(default_factory=dict)

    def initial_vector(self) -> list[float]:
        return [variable.initial for variable in self.design_variables]

    def bounds(self) -> list[tuple[float, float]]:
        return [(variable.lower, variable.upper) for variable in self.design_variables]

    def evaluate(self, vector: Sequence[Number]) -> ProblemEvaluation:
        if len(vector) != len(self.design_variables):
            raise ValueError(
                f"Expected {len(self.design_variables)} design variables, got {len(vector)}."
            )

        inputs = dict(self.fixed_inputs)
        for variable, value in zip(self.design_variables, vector, strict=True):
            inputs[variable.name] = float(value)

        analysis_result = self.analysis.run(inputs)
        state = analysis_result.state
        objectives = {
            objective.name: float(objective.evaluator(state))
            for objective in self.objectives
        }
        constraint_residuals = {
            constraint.name: float(constraint.residual(state))
            for constraint in self.constraints
        }
        return ProblemEvaluation(
            analysis_result=analysis_result,
            objectives=objectives,
            constraint_residuals=constraint_residuals,
        )