"""Compute initial state vector for a satellite at Sun-Earth L4.

L4 leads Earth by 60° in the prograde direction. The satellite is placed
at the ecliptic-plane crossing with an out-of-plane velocity component
that produces the desired inclination relative to the ecliptic.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import numpy as np
import spiceypy as spice


@dataclass(frozen=True)
class L4State:
    """Initial state at L4 in Sun-centred ECLIPJ2000."""

    position_m: np.ndarray  # (3,)
    velocity_ms: np.ndarray  # (3,)
    earth_position_m: np.ndarray  # (3,) for reference
    earth_velocity_ms: np.ndarray  # (3,)
    epoch_et: float  # SPICE ephemeris time


# ---------------------------------------------------------------------------
# SPICE kernel management
# ---------------------------------------------------------------------------

_KERNEL_DIR = Path.home() / ".cache" / "bsk_support_data" / "supportData" / "EphemerisData"

_KERNELS_LOADED = False


def _ensure_spice_kernels() -> None:
    """Load SPICE kernels (idempotent)."""
    global _KERNELS_LOADED  # noqa: PLW0603
    if _KERNELS_LOADED:
        return
    for name in ("naif0012.tls", "de430.bsp", "de-403-masses.tpc", "pck00010.tpc"):
        spice.furnsh(str(_KERNEL_DIR / name))
    _KERNELS_LOADED = True


# ---------------------------------------------------------------------------
# Core computation
# ---------------------------------------------------------------------------

_MU_SUN = 1.327_124_400_18e20  # m^3 s^-2  (IAU 2015)


def _rotation_z(angle_rad: float) -> np.ndarray:
    """3×3 rotation matrix about the z-axis."""
    c, s = np.cos(angle_rad), np.sin(angle_rad)
    return np.array([[c, -s, 0.0], [s, c, 0.0], [0.0, 0.0, 1.0]])


def compute_l4_state(
    epoch_utc: str = "2025 JAN 01 00:00:00.0 (UTC)",
    inclination_deg: float = 14.5,
) -> L4State:
    """Return the inertial state of a satellite at Sun-Earth L4.

    Strategy
    --------
    1. Query Earth's state from SPICE and rotate both r and v by +60°
       about the ecliptic normal.  This places the satellite on *Earth's
       exact orbit* (same a, same e) but 60° ahead — matching Earth's
       orbital period so the satellite stays near L4.
    2. To add out-of-plane inclination we decompose the speed at L4 into
       ``v_inplane = |v| cos(i)`` and ``v_z = |v| sin(i)``.  Because
       ``|v|`` is preserved the vis-viva energy (and thus a) is unchanged,
       keeping the orbital period identical to Earth's.

    :param epoch_utc: SPICE-compatible UTC epoch string.
    :param inclination_deg: Out-of-plane inclination in degrees.
    :return: L4State with positions (m) and velocities (m/s).
    """
    _ensure_spice_kernels()

    et = spice.str2et(epoch_utc)

    # Earth state relative to Sun in ECLIPJ2000 (km, km/s) → (m, m/s)
    state_km, _ = spice.spkezr("EARTH", et, "ECLIPJ2000", "NONE", "SUN")
    r_earth = np.asarray(state_km[:3]) * 1e3
    v_earth = np.asarray(state_km[3:]) * 1e3

    # L4 position: rotate Earth's position +60° about the ecliptic normal
    rz60 = _rotation_z(np.radians(60.0))
    r_l4 = rz60 @ r_earth

    # In-plane velocity: Earth's velocity rotated by +60°.
    # This preserves Earth's orbital energy → same semi-major axis → same period.
    v_l4_base = rz60 @ v_earth
    v_speed = np.linalg.norm(v_l4_base)

    # Decompose into ecliptic in-plane direction and out-of-plane.
    # Project to ecliptic to get the pure in-plane direction.
    v_inplane_dir = v_l4_base.copy()
    v_inplane_dir[2] = 0.0
    v_inplane_dir /= np.linalg.norm(v_inplane_dir)

    inc = np.radians(inclination_deg)
    velocity = (
        v_speed * np.cos(inc) * v_inplane_dir
        + v_speed * np.sin(inc) * np.array([0.0, 0.0, 1.0])
    )

    return L4State(
        position_m=r_l4,
        velocity_ms=velocity,
        earth_position_m=r_earth,
        earth_velocity_ms=v_earth,
        epoch_et=et,
    )


def get_earth_states(
    epoch_et: float,
    times_s: np.ndarray,
    stride: int = 1,
) -> np.ndarray:
    """Return Earth positions (m) in Sun-centred ECLIPJ2000 at each time.

    For large arrays the SPICE loop can be slow.  Use *stride* > 1 to
    query every Nth point and linearly interpolate in between.

    :param epoch_et: SPICE ET of simulation start.
    :param times_s: 1-D array of elapsed seconds since epoch.
    :param stride: Query SPICE every *stride*-th point, interpolate the rest.
    :return: (N, 3) array of Earth positions in metres.
    """
    _ensure_spice_kernels()

    n = len(times_s)
    idx = np.arange(0, n, stride)
    # Always include the last point
    if idx[-1] != n - 1:
        idx = np.append(idx, n - 1)

    sampled = np.empty((len(idx), 3))
    for j, i in enumerate(idx):
        state_km, _ = spice.spkezr(
            "EARTH", epoch_et + float(times_s[i]), "ECLIPJ2000", "NONE", "SUN"
        )
        sampled[j] = np.asarray(state_km[:3]) * 1e3

    if stride == 1:
        return sampled

    # Linearly interpolate for intermediate points
    t_sampled = times_s[idx]
    positions = np.empty((n, 3))
    for axis in range(3):
        positions[:, axis] = np.interp(times_s, t_sampled, sampled[:, axis])
    return positions
