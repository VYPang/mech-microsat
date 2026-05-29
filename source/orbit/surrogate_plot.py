"""Plotting helpers for the SRP surrogate response models."""

from __future__ import annotations

from pathlib import Path

import numpy as np
import plotly.graph_objects as go
import polars as pl

from .surrogate import ResponseSurface


def _response_arrays(
    samples: pl.DataFrame,
) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    """Extract sweep arrays plus the collapsed ballistic coefficient."""
    area = samples["area_m2"].to_numpy()
    cr = samples["cr"].to_numpy()
    mass = samples["mass_kg"].to_numpy()
    dv = samples["dv_per_year_mps"].to_numpy()
    beta = cr * area / mass
    inclination = (
        samples["inclination_deg"].to_numpy()
        if "inclination_deg" in samples.columns
        else np.zeros(len(samples), dtype=float)
    )
    return area, cr, mass, dv, beta, inclination


def _plot_response_curve(
    samples: pl.DataFrame,
    surrogate: ResponseSurface,
    output_path: Path,
) -> Path:
    """Legacy 2-D response curve for a single-inclination surrogate."""
    area, cr, mass, dv, beta, _ = _response_arrays(samples)
    order = np.argsort(beta)

    beta_grid = np.linspace(beta.min(), beta.max(), 200)
    dv_curve = surrogate.predict_beta_array(beta_grid)

    hover = np.array([
        f"A={ai:.3f} m², cR={ci:.2f}, m={mi:.1f} kg<br>β={bi:.4e}<br>ΔV/yr={yi:.3f} m/s"
        for ai, ci, mi, bi, yi in zip(area, cr, mass, beta, dv)
    ])

    fig = go.Figure()
    fig.add_trace(
        go.Scattergl(
            x=beta[order],
            y=dv[order],
            mode="markers",
            name="Basilisk samples",
            marker=dict(
                size=6,
                color=mass[order],
                colorscale="Viridis",
                showscale=True,
                colorbar=dict(title="mass [kg]"),
            ),
            text=hover[order],
            hoverinfo="text",
        )
    )
    fig.add_trace(
        go.Scatter(
            x=beta_grid,
            y=dv_curve,
            mode="lines",
            name=f"Polynomial fit (deg {surrogate.degree}, R²={surrogate.r_squared:.4f})",
            line=dict(color="crimson", width=2),
        )
    )
    fig.update_layout(
        title="SRP-induced ΔV demand vs. ballistic coefficient β = c_R·A/m",
        xaxis_title="β = c_R · A / m   [m²/kg]",
        yaxis_title="ΔV per year   [m/s/yr]",
        template="plotly_dark",
        legend=dict(x=0.02, y=0.98),
    )

    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    fig.write_html(output_path, include_plotlyjs="cdn")
    return output_path


def _plot_response_surface_3d(
    samples: pl.DataFrame,
    surrogate: ResponseSurface,
    output_path: Path,
) -> Path:
    """3-D response surface in ballistic coefficient and inclination."""
    area, cr, mass, dv, beta, inclination = _response_arrays(samples)
    beta_grid = np.linspace(surrogate.bounds.beta[0], surrogate.bounds.beta[1], 120)
    inclination_grid = np.linspace(
        surrogate.inclination_nodes_deg[0],
        surrogate.inclination_nodes_deg[-1],
        80,
    )
    beta_mesh, inclination_mesh = np.meshgrid(beta_grid, inclination_grid)
    dv_surface = surrogate.predict_beta_array(beta_mesh, inclination_deg=inclination_mesh)

    hover = np.array([
        f"inc={incl:.2f}°<br>A={ai:.3f} m², cR={ci:.2f}, m={mi:.1f} kg"
        f"<br>β={bi:.4e}<br>ΔV/yr={yi:.4f} m/s"
        for ai, ci, mi, bi, yi, incl in zip(area, cr, mass, beta, dv, inclination)
    ])

    fig = go.Figure()
    fig.add_trace(
        go.Surface(
            x=beta_mesh,
            y=inclination_mesh,
            z=dv_surface,
            colorscale="Viridis",
            colorbar=dict(title="ΔV/yr [m/s/yr]"),
            name="Interpolated surface",
            opacity=0.9,
        )
    )
    fig.add_trace(
        go.Scatter3d(
            x=beta,
            y=inclination,
            z=dv,
            mode="markers",
            name="Basilisk samples",
            marker=dict(
                size=3.5,
                color=dv,
                colorscale="Viridis",
                showscale=False,
                line=dict(color="black", width=0.5),
            ),
            text=hover,
            hoverinfo="text",
        )
    )
    fig.update_layout(
        title="SRP surrogate surface in ballistic coefficient and inclination",
        template="plotly_white",
        scene=dict(
            xaxis_title="β = c_R · A / m   [m²/kg]",
            yaxis_title="inclination [deg]",
            zaxis_title="ΔV per year   [m/s/yr]",
        ),
        legend=dict(x=0.02, y=0.98),
    )

    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    fig.write_html(output_path, include_plotlyjs="cdn")
    return output_path


def plot_response_surface(
    samples: pl.DataFrame,
    surrogate: ResponseSurface,
    output_path: Path,
) -> Path:
    """Render either the legacy 2-D curve or the new 3-D surface."""
    if surrogate.has_inclination_axis and len(surrogate.inclination_nodes_deg) > 1:
        return _plot_response_surface_3d(samples, surrogate, output_path)
    return _plot_response_curve(samples, surrogate, output_path)


