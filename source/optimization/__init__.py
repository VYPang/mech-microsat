"""Optimization scaffolding for the Sol-Sentinel preliminary design loop."""

from .analysis import FixedPointAnalysis, FixedPointResult
from .comms_module import CommsConfig, FixedCommsModule, build_fixed_comms_module, load_comms_config
from .equations import Equation
from .modules import DisciplineModule, EquationModule, PlaceholderModule
from .orbit_module import OrbitSurrogateModule
from .power_thermal_module import (
    HotCaseThermalModule,
    PowerConfig,
    StationkeepingPowerModule,
    ThermalConfig,
    build_hot_case_thermal_module,
    build_stationkeeping_power_module,
    load_power_config,
    load_thermal_config,
)
from .propulsion_module import (
    FixedThrusterPropulsionModule,
    FixedThrusterSpec,
    MissionConfig,
    PropulsionConfig,
    build_fixed_thruster_propulsion_module,
    load_propulsion_config,
)
from .problem import Constraint, DesignVariable, Objective, OptimizationProblem, ProblemEvaluation
from .sol_sentinel import (
    COUPLED_VARIABLES,
    OPTIMIZER_INPUTS,
    build_configured_objectives,
    build_budget_module,
    build_sol_sentinel_analysis,
    load_optimizer_fixed_inputs,
    load_optimizer_initial_state,
    load_orbit_surrogate_path,
    load_optimizer_startup_seeds,
)
from .state import SystemState
from .variables import SOL_SENTINEL_VARIABLES, VARIABLE_REGISTRY, VariableDefinition

__all__ = [
    "COUPLED_VARIABLES",
    "CommsConfig",
    "Constraint",
    "DesignVariable",
    "DisciplineModule",
    "Equation",
    "EquationModule",
    "FixedCommsModule",
    "FixedThrusterPropulsionModule",
    "FixedThrusterSpec",
    "FixedPointAnalysis",
    "FixedPointResult",
    "HotCaseThermalModule",
    "MissionConfig",
    "OPTIMIZER_INPUTS",
    "PowerConfig",
    "Objective",
    "OptimizationProblem",
    "OrbitSurrogateModule",
    "PlaceholderModule",
    "PropulsionConfig",
    "ProblemEvaluation",
    "SOL_SENTINEL_VARIABLES",
    "StationkeepingPowerModule",
    "SystemState",
    "ThermalConfig",
    "VARIABLE_REGISTRY",
    "VariableDefinition",
    "build_budget_module",
    "build_configured_objectives",
    "build_fixed_comms_module",
    "build_fixed_thruster_propulsion_module",
    "build_hot_case_thermal_module",
    "build_sol_sentinel_analysis",
    "build_stationkeeping_power_module",
    "load_comms_config",
    "load_optimizer_fixed_inputs",
    "load_optimizer_initial_state",
    "load_optimizer_startup_seeds",
    "load_orbit_surrogate_path",
    "load_power_config",
    "load_propulsion_config",
    "load_thermal_config",
]