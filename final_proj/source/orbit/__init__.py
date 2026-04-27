"""Orbit-domain package for Sol-Sentinel trajectory and SRP models."""

from .cr3bp_sim import run_cr3bp_baseline
from .initial_conditions import L4State, compute_l4_state, get_earth_states
from .rotating_frame import to_rotating_frame
from .srp_sim import SrpRunResult, run_srp_drift
from .srp_sweep import GridAxis, SweepSpec, run_sweep
from .srp_validation import ValidationSpec, plot_validation, run_validation
from .surrogate import ResponseSurface, SurrogateBounds, fit_response_surface
from .surrogate_plot import plot_response_surface, plot_response_surface_png
from .visualize import create_all_plots

__all__ = [
    "GridAxis",
    "L4State",
    "ResponseSurface",
    "SrpRunResult",
    "SurrogateBounds",
    "SweepSpec",
    "ValidationSpec",
    "compute_l4_state",
    "create_all_plots",
    "fit_response_surface",
    "get_earth_states",
    "plot_response_surface",
    "plot_response_surface_png",
    "plot_validation",
    "run_cr3bp_baseline",
    "run_srp_drift",
    "run_sweep",
    "run_validation",
    "to_rotating_frame",
]