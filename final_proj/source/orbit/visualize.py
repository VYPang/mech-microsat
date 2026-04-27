"""Plotly visualisation of the L4 orbit in the rotating reference frame.

Produces dark-themed interactive plots matching the aesthetic of the
Uranus-trojan reference image: Sun at origin (yellow), Earth on +x (green),
satellite trace coloured by time.
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
import plotly.graph_objects as go
import polars as pl


_AU = 1.496e11  # metres
_DEFAULT_MAX_POINTS = 50_000  # keep HTML files small & browser responsive
_DEFAULT_ANIMATION_POINTS = 2_000


def _downsample(df: pl.DataFrame, max_points: int) -> pl.DataFrame:
    """Uniformly downsample a DataFrame if it exceeds *max_points* rows."""
    if df.height <= max_points:
        return df
    step = df.height // max_points
    return df.gather_every(step)


def _html_array(values: np.ndarray) -> str:
    """Return a compact JSON array string for embedding in HTML."""
    return json.dumps(np.asarray(values, dtype=float).round(6).tolist(), separators=(",", ":"))


# ---------------------------------------------------------------------------
# Dark theme template (matches the Uranus-trojan image style)
# ---------------------------------------------------------------------------

_DARK_LAYOUT = dict(
    template="plotly_dark",
    paper_bgcolor="#0e0e0e",
    plot_bgcolor="#0e0e0e",
    font=dict(color="#cccccc", size=12),
    margin=dict(l=60, r=40, t=60, b=50),
)


# ---------------------------------------------------------------------------
# Plot 1 — 2D top-down XY in rotating frame
# ---------------------------------------------------------------------------

def plot_rotating_xy(df: pl.DataFrame, max_points: int = _DEFAULT_MAX_POINTS) -> go.Figure:
    """2D top-down view of the satellite orbit in the rotating frame.

    X-axis points from Sun → Earth; L4 is at +60° from Earth
    (i.e. at x = 0.5 AU, y ≈ 0.866 AU in the rotating frame for the
    equilateral triangle).
    """
    df = _downsample(df, max_points)
    x = df["x_rot"].to_numpy() / _AU
    y = df["y_rot"].to_numpy() / _AU
    t = df["t_s"].to_numpy() / (365.25 * 86400)  # years

    # Average Earth position in rotating frame (should be ~(1, 0))
    xe = df["x_earth_rot"].to_numpy().mean() / _AU
    ye = df["y_earth_rot"].to_numpy().mean() / _AU

    # Theoretical L4 location in rotating frame: 60° from Earth at same radius
    # In the synodic frame Earth is on +x, so L4 is at angle +60° from +x
    l4_x = np.cos(np.radians(60)) * np.linalg.norm([xe, ye])
    l4_y = np.sin(np.radians(60)) * np.linalg.norm([xe, ye])

    fig = go.Figure()

    # Satellite trace
    fig.add_trace(go.Scattergl(
        x=x, y=y,
        mode="markers",
        marker=dict(
            size=1.5,
            color=t,
            colorscale="Magenta",
            colorbar=dict(title="Years", thickness=15, len=0.6),
            opacity=0.8,
        ),
        name="Satellite",
    ))

    # Sun
    fig.add_trace(go.Scatter(
        x=[0], y=[0],
        mode="markers",
        marker=dict(size=14, color="yellow", symbol="circle"),
        name="Sun",
    ))

    # Earth
    fig.add_trace(go.Scatter(
        x=[xe], y=[ye],
        mode="markers",
        marker=dict(size=10, color="#00cc66", symbol="circle"),
        name="Earth",
    ))

    # L4 theoretical
    fig.add_trace(go.Scatter(
        x=[l4_x], y=[l4_y],
        mode="markers+text",
        marker=dict(size=8, color="cyan", symbol="diamond"),
        text=["L4"],
        textposition="top center",
        textfont=dict(color="cyan", size=11),
        name="L4 (theoretical)",
    ))

    fig.update_layout(
        **_DARK_LAYOUT,
        title="Rotating Frame — XY Projection (Ecliptic Plane)",
        xaxis=dict(title="x (AU) — Sun → Earth", scaleanchor="y"),
        yaxis=dict(title="y (AU)"),
        showlegend=True,
        legend=dict(x=0.01, y=0.99),
    )
    return fig


# ---------------------------------------------------------------------------
# Plot 2 — 3D rotating frame
# ---------------------------------------------------------------------------

def plot_rotating_3d(df: pl.DataFrame, max_points: int = _DEFAULT_MAX_POINTS) -> go.Figure:
    """3D view showing out-of-plane (z) oscillation."""
    df = _downsample(df, max_points)
    x = df["x_rot"].to_numpy() / _AU
    y = df["y_rot"].to_numpy() / _AU
    z = df["z_rot"].to_numpy() / _AU
    t = df["t_s"].to_numpy() / (365.25 * 86400)

    xe = df["x_earth_rot"].to_numpy().mean() / _AU
    ye = df["y_earth_rot"].to_numpy().mean() / _AU

    fig = go.Figure()

    # Satellite 3D trace
    fig.add_trace(go.Scatter3d(
        x=x, y=y, z=z,
        mode="markers",
        marker=dict(
            size=1.2,
            color=t,
            colorscale="Magenta",
            colorbar=dict(title="Years", thickness=12, len=0.5),
            opacity=0.7,
        ),
        name="Satellite",
    ))

    # Sun
    fig.add_trace(go.Scatter3d(
        x=[0], y=[0], z=[0],
        mode="markers",
        marker=dict(size=8, color="yellow"),
        name="Sun",
    ))

    # Earth
    fig.add_trace(go.Scatter3d(
        x=[xe], y=[ye], z=[0],
        mode="markers",
        marker=dict(size=6, color="#00cc66"),
        name="Earth",
    ))

    # Ecliptic plane (translucent disc)
    r_plane = 1.3
    theta = np.linspace(0, 2 * np.pi, 60)
    r_vals = np.linspace(0, r_plane, 15)
    theta_g, r_g = np.meshgrid(theta, r_vals)
    xp = r_g * np.cos(theta_g)
    yp = r_g * np.sin(theta_g)
    zp = np.zeros_like(xp)

    fig.add_trace(go.Surface(
        x=xp, y=yp, z=zp,
        colorscale=[[0, "rgba(100,100,100,0.08)"], [1, "rgba(100,100,100,0.08)"]],
        showscale=False,
        name="Ecliptic",
        hoverinfo="skip",
    ))

    fig.update_layout(
        **_DARK_LAYOUT,
        title="Rotating Frame — 3D (14.5° Out-of-Plane)",
        scene=dict(
            xaxis=dict(title="x (AU)"),
            yaxis=dict(title="y (AU)"),
            zaxis=dict(title="z (AU)"),
            aspectmode="data",
            bgcolor="#0e0e0e",
        ),
        showlegend=True,
    )
    return fig


# ---------------------------------------------------------------------------
# Plot 3 — Z displacement vs time
# ---------------------------------------------------------------------------

def plot_z_vs_time(
    df: pl.DataFrame,
    inclination_deg: float = 14.5,
    max_points: int = _DEFAULT_MAX_POINTS,
) -> go.Figure:
    """Time series of ecliptic-normal displacement with theoretical overlay."""
    df = _downsample(df, max_points)
    t_years = df["t_s"].to_numpy() / (365.25 * 86400)
    z_au = df["z_rot"].to_numpy() / _AU

    # Theoretical sinusoid: Az * sin(n * t)
    # n ≈ 2π / 1 year for Earth co-orbital;  Az = 1 AU * tan(inc)
    az_au = np.tan(np.radians(inclination_deg))
    t_s = df["t_s"].to_numpy()
    mu_sun = 1.327_124_400_18e20
    n = np.sqrt(mu_sun / (_AU * 0.9833)**3)  # approx mean motion
    z_theory = az_au * np.sin(n * t_s)

    fig = go.Figure()

    fig.add_trace(go.Scattergl(
        x=t_years, y=z_au,
        mode="markers",
        marker=dict(size=1, color="magenta", opacity=0.6),
        name="Simulated z",
    ))

    fig.add_trace(go.Scatter(
        x=t_years, y=z_theory,
        mode="lines",
        line=dict(color="cyan", width=1.5, dash="dash"),
        name=f"Theory (inc = {inclination_deg}°)",
    ))

    fig.update_layout(
        **_DARK_LAYOUT,
        title="Out-of-Plane Displacement vs Time",
        xaxis=dict(title="Time (years)"),
        yaxis=dict(title="z (AU)"),
        showlegend=True,
    )
    return fig


# ---------------------------------------------------------------------------
# Plot 3 — Inertial 3D frame (Sun-centred ECLIPJ2000, animated)
# ---------------------------------------------------------------------------

def write_inertial_3d_html(
        df: pl.DataFrame,
        output_path: Path,
        max_points: int = _DEFAULT_ANIMATION_POINTS,
) -> Path:
        """Write a lightweight animated inertial-frame HTML visualization."""
        df = _downsample(df, max_points)

        x = df["x"].to_numpy() / _AU
        y = df["y"].to_numpy() / _AU
        z = df["z"].to_numpy() / _AU
        xe = df["x_earth"].to_numpy() / _AU
        ye = df["y_earth"].to_numpy() / _AU
        ze = df["z_earth"].to_numpy() / _AU
        t = df["t_s"].to_numpy() / (365.25 * 86400)

        r_plane = 1.3
        theta = np.linspace(0, 2 * np.pi, 60)
        r_vals = np.linspace(0, r_plane, 15)
        theta_g, r_g = np.meshgrid(theta, r_vals)
        xp = r_g * np.cos(theta_g)
        yp = r_g * np.sin(theta_g)
        zp = np.zeros_like(xp)

        html = f"""<!DOCTYPE html>
