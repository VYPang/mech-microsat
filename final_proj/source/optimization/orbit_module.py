"""Optimization-layer wrapper around the fitted SRP orbit surrogate."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from final_proj.source.orbit.surrogate import ResponseSurface

from .state import SystemState


@dataclass(frozen=True)
class OrbitSurrogateModule:
    """Discipline adapter that exposes the current SRP surrogate to the optimizer.

    The XDSM keeps ``M_prop`` as an explicit feedback edge into Orbit.  The
    present surrogate was fit on total wet mass, so this scaffold validates the
    propellant input but still uses ``M_tot`` as the mass seen by the surrogate.
    The upstream thermal placeholder exposes an effective surface reflectivity
    in the normalized range ``rho_s in [0, 1]``; the Basilisk cannonball SRP
    model expects ``c_R in [1, 2]``, so Orbit applies ``c_R = 1 + rho_s`` at
    the interface.
    That hook is where a later faceted or time-varying orbit model can replace
    the current mass policy without changing the optimizer interface.
    """

    surrogate: ResponseSurface
    name: str = "orbit"
    area_variable: str = "solar_array_area_m2"
    reflectivity_variable: str = "effective_reflectivity"
    total_mass_variable: str = "total_wet_mass_kg"
    propellant_mass_variable: str | None = "propellant_mass_kg"
    delta_v_variable: str = "delta_v_mps_per_year"
    beta_variable: str = "ballistic_coefficient_m2_per_kg"
    effective_mass_variable: str = "orbit_mass_for_srp_kg"

    @classmethod
    def from_json(cls, path: Path) -> OrbitSurrogateModule:
        return cls(surrogate=ResponseSurface.from_json(path))

    @property
    def required_inputs(self) -> tuple[str, ...]:
        inputs = [self.area_variable, self.reflectivity_variable, self.total_mass_variable]
        if self.propellant_mass_variable is not None:
            inputs.append(self.propellant_mass_variable)
        return tuple(inputs)

    @property
    def provided_outputs(self) -> tuple[str, ...]:
        return (self.delta_v_variable, self.beta_variable, self.effective_mass_variable)

    def _effective_mass(self, state: SystemState) -> float:
        total_mass = state.get(self.total_mass_variable)
        if self.propellant_mass_variable is not None:
            state.get(self.propellant_mass_variable)
        return total_mass

    def _cannonball_reflectivity(self, state: SystemState) -> float:
        rho_s = state.get(self.reflectivity_variable)
        return 1.0 + rho_s

    def evaluate(self, state: SystemState) -> dict[str, float]:
        area = state.get(self.area_variable)
        reflectivity = self._cannonball_reflectivity(state)
        effective_mass = self._effective_mass(state)
        beta = reflectivity * area / effective_mass
        delta_v = self.surrogate.predict(
            area_m2=area,
            cr=reflectivity,
            mass_kg=effective_mass,
        )
        return {
            self.delta_v_variable: delta_v,
            self.beta_variable: beta,
            self.effective_mass_variable: effective_mass,
        }