"""Orbit-domain package for Sol-Sentinel trajectory and SRP models."""

from __future__ import annotations

from importlib import import_module

_EXPORTS = {
    "GridAxis": ".srp_sweep",
    "L4State": ".initial_conditions",
    "ResponseSurface": ".surrogate",
    "SrpRunResult": ".srp_sim",
    "SurrogateBounds": ".surrogate",
    "SweepSpec": ".srp_sweep",
    "ValidationSpec": ".srp_validation",
    "compute_l4_state": ".initial_conditions",
    "create_all_plots": ".visualize",
    "fit_response_surface": ".surrogate",
    "get_earth_states": ".initial_conditions",
    "plot_response_surface": ".surrogate_plot",
    "plot_response_surface_png": ".surrogate_plot",
    "plot_validation": ".srp_validation",
    "run_cr3bp_baseline": ".cr3bp_sim",
    "run_srp_drift": ".srp_sim",
    "run_sweep": ".srp_sweep",
    "run_validation": ".srp_validation",
    "to_rotating_frame": ".rotating_frame",
}


def __getattr__(name: str):
    if name not in _EXPORTS:
        raise AttributeError(f"module {__name__!r} has no attribute {name!r}")
    module = import_module(_EXPORTS[name], __name__)
    return getattr(module, name)

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