<html lang=\"en\">
<head>
    <meta charset=\"utf-8\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
    <title>Inertial Frame - 3D Animation</title>
    <script src=\"https://cdn.plot.ly/plotly-2.35.2.min.js\"></script>
    <style>
        body {{ margin: 0; background: #0e0e0e; color: #cccccc; font-family: sans-serif; }}
        #wrap {{ padding: 12px; }}
        #plot {{ width: 100%; height: 85vh; }}
        #controls {{ display: flex; gap: 12px; align-items: center; padding: 8px 4px; }}
        #slider {{ flex: 1; }}
        button {{ background: #1d1d1d; color: #cccccc; border: 1px solid #444; padding: 8px 14px; cursor: pointer; }}
        .time {{ min-width: 120px; text-align: right; font-variant-numeric: tabular-nums; }}
    </style>
</head>
<body>
    <div id=\"wrap\">
        <div id=\"controls\">
            <button id=\"play\">Play</button>
            <input id=\"slider\" type=\"range\" min=\"0\" max=\"{len(x) - 1}\" step=\"1\" value=\"0\">
            <div class=\"time\" id=\"time-label\">t = 0.00 yr</div>
        </div>
        <div id=\"plot\"></div>
    </div>
    <script>
        const satX = {_html_array(x)};
        const satY = {_html_array(y)};
        const satZ = {_html_array(z)};
        const earthX = {_html_array(xe)};
        const earthY = {_html_array(ye)};
        const earthZ = {_html_array(ze)};
        const years = {_html_array(t)};
        const planeX = {json.dumps(xp.round(6).tolist(), separators=(",", ":"))};
        const planeY = {json.dumps(yp.round(6).tolist(), separators=(",", ":"))};
        const planeZ = {json.dumps(zp.round(6).tolist(), separators=(",", ":"))};

        const plot = document.getElementById("plot");
        const slider = document.getElementById("slider");
        const play = document.getElementById("play");
        const timeLabel = document.getElementById("time-label");
        const tailLength = Math.max(12, Math.floor(satX.length / 60));
        let timer = null;

        const data = [
            {{
                type: "scatter3d",
                mode: "lines",
                x: satX,
                y: satY,
                z: satZ,
                line: {{ color: "rgba(255, 0, 255, 0.12)", width: 2 }},
                name: "Satellite path",
                hoverinfo: "skip"
            }},
            {{
                type: "scatter3d",
                mode: "lines",
                x: earthX,
                y: earthY,
                z: earthZ,
                line: {{ color: "rgba(0, 204, 102, 0.14)", width: 2 }},
                name: "Earth path",
                hoverinfo: "skip"
            }},
            {{
                type: "scatter3d",
                mode: "lines",
                x: [satX[0]],
                y: [satY[0]],
                z: [satZ[0]],
                line: {{ color: "rgba(255, 0, 255, 0.95)", width: 5 }},
                name: "Satellite trail",
                hoverinfo: "skip"
            }},
            {{
                type: "scatter3d",
                mode: "lines",
                x: [earthX[0]],
                y: [earthY[0]],
                z: [earthZ[0]],
                line: {{ color: "rgba(0, 204, 102, 0.95)", width: 5 }},
                name: "Earth trail",
                hoverinfo: "skip"
            }},
            {{
                type: "scatter3d",
                mode: "markers+text",
                x: [satX[0]],
                y: [satY[0]],
                z: [satZ[0]],
                marker: {{
                    size: 10,
                    color: "magenta",
                    line: {{ color: "white", width: 2 }}
                }},
                text: ["Sat"],
                textposition: "top center",
                textfont: {{ color: "white", size: 12 }},
                name: "Satellite"
            }},
            {{
                type: "scatter3d",
                mode: "markers+text",
                x: [earthX[0]],
                y: [earthY[0]],
                z: [earthZ[0]],
                marker: {{
                    size: 12,
                    color: "#00cc66",
                    line: {{ color: "white", width: 2 }}
                }},
                text: ["Earth"],
                textposition: "top center",
                textfont: {{ color: "white", size: 12 }},
                name: "Earth"
            }},
            {{
                type: "scatter3d",
                mode: "markers",
                x: [0], y: [0], z: [0],
                marker: {{ size: 8, color: "yellow" }},
                name: "Sun"
            }},
            {{
                type: "surface",
                x: planeX,
                y: planeY,
                z: planeZ,
                colorscale: [[0, "rgba(100,100,100,0.08)"], [1, "rgba(100,100,100,0.08)"]],
                showscale: false,
                name: "Ecliptic",
                hoverinfo: "skip"
            }}
        ];

        const layout = {{
            template: "plotly_dark",
            paper_bgcolor: "#0e0e0e",
            plot_bgcolor: "#0e0e0e",
            font: {{ color: "#cccccc", size: 12 }},
            margin: {{ l: 60, r: 40, t: 60, b: 40 }},
            title: "Inertial Frame - 3D (ECLIPJ2000)",
            scene: {{
                xaxis: {{ title: "x (AU)" }},
                yaxis: {{ title: "y (AU)" }},
                zaxis: {{ title: "z (AU)" }},
                aspectmode: "data",
                bgcolor: "#0e0e0e"
            }},
            showlegend: true
        }};

        Plotly.newPlot(plot, data, layout, {{responsive: true}});

        function updateFrame(index) {{
            const start = Math.max(0, index - tailLength);
            Plotly.restyle(plot, {{
                x: [[satX.slice(start, index + 1)]],
                y: [[satY.slice(start, index + 1)]],
                z: [[satZ.slice(start, index + 1)]]
            }}, [2]);
            Plotly.restyle(plot, {{
                x: [[earthX.slice(start, index + 1)]],
                y: [[earthY.slice(start, index + 1)]],
                z: [[earthZ.slice(start, index + 1)]]
            }}, [3]);
            Plotly.restyle(plot, {{
                x: [[satX[index]]],
                y: [[satY[index]]],
                z: [[satZ[index]]],
                text: [["Sat"]]
            }}, [4]);
            Plotly.restyle(plot, {{
                x: [[earthX[index]]],
                y: [[earthY[index]]],
                z: [[earthZ[index]]],
                text: [["Earth"]]
            }}, [5]);
            timeLabel.textContent = `t = ${{years[index].toFixed(2)}} yr`;
            slider.value = index;
        }}

        function stopAnimation() {{
            if (timer !== null) {{
                window.clearInterval(timer);
                timer = null;
                play.textContent = "Play";
            }}
        }}

        play.addEventListener("click", () => {{
            if (timer !== null) {{
                stopAnimation();
                return;
            }}
            play.textContent = "Pause";
            timer = window.setInterval(() => {{
                let next = Number(slider.value) + 1;
                if (next >= satX.length) {{
                    next = 0;
                }}
                updateFrame(next);
            }}, 60);
        }});

        slider.addEventListener("input", () => {{
            stopAnimation();
            updateFrame(Number(slider.value));
        }});

        updateFrame(0);
    </script>
</body>
</html>
"""

        output_path = Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(html, encoding="utf-8")
        return output_path


# ---------------------------------------------------------------------------
# Public entry point
# ---------------------------------------------------------------------------

def create_all_plots(
    df: pl.DataFrame,
    output_dir: Path,
    inclination_deg: float = 14.5,
    inertial_max_points: int = _DEFAULT_ANIMATION_POINTS,
    rotating_max_points: int = _DEFAULT_MAX_POINTS,
) -> list[Path]:
    """Generate all orbit visualisation plots and save as HTML.

    :param df: Trajectory DataFrame with rotating-frame columns.
    :param output_dir: Directory for HTML output files.
    :param inclination_deg: For the theoretical z overlay.
    :param inertial_max_points: Time resolution for the inertial 3D animation.
    :param rotating_max_points: Resolution for the rotating-frame 3D plot.
    :return: List of saved file paths.
    """
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    paths: list[Path] = []

    rotating_path = output_dir / "rotating_3d.html"
    plot_rotating_3d(df, max_points=rotating_max_points).write_html(
        str(rotating_path), include_plotlyjs="cdn",
    )
    paths.append(rotating_path)

    inertial_path = output_dir / "inertial_3d.html"
    paths.append(write_inertial_3d_html(df, inertial_path, max_points=inertial_max_points))

    z_path = output_dir / "z_vs_time.html"
    plot_z_vs_time(df, inclination_deg).write_html(str(z_path), include_plotlyjs="cdn")
    paths.append(z_path)

    return paths
