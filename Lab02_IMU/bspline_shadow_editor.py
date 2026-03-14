from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Annotated

import matplotlib.pyplot as plt
import numpy as np
import typer
from matplotlib.lines import Line2D
from rich.console import Console
from scipy.interpolate import splev, splprep

console = Console()
app = typer.Typer(help="Generate a 3D B-spline whose shadows resemble 1, 2, and 3.")


@dataclass
class CurveData:
    control_points: np.ndarray
    curve_points: np.ndarray
    max_radius_before_scaling: float
    max_radius_after_scaling: float


@dataclass(frozen=True)
class ProjectionSpec:
    name: str
    x_index: int
    y_index: int
    title: str
    x_label: str
    y_label: str
    invert_y: bool = False


@dataclass
class ProjectionArtists:
    ax: plt.Axes
    curve_line: Line2D
    control_line: Line2D


@dataclass
class FigureArtists:
    figure: plt.Figure
    projections: dict[str, ProjectionArtists]
    ax_3d: plt.Axes
    curve_3d: object
    control_3d: object


PROJECTION_SPECS: tuple[ProjectionSpec, ...] = (
    ProjectionSpec("xy", 0, 1, "XY Projection (Digit 1)", "X", "Y", invert_y=True),
    ProjectionSpec("yz", 1, 2, "YZ Projection (Digit 3)", "Y", "Z"),
    ProjectionSpec("xz", 0, 2, "XZ Projection (Digit 2)", "X", "Z"),
)
PROJECTION_MAP = {spec.name: spec for spec in PROJECTION_SPECS}

OUTPUT_DIR = Path("output")
DEFAULT_POINTS_FILE = OUTPUT_DIR / "control_points.npz"


def save_control_points(path: Path, control_points: np.ndarray) -> None:
    """Save control points to a .npz with initial/end indices labeled (0 and N-1)."""
    n = len(control_points)
    np.savez(
        path,
        control_points=control_points,
        initial_index=np.int64(0),
        end_index=np.int64(n - 1),
    )
    console.print(f"[green]Control points saved:[/green] {path} (initial=0, end={n - 1})")


def load_control_points(path: Path) -> tuple[np.ndarray, int, int] | None:
    """Load control points from .npz. Returns (points, initial_index, end_index) or None if missing/invalid."""
    if not path.exists():
        return None
    try:
        data = np.load(path, allow_pickle=False)
        control_points = np.asarray(data["control_points"], dtype=float)
        initial_index = int(data["initial_index"])
        end_index = int(data["end_index"])
        if control_points.ndim != 2 or control_points.shape[1] != 3:
            return None
        return control_points, initial_index, end_index
    except Exception:
        return None


def build_control_points() -> np.ndarray:
    """Return one continuous 3D control polygon for the shadow puzzle.

    The points are tuned so that:
    - XY is a slim, serif-like "1"
    - YZ is a rounded "2"
    - XZ is a double-lobed "3"

    The trade-off is intentional: each point serves three projections at once.
    """

    return np.array(
        [
            # Top bar of "1" and the top stroke of "2".
            [0.18, -0.72, 0.64],
            [0.32, -0.72, 0.70],
            [0.46, -0.72, 0.66],
            # Down the stem while XZ rounds the upper lobe of "3".
            [0.32, -0.44, 0.50],
            [0.22, -0.22, 0.30],
            [0.30, -0.06, 0.10],
            # Small middle barb so XY still reads like a stylized "1".
            [0.44, 0.02, 0.00],
            [0.32, 0.06, -0.18],
            # Lower sweep for the second lobe of "3".
            [0.24, 0.28, -0.38],
            [0.34, 0.50, -0.56],
            # Bottom bar of "1" and the baseline of "2".
            [0.16, 0.72, -0.68],
            [0.30, 0.72, -0.70],
            [0.44, 0.72, -0.68],
        ],
        dtype=float,
    )


