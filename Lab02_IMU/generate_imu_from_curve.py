from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Annotated

import matplotlib.pyplot as plt
import numpy as np
import typer
from rich.console import Console
from scipy.interpolate import splev, splprep

console = Console()
app = typer.Typer(
    help="Generate tab-delimited IMU data from a saved B-spline curve.",
    invoke_without_command=True,
)
GRAVITY_NAV = np.array([0.0, 0.0, -9.81], dtype=float)
OUTPUT_DIR = Path("output")
DEFAULT_INPUT = OUTPUT_DIR / "control_points.npz"
DEFAULT_OUTPUT = OUTPUT_DIR / "IMU_from_curve.csv"


@dataclass
class LoadedCurve:
    control_points: np.ndarray
    initial_index: int
    end_index: int


@dataclass
class SplineCurve:
    tck: tuple[np.ndarray, list[np.ndarray], int]
    scale: float
    max_radius_before_scaling: float


@dataclass
class TrajectorySamples:
    timestamps_ms: np.ndarray
    time_s: np.ndarray
    position_nav: np.ndarray
    velocity_nav: np.ndarray
    acceleration_nav: np.ndarray
    specific_force_body: np.ndarray
    angular_rate_body: np.ndarray


def load_control_points(path: Path) -> LoadedCurve:
    """Load control points from .npz without modifying the file."""

    with np.load(path, allow_pickle=False) as data:
        control_points = np.asarray(data["control_points"], dtype=float)
        initial_index = int(data["initial_index"])
        end_index = int(data["end_index"])

    if control_points.ndim != 2 or control_points.shape[1] != 3:
        raise ValueError("control_points must have shape (N, 3)")

    return LoadedCurve(
        control_points=control_points,
        initial_index=initial_index,
        end_index=end_index,
    )


def build_scaled_spline(control_points: np.ndarray) -> SplineCurve:
    """Recreate the B-spline and its unit-sphere scaling from the saved control points."""

    degree = min(3, len(control_points) - 1)
    x_vals, y_vals, z_vals = control_points.T
    tck, _ = splprep([x_vals, y_vals, z_vals], s=0.0, k=degree)

    probe_u = np.linspace(0.0, 1.0, 2000)
    probe_curve = np.vstack(splev(probe_u, tck)).T
    max_radius = float(np.linalg.norm(probe_curve, axis=1).max())
    scale = 1.0 if max_radius == 0.0 else 1.0 / max_radius

    return SplineCurve(tck=tck, scale=scale, max_radius_before_scaling=max_radius)


def build_timebase(
    *,
    duration_s: float,
    dt_ms: int | None,
    samples: int,
    stationary_ms: int,
) -> tuple[np.ndarray, np.ndarray, int]:
    """Create timestamps in seconds and milliseconds.

    Returns timestamps_ms, timestamps_s, dynamic_start_index.
    """

    if duration_s <= 0.0:
        raise ValueError("duration_s must be positive")
    if stationary_ms < 0:
        raise ValueError("stationary_ms must be non-negative")

    if dt_ms is not None:
        if dt_ms <= 0:
            raise ValueError("dt_ms must be positive")
        dynamic_ms = np.arange(
            0,
            int(round(duration_s * 1000.0)) + dt_ms,
            dt_ms,
            dtype=int,
        )
        dynamic_s = dynamic_ms / 1000.0
    else:
        if samples < 2:
            raise ValueError("samples must be at least 2")
        dynamic_s = np.linspace(0.0, duration_s, samples)
        dynamic_ms = np.rint(dynamic_s * 1000.0).astype(int)

    if stationary_ms == 0:
        return dynamic_ms, dynamic_s, 0

    if dt_ms is None:
        if len(dynamic_ms) < 2:
            raise ValueError("cannot infer sample interval from fewer than 2 samples")
        lead_dt_ms = int(dynamic_ms[1] - dynamic_ms[0])
    else:
        lead_dt_ms = dt_ms

    if lead_dt_ms <= 0:
        raise ValueError("sample interval must be positive")

    stationary_ms = int(np.ceil(stationary_ms / lead_dt_ms) * lead_dt_ms)
    lead_ms = np.arange(0, stationary_ms, lead_dt_ms, dtype=int)
    full_ms = np.concatenate([lead_ms, dynamic_ms + stationary_ms])
    full_s = full_ms / 1000.0
    dynamic_start_index = len(lead_ms)
    return full_ms, full_s, dynamic_start_index


