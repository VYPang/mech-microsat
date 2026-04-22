"""Plotly visualisations for the SRP response surface."""

from __future__ import annotations

from pathlib import Path

import numpy as np
import plotly.graph_objects as go
import polars as pl

from .surrogate import ResponseSurface


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
    a = samples["area_m2"].to_numpy()
    c = samples["cr"].to_numpy()
    m = samples["mass_kg"].to_numpy()
    y = samples["dv_per_year_mps"].to_numpy()
    beta = c * a / m

    beta_grid = np.linspace(beta.min(), beta.max(), 200)
    y_hat = surrogate.predict_array(
        np.full_like(beta_grid, 1.0),
        beta_grid,
        np.full_like(beta_grid, 1.0),
    )

    hover = [
        f"A={ai:.3f} m², cR={ci:.2f}, m={mi:.1f} kg<br>β={bi:.4e}<br>ΔV/yr={yi:.3f} m/s"
        for ai, ci, mi, bi, yi in zip(a, c, m, beta, y)
    ]

    fig = go.Figure()
    fig.add_trace(
        go.Scatter(
            x=beta,
            y=y,
            mode="markers",
            name="Basilisk samples",
            marker=dict(size=6, color=m, colorscale="Viridis", showscale=True,
                        colorbar=dict(title="mass [kg]")),
            text=hover,
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
