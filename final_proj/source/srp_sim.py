"""Single Basilisk run with cannonball SRP for one (area, c_R, mass) point.

Returns the inertial accumulated non-gravitational ΔV at the end of the
run.  Used by the response-surface sweep driver.
"""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np

from Basilisk.simulation import radiationPressure, spacecraft
from Basilisk.utilities import SimulationBaseClass, macros
from Basilisk.utilities.simIncludeGravBody import gravBodyFactory

from .initial_conditions import compute_l4_state


@dataclass(frozen=True)
class SrpRunResult:
    """Outcome of a single SRP-perturbed propagation."""

    area_m2: float
    cr: float
    mass_kg: float
    duration_s: float
    dv_total_mps: float       # ||Δv_accum_CN_N|| at final time
    dv_per_year_mps: float    # dv_total_mps / (duration / 1 year)


def run_srp_drift(
    *,
    epoch_utc: str,
    duration_years: float,
    timestep_s: float,
    inclination_deg: float,
    mass_kg: float,
    area_m2: float,
    cr: float,
) -> SrpRunResult:
    """Propagate one CR3BP run with cannonball SRP and report final ΔV.

    :param mass_kg: Spacecraft hub mass; SRP acceleration scales as 1/m.
    :param area_m2: Effective sun-facing cross-section.
    :param cr: Reflectivity coefficient (1.0 = pure absorber, 2.0 = perfect mirror).
    :return: Final inertial accumulated non-gravitational ΔV magnitude and per-year rate.
    """
    ic = compute_l4_state(epoch_utc, inclination_deg)

    sim = SimulationBaseClass.SimBaseClass()
    proc = sim.CreateNewProcess("dynProcess")
    dt_nano = macros.sec2nano(timestep_s)
    proc.addTask(sim.CreateNewTask("dynTask", dt_nano))

    # Sun (central) + Earth (perturber) via SPICE.
    grav_factory = gravBodyFactory()
    sun = grav_factory.createSun()
    sun.isCentralBody = True
    grav_factory.createEarth()
    spice_obj = grav_factory.createSpiceInterface(time=epoch_utc)
    sim.AddModelToTask("dynTask", spice_obj)

    # Spacecraft hub.
    sc = sc_obj = spacecraft.Spacecraft()
    sc.ModelTag = "solSentinelSRP"
    sc.hub.r_CN_NInit = ic.position_m.tolist()
    sc.hub.v_CN_NInit = ic.velocity_ms.tolist()
    sc.hub.mHub = float(mass_kg)
    grav_factory.addBodiesTo(sc)
    sim.AddModelToTask("dynTask", sc)

    # Cannonball SRP effector.  Sun is index 0 in planetStateOutMsgs (createSun first).
    srp = radiationPressure.RadiationPressure()
    srp.ModelTag = "srpCannonball"
    srp.setUseCannonballModel()
    srp.area = float(area_m2)
    srp.coefficientReflection = float(cr)
    srp.sunEphmInMsg.subscribeTo(spice_obj.planetStateOutMsgs[0])
    sc_obj.addDynamicEffector(srp)
    sim.AddModelToTask("dynTask", srp)

    # Recorder — only need the accumulated DV at the end, so coarse logging is fine.
    rec = sc.scStateOutMsg.recorder(macros.sec2nano(timestep_s * 100.0))
    sim.AddModelToTask("dynTask", rec)

    duration_s = duration_years * 365.25 * 86400.0
    sim.InitializeSimulation()
    sim.ConfigureStopTime(macros.sec2nano(duration_s))
    sim.ExecuteSimulation()

    # TotalAccumDV_CN_N is the running inertial ΔV from non-gravitational forces.
    dv_history = np.asarray(rec.TotalAccumDV_CN_N)
    dv_final = float(np.linalg.norm(dv_history[-1]))

    seconds_per_year = 365.25 * 86400.0
    dv_per_year = dv_final / (duration_s / seconds_per_year)

    return SrpRunResult(
        area_m2=float(area_m2),
        cr=float(cr),
        mass_kg=float(mass_kg),
        duration_s=duration_s,
        dv_total_mps=dv_final,
        dv_per_year_mps=dv_per_year,
    )