def normalize(vector: np.ndarray, fallback: np.ndarray | None = None) -> np.ndarray:
    norm = float(np.linalg.norm(vector))
    if norm > 1e-9:
        return vector / norm
    if fallback is not None:
        return fallback.copy()
    raise ValueError("cannot normalize zero-length vector")


def choose_reference_normal(tangent: np.ndarray) -> np.ndarray:
    candidates = (
        np.array([0.0, 0.0, 1.0]),
        np.array([0.0, 1.0, 0.0]),
        np.array([1.0, 0.0, 0.0]),
    )
    for candidate in candidates:
        projected = candidate - np.dot(candidate, tangent) * tangent
        if np.linalg.norm(projected) > 1e-6:
            return normalize(projected)
    raise ValueError("could not find a valid normal direction")


def quintic_rest_to_rest_profile(
    time_s: np.ndarray,
    duration_s: float,
) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Return parameter, rate, and acceleration for a rest-to-rest quintic profile."""

    tau = np.clip(time_s / duration_s, 0.0, 1.0)
    u = 10.0 * tau**3 - 15.0 * tau**4 + 6.0 * tau**5
    u_dot = (30.0 * tau**2 - 60.0 * tau**3 + 30.0 * tau**4) / duration_s
    u_ddot = (60.0 * tau - 180.0 * tau**2 + 120.0 * tau**3) / (duration_s**2)
    return u, u_dot, u_ddot


def build_body_frames(
    velocity_nav: np.ndarray,
    acceleration_nav: np.ndarray,
) -> np.ndarray:
    """Build a right-handed body frame [T, N, B] expressed in navigation coordinates."""

    num_samples = len(velocity_nav)
    rotation_nav_from_body = np.zeros((num_samples, 3, 3), dtype=float)
    previous_tangent = np.array([1.0, 0.0, 0.0], dtype=float)
    previous_normal = np.array([0.0, 1.0, 0.0], dtype=float)

    for index in range(num_samples):
        tangent = normalize(velocity_nav[index], fallback=previous_tangent)

        normal_component = (
            acceleration_nav[index]
            - np.dot(acceleration_nav[index], tangent) * tangent
        )
        if np.linalg.norm(normal_component) <= 1e-8:
            normal_component = previous_normal - np.dot(previous_normal, tangent) * tangent

        if np.linalg.norm(normal_component) <= 1e-8:
            normal = choose_reference_normal(tangent)
        else:
            normal = normalize(normal_component)

        binormal = np.cross(tangent, normal)
        if np.linalg.norm(binormal) <= 1e-8:
            normal = choose_reference_normal(tangent)
            binormal = np.cross(tangent, normal)

        binormal = normalize(binormal)
        normal = normalize(np.cross(binormal, tangent))

        rotation_nav_from_body[index] = np.column_stack((tangent, normal, binormal))
        previous_tangent = tangent
        previous_normal = normal

    return rotation_nav_from_body


def compute_body_angular_rate(
    rotation_nav_from_body: np.ndarray,
    time_s: np.ndarray,
) -> np.ndarray:
    """Compute body angular rate from the time derivative of the body frame."""

    rotation_derivative = np.gradient(rotation_nav_from_body, time_s, axis=0)
    angular_rate_body = np.zeros((len(time_s), 3), dtype=float)

    for index in range(len(time_s)):
        skew_matrix = rotation_nav_from_body[index].T @ rotation_derivative[index]
        skew_matrix = 0.5 * (skew_matrix - skew_matrix.T)
        angular_rate_body[index] = np.array(
            [
                skew_matrix[2, 1],
                skew_matrix[0, 2],
                skew_matrix[1, 0],
            ],
            dtype=float,
        )

    return angular_rate_body


def sample_trajectory(
    spline: SplineCurve,
    *,
    duration_s: float,
    dt_ms: int | None,
    samples: int,
    length_scale: float,
    stationary_ms: int,
) -> TrajectorySamples:
    """Sample spline kinematics and convert them to IMU measurements.

    The exported motion is a rest-to-rest traversal of the spline, which is compatible
    with the MATLAB dead-reckoning script's zero initial position and zero initial
    velocity assumptions. The body frame is held aligned with the navigation frame,
    so gyroscope output is zero and accelerometer output is simply a_nav + g_nav.
    """

    timestamps_ms, time_s, dynamic_start = build_timebase(
        duration_s=duration_s,
        dt_ms=dt_ms,
        samples=samples,
        stationary_ms=stationary_ms,
    )

    dynamic_time_s = time_s[dynamic_start:] - time_s[dynamic_start]
    if len(dynamic_time_s) < 2:
        raise ValueError("trajectory must contain at least 2 dynamic samples")

    u, u_dot, u_ddot = quintic_rest_to_rest_profile(dynamic_time_s, duration_s)
    position_dynamic = spline.scale * length_scale * np.vstack(splev(u, spline.tck)).T
    first_derivative = spline.scale * length_scale * np.vstack(
        splev(u, spline.tck, der=1)
    ).T
    second_derivative = spline.scale * length_scale * np.vstack(
        splev(u, spline.tck, der=2)
    ).T

    position_dynamic = position_dynamic - position_dynamic[0]
    velocity_dynamic = first_derivative * u_dot[:, np.newaxis]
    acceleration_dynamic = (
        second_derivative * (u_dot[:, np.newaxis] ** 2)
        + first_derivative * u_ddot[:, np.newaxis]
    )
    accelerometer_body_dynamic = acceleration_dynamic + GRAVITY_NAV
    angular_rate_dynamic = np.zeros_like(accelerometer_body_dynamic)

    total_samples = len(time_s)
    position_nav = np.zeros((total_samples, 3), dtype=float)
    velocity_nav = np.zeros((total_samples, 3), dtype=float)
    acceleration_nav = np.zeros((total_samples, 3), dtype=float)
    specific_force_body = np.zeros((total_samples, 3), dtype=float)
    angular_rate_body = np.zeros((total_samples, 3), dtype=float)

    position_nav[dynamic_start:] = position_dynamic
    velocity_nav[dynamic_start:] = velocity_dynamic
    acceleration_nav[dynamic_start:] = acceleration_dynamic
    specific_force_body[dynamic_start:] = accelerometer_body_dynamic
    angular_rate_body[dynamic_start:] = angular_rate_dynamic

    if dynamic_start > 0:
        position_nav[:dynamic_start] = position_dynamic[0]
        specific_force_body[:dynamic_start] = np.array([0.0, 0.0, -9.81], dtype=float)

    return TrajectorySamples(
        timestamps_ms=timestamps_ms,
        time_s=time_s,
        position_nav=position_nav,
        velocity_nav=velocity_nav,
        acceleration_nav=acceleration_nav,
        specific_force_body=specific_force_body,
        angular_rate_body=angular_rate_body,
    )


def sample_reference_curve(
    spline: SplineCurve,
    *,
    duration_s: float,
    dt_ms: int | None,
    samples: int,
    length_scale: float,
    stationary_ms: int,
) -> tuple[np.ndarray, np.ndarray]:
    """Sample the source spline using the same rest-to-rest motion law as IMU export."""

    timestamps_ms, time_s, dynamic_start = build_timebase(
        duration_s=duration_s,
        dt_ms=dt_ms,
        samples=samples,
        stationary_ms=stationary_ms,
    )
    dynamic_time_s = time_s[dynamic_start:] - time_s[dynamic_start]
    u, _, _ = quintic_rest_to_rest_profile(dynamic_time_s, duration_s)
    position_dynamic = spline.scale * length_scale * np.vstack(splev(u, spline.tck)).T
    position_dynamic = position_dynamic - position_dynamic[0]
    return timestamps_ms[dynamic_start:], position_dynamic


def write_imu_csv(path: Path, trajectory: TrajectorySamples) -> None:
    """Write the generated IMU stream as tab-separated CSV with no header."""

    matrix = np.column_stack(
        [
            trajectory.timestamps_ms,
            trajectory.specific_force_body,
            trajectory.angular_rate_body,
        ]
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    np.savetxt(
        path,
        matrix,
        delimiter="\t",
        fmt=["%d", "%.10f", "%.10f", "%.10f", "%.10f", "%.10f", "%.10f"],
    )


def load_imu_csv(path: Path) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Load tab-delimited IMU CSV (no header). Returns (time_ms, acc_b, gyro_b)."""
    data = np.loadtxt(path, delimiter="\t", dtype=float)
    if data.ndim == 1:
        data = data.reshape(1, -1)
    time_ms = data[:, 0]
    acc_b = data[:, 1:4]
    gyro_b = data[:, 4:7]
    return time_ms, acc_b, gyro_b