def plot_response_surface_png(
    samples: pl.DataFrame,
    surrogate: ResponseSurface,
    output_path: Path,
) -> Path:
    """Static figure for the fitted SRP surrogate."""
    import matplotlib.pyplot as plt

    plt.rcParams.update(
        {
            "font.family": "serif",
            "font.size": 11,
            "axes.labelsize": 12,
            "axes.titlesize": 13,
            "legend.fontsize": 10,
            "figure.dpi": 150,
            "savefig.dpi": 300,
            "axes.grid": True,
            "grid.alpha": 0.3,
        }
    )

    _, _, _, dv, beta, inclination = _response_arrays(samples)

    if surrogate.has_inclination_axis and len(surrogate.inclination_nodes_deg) > 1:
        beta_grid = np.linspace(surrogate.bounds.beta[0], surrogate.bounds.beta[1], 220)
        inclination_grid = np.linspace(
            surrogate.inclination_nodes_deg[0],
            surrogate.inclination_nodes_deg[-1],
            160,
        )
        beta_mesh, inclination_mesh = np.meshgrid(beta_grid, inclination_grid)
        dv_surface = surrogate.predict_beta_array(beta_mesh, inclination_deg=inclination_mesh)

        fig, ax = plt.subplots(figsize=(7.8, 5.4))
        image = ax.imshow(
            dv_surface,
            origin="lower",
            aspect="auto",
            extent=[beta_grid.min(), beta_grid.max(), inclination_grid.min(), inclination_grid.max()],
            cmap="viridis",
        )
        ax.scatter(
            beta,
            inclination,
            s=16,
            facecolors="none",
            edgecolors="white",
            linewidths=0.45,
            alpha=0.85,
        )
        ax.set_xlabel(r"$\beta = c_R\,A/m$  [m$^2$/kg]")
        ax.set_ylabel("inclination [deg]")
        ax.set_title("SRP surrogate surface in ballistic coefficient and inclination")
        colorbar = fig.colorbar(image, ax=ax)
        colorbar.set_label(r"$\Delta V$ per year  [m/s/yr]")
        ax.text(
            0.99,
            0.02,
            f"deg {surrogate.degree} fit\nR² = {surrogate.r_squared:.4f}",
            transform=ax.transAxes,
            ha="right",
            va="bottom",
            fontsize=9,
            family="serif",
            bbox=dict(facecolor="white", edgecolor="0.7", boxstyle="round,pad=0.3"),
        )

        output_path = Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        fig.savefig(output_path, bbox_inches="tight")
        plt.close(fig)
        return output_path

    order = np.argsort(beta)
    beta_sorted = beta[order]
    dv_sorted = dv[order]

    beta_curve = np.linspace(beta_sorted.min(), beta_sorted.max(), 400)
    dv_curve = surrogate.predict_beta_array(beta_curve)
    dv_pred = surrogate.predict_beta_array(beta_sorted)
    safe_pred = np.where(np.abs(dv_pred) < 1e-12, 1e-12, dv_pred)
    rel_residual_pct = 100.0 * (dv_sorted - dv_pred) / safe_pred

    fig, (ax_top, ax_bot) = plt.subplots(
        2,
        1,
        figsize=(7.5, 6.5),
        sharex=True,
        gridspec_kw={"height_ratios": [3, 1.4], "hspace": 0.08},
    )

    ax_top.plot(
        beta_curve,
        dv_curve,
        color="black",
        lw=1.2,
        ls="--",
        label=f"Surrogate (deg {surrogate.degree}, $R^2={surrogate.r_squared:.4f}$)",
        zorder=1,
    )
    ax_top.scatter(
        beta_sorted,
        dv_sorted,
        marker="o",
        color="#1f77b4",
        edgecolor="black",
        linewidths=0.25,
        s=24,
        alpha=0.65,
        label=f"Basilisk samples (n={len(beta_sorted)})",
        zorder=3,
    )
    ax_top.set_ylabel(r"$\Delta V$ per year  [m/s/yr]")
    ax_top.set_title(
        r"SRP sweep fit for the cannonball-SRP surrogate "
        r"($\beta = c_R\,A/m$)"
    )
    ax_top.legend(loc="upper left", framealpha=0.95)

    ax_bot.axhline(0.0, color="black", lw=0.8)
    ax_bot.scatter(
        beta_sorted,
        rel_residual_pct,
        marker="o",
        color="#1f77b4",
        edgecolor="black",
        linewidths=0.25,
        s=20,
        alpha=0.65,
    )
    ax_bot.set_xlabel(r"$\beta = c_R\,A/m$  [m$^2$/kg]")
    ax_bot.set_ylabel(r"$(\Delta V - \widehat{\Delta V}) / \widehat{\Delta V}$  [%]")

    rms = float(np.sqrt(np.mean(rel_residual_pct**2)))
    max_abs = float(np.max(np.abs(rel_residual_pct)))
    ax_bot.text(
        0.99,
        0.05,
        f"RMS deviation = {rms:.3f}%\nmax |dev| = {max_abs:.3f}%",
        transform=ax_bot.transAxes,
        ha="right",
        va="bottom",
        fontsize=9,
        family="serif",
        bbox=dict(facecolor="white", edgecolor="0.7", boxstyle="round,pad=0.3"),
    )

    fig.align_ylabels([ax_top, ax_bot])
    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_path, bbox_inches="tight")
    plt.close(fig)
    return output_path
