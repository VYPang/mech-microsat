"""Plotly visualisations for the SRP response surface."""

from __future__ import annotations

from pathlib import Path

import numpy as np
import plotly.graph_objects as go
import polars as pl

from .surrogate import ResponseSurface


def _response_arrays(samples: pl.DataFrame) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    """Extract the sweep response arrays and the collapsed ballistic coefficient."""
    a = samples["area_m2"].to_numpy()
    c = samples["cr"].to_numpy()
    m = samples["mass_kg"].to_numpy()
    y = samples["dv_per_year_mps"].to_numpy()
    beta = c * a / m
    return a, c, m, y, beta


def plot_response_surface(
    samples: pl.DataFrame,
    surrogate: ResponseSurface,
    output_path: Path,
) -> Path:
    """Plot ΔV/yr vs. ballistic coefficient beta with sample scatter and fit curve.

    Because the surrogate is a univariate function of ``beta = cR·A/m``, this
    single chart fully describes the response over the whole 3-D grid: every
    (A, cR, m) point in the sweep maps to one point on this curve.
    """
    a, c, m, y, beta = _response_arrays(samples)
    order = np.argsort(beta)

    beta_grid = np.linspace(beta.min(), beta.max(), 200)
    y_hat = surrogate.predict_array(
        np.full_like(beta_grid, 1.0),
        beta_grid,
        np.full_like(beta_grid, 1.0),
    )

    hover = np.array([
        f"A={ai:.3f} m², cR={ci:.2f}, m={mi:.1f} kg<br>β={bi:.4e}<br>ΔV/yr={yi:.3f} m/s"
        for ai, ci, mi, bi, yi in zip(a, c, m, beta, y)
    ])

    fig = go.Figure()
    fig.add_trace(
        go.Scattergl(
            x=beta[order],
            y=y[order],
            mode="markers",
            name="Basilisk samples",
            marker=dict(size=6, color=m[order], colorscale="Viridis", showscale=True,
                        colorbar=dict(title="mass [kg]")),
            text=hover[order],
            hoverinfo="text",
        )
    )
    fig.add_trace(
        go.Scatter(
            x=beta_grid,
            y=y_hat,
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


def plot_response_surface_png(
    samples: pl.DataFrame,
    surrogate: ResponseSurface,
    output_path: Path,
) -> Path:
    """Two-panel academic PNG figure for the fitted SRP response surface."""
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

    _, _, _, dv, beta = _response_arrays(samples)
    order = np.argsort(beta)
    beta = beta[order]
    dv = dv[order]

    beta_curve = np.linspace(beta.min(), beta.max(), 400)
    dv_curve = surrogate.predict_array(
        np.full_like(beta_curve, 1.0),
        beta_curve,
        np.full_like(beta_curve, 1.0),
    )

    dv_pred = surrogate.predict_array(
        np.full_like(beta, 1.0),
        beta,
        np.full_like(beta, 1.0),
    )
    safe_pred = np.where(np.abs(dv_pred) < 1e-12, 1e-12, dv_pred)
    rel_residual_pct = 100.0 * (dv - dv_pred) / safe_pred

    fig, (ax_top, ax_bot) = plt.subplots(
        2, 1, figsize=(7.5, 6.5), sharex=True,
        gridspec_kw={"height_ratios": [3, 1.4], "hspace": 0.08},
    )

    ax_top.plot(
        beta_curve, dv_curve, color="black", lw=1.2, ls="--",
        label=f"Surrogate (deg {surrogate.degree}, $R^2={surrogate.r_squared:.4f}$)",
        zorder=1,
    )
    ax_top.scatter(
        beta, dv,
        marker="o", color="#1f77b4",
        edgecolor="black", linewidths=0.25, s=24,
        alpha=0.65, label=f"Basilisk samples (n={len(beta)})", zorder=3,
    )
    ax_top.set_ylabel(r"$\Delta V$ per year  [m/s/yr]")
    ax_top.set_title(
        r"SRP sweep fit for the cannonball-SRP surrogate "
        r"($\beta = c_R\,A/m$)"
    )
    ax_top.legend(loc="upper left", framealpha=0.95)

    ax_bot.axhline(0.0, color="black", lw=0.8)
    ax_bot.scatter(
        beta, rel_residual_pct,
        marker="o", color="#1f77b4",
        edgecolor="black", linewidths=0.25, s=20,
        alpha=0.65,
    )
    ax_bot.set_xlabel(r"$\beta = c_R\,A/m$  [m$^2$/kg]")
    ax_bot.set_ylabel(r"$(\Delta V - \widehat{\Delta V}) / \widehat{\Delta V}$  [%]")

    rms = float(np.sqrt(np.mean(rel_residual_pct ** 2)))
    max_abs = float(np.max(np.abs(rel_residual_pct)))
    ax_bot.text(
        0.99, 0.05,
        f"RMS deviation = {rms:.3f}%\nmax |dev| = {max_abs:.3f}%",
        transform=ax_bot.transAxes, ha="right", va="bottom",
        fontsize=9, family="serif",
        bbox=dict(facecolor="white", edgecolor="0.7", boxstyle="round,pad=0.3"),
    )

    fig.align_ylabels([ax_top, ax_bot])
    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_path, bbox_inches="tight")
    plt.close(fig)
    return output_path