def dead_reckoning_from_imu(
    time_ms: np.ndarray,
    acc_b: np.ndarray,
    gyro_b: np.ndarray,
    g_n: np.ndarray,
    *,
    data_pts_to_skip: int = 3,
    data_pts_for_zeroing: int = 20,
    resample_dt_ms: int = 10,
) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    """Run DCM dead reckoning matching ideal_IMU_DCM_script.m run_dead_reckoning."""
    start_index = max(data_pts_to_skip - 1, 0)
    time_ms = time_ms[start_index:]
    acc_b = acc_b[start_index:]
    gyro_b = gyro_b[start_index:]

    acc_offset = np.mean(acc_b[:data_pts_for_zeroing], axis=0)
    acc_offset[2] = acc_offset[2] - g_n[2]
    acc_b = acc_b - acc_offset
    gyro_b = gyro_b - np.mean(gyro_b[:data_pts_for_zeroing], axis=0)

    time_ms_0 = time_ms - time_ms[0]
    time_elapsed_ms = time_ms_0[-1] - time_ms_0[0]
    time_resmpl_ms = np.arange(0, time_elapsed_ms + resample_dt_ms, resample_dt_ms, dtype=float)
    time_s = time_resmpl_ms / 1000.0
    dt_s = resample_dt_ms / 1000.0

    acc_b_resmpl = np.column_stack([
        np.interp(time_resmpl_ms, time_ms_0, acc_b[:, 0]),
        np.interp(time_resmpl_ms, time_ms_0, acc_b[:, 1]),
        np.interp(time_resmpl_ms, time_ms_0, acc_b[:, 2]),
    ])
    gyro_b_resmpl = np.column_stack([
        np.interp(time_resmpl_ms, time_ms_0, gyro_b[:, 0]),
        np.interp(time_resmpl_ms, time_ms_0, gyro_b[:, 1]),
        np.interp(time_resmpl_ms, time_ms_0, gyro_b[:, 2]),
    ])

    n = len(time_s)
    attitude_dcm = np.tile(np.eye(3), (n, 1, 1))
    pos_n = np.zeros((n, 3))
    vel_n = np.zeros((n, 3))

    for t in range(n - 1):
        acc_n = attitude_dcm[t] @ acc_b_resmpl[t] - g_n
        vel_n[t + 1] = vel_n[t] + dt_s * acc_n
        pos_n[t + 1] = pos_n[t] + dt_s * vel_n[t]

        sigma = np.linalg.norm(gyro_b_resmpl[t]) * dt_s
        if sigma >= 1e-6:
            coeff = np.sin(sigma) / sigma
            coeff_sq = (1 - np.cos(sigma)) / (sigma**2)
        else:
            coeff = 1.0
            coeff_sq = 0.5
        omega = np.array([
            [0, -gyro_b_resmpl[t, 2], gyro_b_resmpl[t, 1]],
            [gyro_b_resmpl[t, 2], 0, -gyro_b_resmpl[t, 0]],
            [-gyro_b_resmpl[t, 1], gyro_b_resmpl[t, 0], 0],
        ], dtype=float)
        delturn = omega * dt_s
        exp_delturn = np.eye(3) + coeff * delturn + coeff_sq * (delturn @ delturn)
        attitude_dcm[t + 1] = attitude_dcm[t] @ exp_delturn

    return time_s, pos_n, vel_n, attitude_dcm