def evaluate_curve(control_points: np.ndarray, samples: int) -> CurveData:
    """Interpolate the control points and scale the result into the unit sphere."""

    x_vals, y_vals, z_vals = control_points.T
    degree = min(3, len(control_points) - 1)
    tck, _ = splprep([x_vals, y_vals, z_vals], s=0.0, k=degree)
    parameter_values = np.linspace(0.0, 1.0, samples)
    curve_points = np.vstack(splev(parameter_values, tck)).T

    radii = np.linalg.norm(curve_points, axis=1)
    max_radius = float(radii.max())
    scale = 1.0 if max_radius == 0.0 else 1.0 / max_radius

    return CurveData(
        control_points=control_points * scale,
        curve_points=curve_points * scale,
        max_radius_before_scaling=max_radius,
        max_radius_after_scaling=float(np.linalg.norm(curve_points * scale, axis=1).max()),
    )


def configure_projection_axis(ax: plt.Axes, spec: ProjectionSpec) -> None:
    ax.set_title(spec.title)
    ax.set_xlabel(spec.x_label)
    ax.set_ylabel(spec.y_label)
    ax.grid(True, alpha=0.25)
    ax.set_aspect("equal", adjustable="box")
    ax.set_xlim(-1.05, 1.05)
    if spec.invert_y:
        ax.set_ylim(1.05, -1.05)
    else:
        ax.set_ylim(-1.05, 1.05)


def set_equal_3d(ax: plt.Axes) -> None:
    ax.set_xlim(-1.0, 1.0)
    ax.set_ylim(-1.0, 1.0)
    ax.set_zlim(-1.0, 1.0)
    ax.set_box_aspect((1.0, 1.0, 1.0))


def project_points(points: np.ndarray, spec: ProjectionSpec) -> tuple[np.ndarray, np.ndarray]:
    return points[:, spec.x_index], points[:, spec.y_index]


def create_figure() -> FigureArtists:
    figure = plt.figure(figsize=(12, 10))
    grid = figure.add_gridspec(2, 2)

    projection_axes = (
        figure.add_subplot(grid[0, 0]),
        figure.add_subplot(grid[0, 1]),
        figure.add_subplot(grid[1, 0]),
    )
    ax_3d = figure.add_subplot(grid[1, 1], projection="3d")
    projections: dict[str, ProjectionArtists] = {}

    for spec, ax in zip(PROJECTION_SPECS, projection_axes, strict=True):
        configure_projection_axis(ax, spec)
        curve_line, = ax.plot([], [], color="#1f77b4", linewidth=2.5)
        control_line, = ax.plot(
            [],
            [],
            "o--",
            color="#ff7f0e",
            alpha=0.45,
            markersize=6,
            picker=False,
        )
        projections[spec.name] = ProjectionArtists(
            ax=ax,
            curve_line=curve_line,
            control_line=control_line,
        )

    curve_3d, = ax_3d.plot(
        [],
        [],
        [],
        color="#1f77b4",
        linewidth=2.5,
        label="B-spline curve",
    )
    control_3d, = ax_3d.plot(
        [],
        [],
        [],
        "o--",
        color="#ff7f0e",
        alpha=0.35,
        markersize=6,
        label="Control polygon",
    )

    phi = np.linspace(0.0, np.pi, 25)
    theta = np.linspace(0.0, 2.0 * np.pi, 40)
    sphere_x = np.outer(np.sin(phi), np.cos(theta))
    sphere_y = np.outer(np.sin(phi), np.sin(theta))
    sphere_z = np.outer(np.cos(phi), np.ones_like(theta))
    ax_3d.plot_wireframe(
        sphere_x,
        sphere_y,
        sphere_z,
        color="gray",
        linewidth=0.5,
        alpha=0.25,
    )

    ax_3d.set_title("3D Curve Inside Unit Sphere")
    ax_3d.set_xlabel("X")
    ax_3d.set_ylabel("Y")
    ax_3d.set_zlabel("Z")
    set_equal_3d(ax_3d)
    ax_3d.legend(loc="upper left")

    figure.suptitle("3D B-Spline Shadow Puzzle", fontsize=16)
    figure.text(
        0.5,
        0.02,
        "Drag orange control points in XY, YZ, or XZ. r=reset, s=save control points.",
        ha="center",
    )
    figure.tight_layout(rect=(0.0, 0.04, 1.0, 0.97))
    return FigureArtists(
        figure=figure,
        projections=projections,
        ax_3d=ax_3d,
        curve_3d=curve_3d,
        control_3d=control_3d,
    )


