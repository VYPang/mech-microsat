"""Transform inertial trajectory to Sun-centred co-rotating frame.

The rotating frame is defined so that Earth sits (approximately) on
the +x axis at all times:
    x̂ = r̂_Earth     (Sun → Earth direction)
    ẑ = ecliptic normal  [0, 0, 1]
    ŷ = ẑ × x̂        (completes right-hand triad)
"""

from __future__ import annotations

import numpy as np
import polars as pl

from .initial_conditions import get_earth_states


def to_rotating_frame(
    df: pl.DataFrame,
    epoch_et: float,
    earth_spice_stride: int = 10,
) -> pl.DataFrame:
    """Convert an inertial trajectory DataFrame to the rotating frame.

    :param df: DataFrame with columns t_s, x, y, z  (metres, ECLIPJ2000).
    :param epoch_et: SPICE ET of the simulation start epoch.
    :param earth_spice_stride: Query Earth SPICE every N-th point and interpolate.
    :return: New DataFrame with added columns x_rot, y_rot, z_rot,
             x_earth_rot, y_earth_rot, z_earth_rot  (all in metres).
    """
    times_s = df["t_s"].to_numpy()
    sat_pos = np.column_stack([df["x"].to_numpy(), df["y"].to_numpy(), df["z"].to_numpy()])

    # Earth positions at every recorded timestep (interpolated for speed)
    earth_pos = get_earth_states(epoch_et, times_s, stride=earth_spice_stride)

    sat_rot, earth_rot = _rotate_to_synodic(sat_pos, earth_pos)

    return df.with_columns(
        pl.Series("x_rot", sat_rot[:, 0]),
        pl.Series("y_rot", sat_rot[:, 1]),
        pl.Series("z_rot", sat_rot[:, 2]),
        pl.Series("x_earth_rot", earth_rot[:, 0]),
        pl.Series("y_earth_rot", earth_rot[:, 1]),
        pl.Series("z_earth_rot", earth_rot[:, 2]),
        pl.Series("x_earth", earth_pos[:, 0]),
        pl.Series("y_earth", earth_pos[:, 1]),
        pl.Series("z_earth", earth_pos[:, 2]),
    )


def _rotate_to_synodic(
    sat_pos: np.ndarray,
    earth_pos: np.ndarray,
) -> tuple[np.ndarray, np.ndarray]:
    """Vectorised rotation of positions into the synodic frame.

    :param sat_pos: (N, 3) satellite positions in ECLIPJ2000.
    :param earth_pos: (N, 3) Earth positions in ECLIPJ2000.
    :return: Tuple of (sat_rotated, earth_rotated), each (N, 3).
    """
    n = sat_pos.shape[0]

    # Unit vector Sun → Earth (x-axis of rotating frame)
    r_earth_mag = np.linalg.norm(earth_pos, axis=1, keepdims=True)
    x_hat = earth_pos / r_earth_mag  # (N, 3)

    # Ecliptic normal (z-axis)
    z_hat = np.zeros_like(x_hat)
    z_hat[:, 2] = 1.0

    # y = z × x  (right-hand rule)
    y_hat = np.cross(z_hat, x_hat)
    y_hat /= np.linalg.norm(y_hat, axis=1, keepdims=True)

    # Recompute z to ensure exact orthogonality
    z_hat = np.cross(x_hat, y_hat)

    # Build rotation matrices (N, 3, 3) — rows are basis vectors
    R = np.empty((n, 3, 3))
    R[:, 0, :] = x_hat
    R[:, 1, :] = y_hat
    R[:, 2, :] = z_hat

    # r_rot[i] = R[i] @ r_inertial[i]
    sat_rot = np.einsum("nij,nj->ni", R, sat_pos)
    earth_rot = np.einsum("nij,nj->ni", R, earth_pos)

    return sat_rot, earth_rot