def visualize_imu_csv(
    csv_path: Path,
    *,
    show: bool = True,
    save: Path | None = None,
    reference_npz: Path | None = None,
    duration_s: float = 20.0,
    dt_ms: int | None = 10,
    samples: int = 2001,
    length_scale: float = 1.0,
    stationary_ms: int = 300,
) -> None:
    """Load IMU CSV, run dead reckoning, and plot 3D trajectory.

    When a reference .npz is provided, the plot overlays the original spline path
    sampled with the same rest-to-rest timing law used for export.
    """
    time_ms, acc_b, gyro_b = load_imu_csv(csv_path)
    _, pos_n, _, _ = dead_reckoning_from_imu(
        time_ms, acc_b, gyro_b, GRAVITY_NAV
    )

    fig = plt.figure(figsize=(10, 8))
    ax = fig.add_subplot(111, projection="3d")
    ax.plot(pos_n[:, 0], pos_n[:, 1], pos_n[:, 2], "b-", linewidth=2, label="Dead reckoning")

    combined_points = [pos_n]
    if reference_npz is not None:
        loaded_curve = load_control_points(reference_npz)
        spline = build_scaled_spline(loaded_curve.control_points)
        _, reference_position = sample_reference_curve(
            spline,
            duration_s=duration_s,
            dt_ms=dt_ms,
            samples=samples,
            length_scale=length_scale,
            stationary_ms=stationary_ms,
        )
        ax.plot(
            reference_position[:, 0],
            reference_position[:, 1],
            reference_position[:, 2],
            "r--",
            linewidth=2,
            label="Reference spline",
        )
        combined_points.append(reference_position)

    ax.set_xlabel("x [m]")
    ax.set_ylabel("y [m]")
    ax.set_zlabel("z [m]")
    ax.set_title("Trajectory from IMU CSV (Python dead reckoning)")
    ax.legend()
    ax.grid(True)

    plot_points = np.vstack(combined_points)
    xr = plot_points[:, 0].min(), plot_points[:, 0].max()
    yr = plot_points[:, 1].min(), plot_points[:, 1].max()
    zr = plot_points[:, 2].min(), plot_points[:, 2].max()
    span = max(xr[1] - xr[0], yr[1] - yr[0], zr[1] - zr[0], 0.2)
    mx = (xr[0] + xr[1]) / 2
    my = (yr[0] + yr[1]) / 2
    mz = (zr[0] + zr[1]) / 2
    ax.set_xlim(mx - span / 2, mx + span / 2)
    ax.set_ylim(my - span / 2, my + span / 2)
    ax.set_zlim(mz - span / 2, mz + span / 2)
    ax.set_box_aspect((1, 1, 1))

    fig.tight_layout()
    if save is not None:
        save.parent.mkdir(parents=True, exist_ok=True)
        fig.savefig(save, dpi=150, bbox_inches="tight")
        console.print(f"[bold]Saved:[/bold] {save}")
    if show:
        plt.show()
    else:
        plt.close(fig)


