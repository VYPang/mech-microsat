"""Optimization scaffolding for the Sol-Sentinel preliminary design loop."""

from .analysis import FixedPointAnalysis, FixedPointResult
from .equations import Equation
from .modules import DisciplineModule, EquationModule, PlaceholderModule
from .orbit_module import OrbitSurrogateModule
from .problem import Constraint, DesignVariable, Objective, OptimizationProblem, ProblemEvaluation
from .sol_sentinel import COUPLED_VARIABLES, OPTIMIZER_INPUTS, build_budget_module, build_sol_sentinel_analysis
from .state import SystemState
from .variables import SOL_SENTINEL_VARIABLES, VARIABLE_REGISTRY, VariableDefinition

__all__ = [
    "COUPLED_VARIABLES",
    "Constraint",
    "DesignVariable",
    "DisciplineModule",
    "Equation",
    "EquationModule",
    "FixedPointAnalysis",
    "FixedPointResult",
    "OPTIMIZER_INPUTS",
    "Objective",
    "OptimizationProblem",
    "OrbitSurrogateModule",
    "PlaceholderModule",
    "ProblemEvaluation",
    "SOL_SENTINEL_VARIABLES",
    "SystemState",
    "VARIABLE_REGISTRY",
    "VariableDefinition",
    "build_budget_module",
    "build_sol_sentinel_analysis",
]