def update_figure_artists(artists: FigureArtists, curve_data: CurveData) -> None:
    for spec in PROJECTION_SPECS:
        projection = artists.projections[spec.name]
        curve_x, curve_y = project_points(curve_data.curve_points, spec)
        control_x, control_y = project_points(curve_data.control_points, spec)
        projection.curve_line.set_data(curve_x, curve_y)
        projection.control_line.set_data(control_x, control_y)

    artists.curve_3d.set_data_3d(
        curve_data.curve_points[:, 0],
        curve_data.curve_points[:, 1],
        curve_data.curve_points[:, 2],
    )
    artists.control_3d.set_data_3d(
        curve_data.control_points[:, 0],
        curve_data.control_points[:, 1],
        curve_data.control_points[:, 2],
    )


def build_figure(curve_data: CurveData) -> plt.Figure:
    artists = create_figure()
    update_figure_artists(artists, curve_data)
    return artists.figure


def print_curve_summary(curve_data: CurveData) -> None:
    console.print(f"[bold]Control points:[/bold] {len(curve_data.control_points)}")
    console.print(
        "[bold]Max radius before scaling:[/bold] "
        f"{curve_data.max_radius_before_scaling:.4f}"
    )
    console.print(
        "[bold]Max radius after scaling:[/bold] "
        f"{curve_data.max_radius_after_scaling:.4f}"
    )
    console.print("[green]Curve fits inside the unit sphere.[/green]")


class ControlPointEditor:
    """Interactive matplotlib editor for the shared 3D control polygon."""

    pick_radius_pixels = 12.0

    def __init__(
        self,
        control_points: np.ndarray,
        samples: int,
        points_file: Path = DEFAULT_POINTS_FILE,
    ) -> None:
        self.initial_control_points = np.array(control_points, dtype=float, copy=True)
        self.control_points = np.array(control_points, dtype=float, copy=True)
        self.samples = samples
        self.points_file = Path(points_file)
        self.artists = create_figure()
        self.axis_to_projection = {
            projection.ax: name for name, projection in self.artists.projections.items()
        }
        self.active_drag: tuple[str, int] | None = None
        self.refresh()

        canvas = self.artists.figure.canvas
        canvas.mpl_connect("button_press_event", self.on_press)
        canvas.mpl_connect("motion_notify_event", self.on_motion)
        canvas.mpl_connect("button_release_event", self.on_release)
        canvas.mpl_connect("key_press_event", self.on_key_press)

    def refresh(self) -> None:
        curve_data = evaluate_curve(self.control_points, samples=self.samples)
        self.control_points = curve_data.control_points.copy()
        update_figure_artists(self.artists, curve_data)
        self.artists.figure.canvas.draw_idle()

    def find_closest_point(self, projection_name: str, event: object) -> int | None:
        spec = PROJECTION_MAP[projection_name]
        ax = self.artists.projections[projection_name].ax
        point_xy = np.column_stack(project_points(self.control_points, spec))
        point_pixels = ax.transData.transform(point_xy)
        event_pixels = np.array([event.x, event.y], dtype=float)
        distances = np.linalg.norm(point_pixels - event_pixels, axis=1)
        nearest = int(np.argmin(distances))
        if distances[nearest] <= self.pick_radius_pixels:
            return nearest
        return None

    def on_press(self, event: object) -> None:
        projection_name = self.axis_to_projection.get(event.inaxes)
        if projection_name is None or event.x is None or event.y is None:
            return

        point_index = self.find_closest_point(projection_name, event)
        if point_index is not None:
            self.active_drag = (projection_name, point_index)

    def on_motion(self, event: object) -> None:
        if self.active_drag is None or event.xdata is None or event.ydata is None:
            return

        projection_name, point_index = self.active_drag
        expected_ax = self.artists.projections[projection_name].ax
        if event.inaxes is not expected_ax:
            return

        spec = PROJECTION_MAP[projection_name]
        previous_control_points = self.control_points.copy()
        self.control_points[point_index, spec.x_index] = float(np.clip(event.xdata, -1.0, 1.0))
        self.control_points[point_index, spec.y_index] = float(np.clip(event.ydata, -1.0, 1.0))
        try:
            self.refresh()
        except ValueError:
            self.control_points = previous_control_points

    def on_release(self, _: object) -> None:
        self.active_drag = None

    def on_key_press(self, event: object) -> None:
        if event.key == "r":
            self.control_points = self.initial_control_points.copy()
            self.refresh()
            console.print("[yellow]Control points reset.[/yellow]")
        elif event.key == "s":
            self.points_file.parent.mkdir(parents=True, exist_ok=True)
            save_control_points(self.points_file, self.control_points)