@app.callback()
def main(
    ctx: typer.Context,
    input_path: Annotated[
        Path,
        typer.Option("--input", "-i", help="Path to the saved control-point .npz file."),
    ] = DEFAULT_INPUT,
    output_path: Annotated[
        Path,
        typer.Option("--output", "-o", help="Path to the output IMU CSV file."),
    ] = DEFAULT_OUTPUT,
    duration_s: Annotated[
        float,
        typer.Option(help="Total dynamic traversal time in seconds."),
    ] = 20.0,
    dt_ms: Annotated[
        int | None,
        typer.Option(help="Sample interval in milliseconds. Overrides --samples when set."),
    ] = 10,
    samples: Annotated[
        int,
        typer.Option(min=2, help="Number of dynamic samples when --dt-ms is not used."),
    ] = 2001,
    length_scale: Annotated[
        float,
        typer.Option(help="Meters per unit-radius curve coordinate."),
    ] = 1.0,
    stationary_ms: Annotated[
        int,
        typer.Option(
            help="Optional stationary lead-in before motion to help zero-offset routines.",
        ),
    ] = 300,
) -> None:
    if ctx.invoked_subcommand is not None:
        return

    input_path = Path(input_path)
    output_path = Path(output_path)

    if not input_path.exists():
        raise typer.BadParameter(f"Input file does not exist: {input_path}")
    if length_scale <= 0.0:
        raise typer.BadParameter("length_scale must be positive")

    loaded_curve = load_control_points(input_path)
    spline = build_scaled_spline(loaded_curve.control_points)
    trajectory = sample_trajectory(
        spline,
        duration_s=duration_s,
        dt_ms=dt_ms,
        samples=samples,
        length_scale=length_scale,
        stationary_ms=stationary_ms,
    )
    write_imu_csv(output_path, trajectory)

    console.print(f"[bold]Input file:[/bold] {input_path}")
    console.print(
        "[bold]Control points:[/bold] "
        f"{len(loaded_curve.control_points)} (initial={loaded_curve.initial_index}, "
        f"end={loaded_curve.end_index})"
    )
    console.print(
        f"[bold]Max radius before scaling:[/bold] {spline.max_radius_before_scaling:.6f}"
    )
    console.print(f"[bold]Rows written:[/bold] {len(trajectory.timestamps_ms)}")
    console.print(
        "[bold]Time span:[/bold] "
        f"{trajectory.timestamps_ms[0]} ms -> {trajectory.timestamps_ms[-1]} ms"
    )
    console.print(f"[bold]Output file:[/bold] {output_path}")
    console.print("[green]Tab-delimited IMU export complete.[/green]")


