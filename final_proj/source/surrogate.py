"""Polynomial response-surface surrogate for the SRP-induced ΔV demand.

The cannonball SRP acceleration scales exactly as ``c_R * A / m``, so the
surrogate is parameterised on the **ballistic coefficient**
``beta = c_R * A / m`` rather than the three raw variables.  This keeps
the fit 1-D, gives an exact closed-form gradient, and lets us extrapolate
to mass values outside the sweep grid without rerunning Basilisk.

Empirically the integrated drift is sub-linear in ``beta`` because the
SRP direction rotates with the satellite around the Sun, partially
cancelling out.  A quadratic in ``beta`` captures this comfortably.
"""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass, field
from pathlib import Path

import numpy as np
import polars as pl


@dataclass(frozen=True)
class SurrogateBounds:
    """Range of design variables present in the training data."""

    area_m2: tuple[float, float]
    cr: tuple[float, float]
    mass_kg: tuple[float, float]
    beta: tuple[float, float]


@dataclass(frozen=True)
class ResponseSurface:
    """Univariate polynomial in beta = c_R * A / m, predicting ΔV per year [m/s/yr]."""

    coefficients: list[float]                # ascending order: c0 + c1*beta + c2*beta^2 ...
    degree: int
    n_samples: int
    r_squared: float
    bounds: SurrogateBounds
    metadata: dict = field(default_factory=dict)

    # ------------------------------------------------------------------
    # Prediction
    # ------------------------------------------------------------------
    def predict(self, area_m2: float, cr: float, mass_kg: float) -> float:
        """ΔV per year [m/s/yr] for a single design point."""
        beta = cr * area_m2 / mass_kg
        return float(np.polynomial.polynomial.polyval(beta, self.coefficients))

    def predict_array(
        self,
        area_m2: np.ndarray,
        cr: np.ndarray,
        mass_kg: np.ndarray,
    ) -> np.ndarray:
        """Vectorised prediction."""
        beta = np.asarray(cr) * np.asarray(area_m2) / np.asarray(mass_kg)
        return np.polynomial.polynomial.polyval(beta, self.coefficients)

    def gradient(self, area_m2: float, cr: float, mass_kg: float) -> dict[str, float]:
        """Closed-form ∂ΔV/∂x for x ∈ {area, cr, mass}.

        ΔV(beta) where beta = cR·A/m → chain rule gives the per-variable gradients.
        """
        beta = cr * area_m2 / mass_kg
        # dΔV/dbeta from polynomial derivative.
        deriv = np.polynomial.polynomial.polyder(self.coefficients)
        d_dv_d_beta = float(np.polynomial.polynomial.polyval(beta, deriv))
        return {
            "d_dv_d_area": d_dv_d_beta * cr / mass_kg,
            "d_dv_d_cr":   d_dv_d_beta * area_m2 / mass_kg,
            "d_dv_d_mass": -d_dv_d_beta * cr * area_m2 / (mass_kg ** 2),
        }

    # ------------------------------------------------------------------
    # Persistence
    # ------------------------------------------------------------------
    def to_json(self, path: Path) -> None:
        path = Path(path)
        path.parent.mkdir(parents=True, exist_ok=True)
        payload = {
            "coefficients": list(self.coefficients),
            "degree": self.degree,
            "n_samples": self.n_samples,
            "r_squared": self.r_squared,
            "bounds": asdict(self.bounds),
            "metadata": self.metadata,
        }
        path.write_text(json.dumps(payload, indent=2))

    @classmethod
    def from_json(cls, path: Path) -> ResponseSurface:
        payload = json.loads(Path(path).read_text())
        bounds = SurrogateBounds(
            area_m2=tuple(payload["bounds"]["area_m2"]),
            cr=tuple(payload["bounds"]["cr"]),
            mass_kg=tuple(payload["bounds"]["mass_kg"]),
            beta=tuple(payload["bounds"]["beta"]),
        )
        return cls(
            coefficients=list(payload["coefficients"]),
            degree=int(payload["degree"]),
            n_samples=int(payload["n_samples"]),
            r_squared=float(payload["r_squared"]),
            bounds=bounds,
            metadata=payload.get("metadata", {}),
        )


# ---------------------------------------------------------------------------
# Fitting
# ---------------------------------------------------------------------------


def fit_response_surface(samples: pl.DataFrame, degree: int = 2) -> ResponseSurface:
    """Least-squares fit of ΔV/yr against beta = c_R·A/m.

    :param samples: DataFrame with columns area_m2, cr, mass_kg, dv_per_year_mps.
    :param degree: Polynomial degree in beta.
    :return: Fitted :class:`ResponseSurface`.
    """
    if samples.is_empty():
        raise ValueError("Cannot fit a surrogate with zero samples.")

    a = samples["area_m2"].to_numpy()
    c = samples["cr"].to_numpy()
    m = samples["mass_kg"].to_numpy()
    y = samples["dv_per_year_mps"].to_numpy()

    beta = c * a / m

    # numpy.polynomial.polynomial.polyfit returns coefficients in ascending order.
    coeffs = np.polynomial.polynomial.polyfit(beta, y, deg=degree)
    y_hat = np.polynomial.polynomial.polyval(beta, coeffs)

    ss_res = float(np.sum((y - y_hat) ** 2))
    ss_tot = float(np.sum((y - y.mean()) ** 2))
    r2 = 1.0 - ss_res / ss_tot if ss_tot > 0 else 0.0

    bounds = SurrogateBounds(
        area_m2=(float(a.min()), float(a.max())),
        cr=(float(c.min()), float(c.max())),
        mass_kg=(float(m.min()), float(m.max())),
        beta=(float(beta.min()), float(beta.max())),
    )

    return ResponseSurface(
        coefficients=[float(x) for x in coeffs],
        degree=degree,
        n_samples=len(samples),
        r_squared=r2,
        bounds=bounds,
        metadata={
            "feature": "beta = cr * area_m2 / mass_kg",
            "target": "dv_per_year_mps",
            "fit": "numpy.polynomial.polynomial.polyfit (ordinary least squares)",
        },
    )