@app.command()
def main(
    points: Annotated[
        int,
        typer.Option(min=200, help="Number of samples used to evaluate the spline."),
    ] = 1000,
    show: Annotated[
        bool,
        typer.Option("--show/--no-show", help="Display the matplotlib window."),
    ] = True,
    edit: Annotated[
        bool,
        typer.Option(help="Launch the interactive control-point editor."),
    ] = False,
    points_file: Annotated[
        Path,
        typer.Option(
            "--points-file",
            help="In edit mode: load control points from this file if it exists; press 's' to save here.",
        ),
    ] = DEFAULT_POINTS_FILE,
    save: Annotated[
        Path | None,
        typer.Option(help="Optional output path for the rendered figure."),
    ] = None,
) -> None:
    points_file = Path(points_file)
    console.print(f"[bold]Spline samples:[/bold] {points}")

    if edit and points_file.exists():
        loaded = load_control_points(points_file)
        if loaded is not None:
            control_points, init_idx, end_idx = loaded
            console.print(
                f"[cyan]Loaded control points from[/cyan] {points_file} "
                f"(initial={init_idx}, end={end_idx}, n={len(control_points)})"
            )
            curve_data = evaluate_curve(control_points, samples=points)
        else:
            control_points = build_control_points()
            curve_data = evaluate_curve(control_points, samples=points)
            console.print("[yellow]Could not load points file; using default control points.[/yellow]")
    else:
        control_points = build_control_points()
        curve_data = evaluate_curve(control_points, samples=points)

    print_curve_summary(curve_data)

    if edit:
        console.print(
            "[cyan]Interactive mode:[/cyan] drag orange control points in XY, YZ, or XZ. "
            "[bold]r[/bold]=reset, [bold]s[/bold]=save control points to "
            f"[bold]{points_file}[/bold]."
        )
        editor = ControlPointEditor(
            curve_data.control_points,
            samples=points,
            points_file=points_file,
        )
        figure = editor.artists.figure
    else:
        figure = build_figure(curve_data)

    if show:
        plt.show()
    else:
        figure.canvas.draw()

    if save is not None:
        save.parent.mkdir(parents=True, exist_ok=True)
        figure.savefig(save, dpi=200, bbox_inches="tight")
        console.print(f"[bold]Saved figure:[/bold] {save}")

    if not show:
        plt.close(figure)


if __name__ == "__main__":
    app()