@app.command()
def visualize(
    csv_path: Annotated[
        Path,
        typer.Argument(help="Path to the IMU CSV (e.g. IMU_from_curve.csv)."),
    ],
    reference_npz: Annotated[
        Path | None,
        typer.Option(
            "--reference-npz",
            help="Optional saved control-point .npz to overlay as the reference spline.",
        ),
    ] = None,
    save: Annotated[
        Path | None,
        typer.Option("--save", "-s", help="Save figure to this path instead of showing."),
    ] = None,
    no_show: Annotated[
        bool,
        typer.Option("--no-show", help="Do not open the plot window (use with --save)."),
    ] = False,
    duration_s: Annotated[
        float,
        typer.Option(help="Dynamic traversal time used for the reference overlay."),
    ] = 20.0,
    dt_ms: Annotated[
        int | None,
        typer.Option(help="Sample interval used for the reference overlay."),
    ] = 10,
    samples: Annotated[
        int,
        typer.Option(min=2, help="Number of samples used when --dt-ms is not set."),
    ] = 2001,
    length_scale: Annotated[
        float,
        typer.Option(help="Meters per unit-radius used for the reference overlay."),
    ] = 1.0,
    stationary_ms: Annotated[
        int,
        typer.Option(help="Stationary lead-in used for the reference overlay."),
    ] = 300,
) -> None:
    """Run dead reckoning on an IMU CSV and plot the 3D trajectory (cross-check with MATLAB)."""
    csv_path = Path(csv_path)
    if not csv_path.exists():
        raise typer.BadParameter(f"File not found: {csv_path}")
    if reference_npz is not None and not Path(reference_npz).exists():
        raise typer.BadParameter(f"Reference file not found: {reference_npz}")
    console.print(f"[bold]Loading:[/bold] {csv_path}")
    visualize_imu_csv(
        csv_path,
        show=not no_show,
        save=save,
        reference_npz=Path(reference_npz) if reference_npz is not None else None,
        duration_s=duration_s,
        dt_ms=dt_ms,
        samples=samples,
        length_scale=length_scale,
        stationary_ms=stationary_ms,
    )


if __name__ == "__main__":
    app()
