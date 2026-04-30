"""Polynomial surrogate for the SRP-induced ΔV demand.

For a fixed inclination, the cannonball SRP acceleration scales exactly as
``c_R * A / m``, so the response can be fit as a low-order polynomial in the
ballistic coefficient ``beta = c_R * A / m``.

For the inclination-surface workflow, the code fits one beta-polynomial per
inclination and linearly interpolates those coefficients across inclination.
This preserves the current 1-D fit at each inclination while exposing a smooth
surface ``ΔV(beta, inclination_deg)`` to plotting and later solver use.
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
    inclination_deg: tuple[float, float] | None = None


@dataclass(frozen=True)
class ResponseSurface:
    """SRP surrogate predicting ΔV per year [m/s/yr].

    The response is always polynomial in ``beta = c_R * A / m``. For a single
    inclination this is the legacy univariate fit. For multiple inclinations,
    ``coefficients_by_inclination`` stores one polynomial per inclination node,
    and predictions linearly interpolate those coefficients across inclination.
    """

    coefficients: list[float]
    degree: int
    n_samples: int
    r_squared: float
    bounds: SurrogateBounds
    metadata: dict = field(default_factory=dict)
    inclination_nodes_deg: list[float] = field(default_factory=list)
    coefficients_by_inclination: list[list[float]] = field(default_factory=list)
    r_squared_by_inclination: list[float] = field(default_factory=list)
    samples_by_inclination: list[int] = field(default_factory=list)

    @property
    def has_inclination_axis(self) -> bool:
        return bool(self.coefficients_by_inclination)

    def _coefficient_matrix(self) -> np.ndarray:
        if not self.coefficients_by_inclination:
            return np.asarray([self.coefficients], dtype=float)
        return np.asarray(self.coefficients_by_inclination, dtype=float)

    def _resolve_coefficients(self, inclination_deg: float | None = None) -> np.ndarray:
        if not self.has_inclination_axis:
            return np.asarray(self.coefficients, dtype=float)

        nodes = np.asarray(self.inclination_nodes_deg, dtype=float)
        matrix = self._coefficient_matrix()
        if len(nodes) == 1:
            if inclination_deg is not None and not np.isclose(float(inclination_deg), nodes[0]):
                raise ValueError(
                    f"Surrogate was trained only at inclination {nodes[0]:.6g} deg; "
                    f"got {float(inclination_deg):.6g} deg."
                )
            return matrix[0]

        if inclination_deg is None:
            raise ValueError(
                "This surrogate spans multiple inclinations; inclination_deg must be provided "
                "when evaluating it."
            )

        inclination = float(inclination_deg)
        lower, upper = float(nodes.min()), float(nodes.max())
        if inclination < lower or inclination > upper:
            raise ValueError(
                f"inclination_deg={inclination:.6g} is outside the surrogate bounds "
                f"[{lower:.6g}, {upper:.6g}] deg."
            )

        return np.asarray(
            [np.interp(inclination, nodes, matrix[:, idx]) for idx in range(matrix.shape[1])],
            dtype=float,
        )

    def predict_beta(self, beta: float, inclination_deg: float | None = None) -> float:
        """ΔV per year [m/s/yr] for one ballistic coefficient sample."""
        coeffs = self._resolve_coefficients(inclination_deg)
        return float(np.polynomial.polynomial.polyval(float(beta), coeffs))

    def predict_beta_array(
        self,
        beta: np.ndarray,
        inclination_deg: float | np.ndarray | None = None,
    ) -> np.ndarray:
        """Vectorised prediction in ballistic-coefficient space."""
        beta_arr = np.asarray(beta, dtype=float)

        if not self.has_inclination_axis:
            return np.polynomial.polynomial.polyval(beta_arr, self.coefficients)

        nodes = np.asarray(self.inclination_nodes_deg, dtype=float)
        matrix = self._coefficient_matrix()
        if inclination_deg is None:
            if len(nodes) != 1:
                raise ValueError(
                    "This surrogate spans multiple inclinations; inclination_deg must be provided "
                    "when evaluating it."
                )
            return np.polynomial.polynomial.polyval(beta_arr, matrix[0])

        inclination_arr = np.asarray(inclination_deg, dtype=float)
        beta_broadcast, inclination_broadcast = np.broadcast_arrays(beta_arr, inclination_arr)
        lower, upper = float(nodes.min()), float(nodes.max())
        if np.any((inclination_broadcast < lower) | (inclination_broadcast > upper)):
            raise ValueError(
                f"inclination_deg values must remain within the surrogate bounds "
                f"[{lower:.6g}, {upper:.6g}] deg."
            )

        flat_beta = beta_broadcast.ravel()
        flat_inclination = inclination_broadcast.ravel()
        flat_result = np.zeros_like(flat_beta, dtype=float)
        for power in range(matrix.shape[1]):
            coeff_interp = np.interp(flat_inclination, nodes, matrix[:, power])
            flat_result += coeff_interp * flat_beta**power
        return flat_result.reshape(beta_broadcast.shape)

    # ------------------------------------------------------------------
    # Prediction
    # ------------------------------------------------------------------
    def predict(
        self,
        area_m2: float,
        cr: float,
        mass_kg: float,
        inclination_deg: float | None = None,
    ) -> float:
        """ΔV per year [m/s/yr] for a single design point."""
        beta = cr * area_m2 / mass_kg
        return self.predict_beta(beta, inclination_deg=inclination_deg)

    def predict_array(
        self,
        area_m2: np.ndarray,
        cr: np.ndarray,
        mass_kg: np.ndarray,
        inclination_deg: float | np.ndarray | None = None,
    ) -> np.ndarray:
        """Vectorised prediction."""
        beta = np.asarray(cr) * np.asarray(area_m2) / np.asarray(mass_kg)
        return self.predict_beta_array(beta, inclination_deg=inclination_deg)

    def gradient(
        self,
        area_m2: float,
        cr: float,
        mass_kg: float,
        inclination_deg: float | None = None,
    ) -> dict[str, float]:
        """Closed-form ∂ΔV/∂x for x ∈ {area, cr, mass}.

        ΔV(beta) where beta = cR·A/m → chain rule gives the per-variable gradients.
        """
        beta = cr * area_m2 / mass_kg
        coeffs = self._resolve_coefficients(inclination_deg)
        # dΔV/dbeta from polynomial derivative.
        deriv = np.polynomial.polynomial.polyder(coeffs)
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
            "inclination_nodes_deg": list(self.inclination_nodes_deg),
            "coefficients_by_inclination": [list(row) for row in self.coefficients_by_inclination],
            "r_squared_by_inclination": list(self.r_squared_by_inclination),
            "samples_by_inclination": list(self.samples_by_inclination),
        }
        path.write_text(json.dumps(payload, indent=2))

    @classmethod
    def from_json(cls, path: Path) -> ResponseSurface:
        payload = json.loads(Path(path).read_text())
        raw_bounds = payload["bounds"]
        bounds = SurrogateBounds(
            area_m2=tuple(raw_bounds["area_m2"]),
            cr=tuple(raw_bounds["cr"]),
            mass_kg=tuple(raw_bounds["mass_kg"]),
            beta=tuple(raw_bounds["beta"]),
            inclination_deg=(
                None
                if raw_bounds.get("inclination_deg") is None
                else tuple(raw_bounds["inclination_deg"])
            ),
        )
        return cls(
            coefficients=list(payload["coefficients"]),
            degree=int(payload["degree"]),
            n_samples=int(payload["n_samples"]),
            r_squared=float(payload["r_squared"]),
            bounds=bounds,
            metadata=payload.get("metadata", {}),
            inclination_nodes_deg=[float(x) for x in payload.get("inclination_nodes_deg", [])],
            coefficients_by_inclination=[
                [float(value) for value in row]
                for row in payload.get("coefficients_by_inclination", [])
            ],
            r_squared_by_inclination=[
                float(value) for value in payload.get("r_squared_by_inclination", [])
            ],
            samples_by_inclination=[
                int(value) for value in payload.get("samples_by_inclination", [])
            ],
        )


# ---------------------------------------------------------------------------
# Fitting
# ---------------------------------------------------------------------------


def _fit_beta_curve(samples: pl.DataFrame, degree: int) -> tuple[list[float], float, np.ndarray, np.ndarray]:
    """Fit one polynomial curve in beta for one inclination slice."""
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

    return [float(x) for x in coeffs], r2, beta, y


def fit_response_surface(samples: pl.DataFrame, degree: int = 2) -> ResponseSurface:
    """Least-squares fit of ΔV/yr against beta and, optionally, inclination.

    :param samples: DataFrame with columns area_m2, cr, mass_kg, dv_per_year_mps,
        and optionally inclination_deg.
    :param degree: Polynomial degree in beta.
    :return: Fitted :class:`ResponseSurface`.
    """
    if samples.is_empty():
        raise ValueError("Cannot fit a surrogate with zero samples.")

    inclination_series = (
        samples["inclination_deg"].to_numpy()
        if "inclination_deg" in samples.columns
        else np.zeros(len(samples), dtype=float)
    )
    unique_inclinations = sorted(float(value) for value in np.unique(inclination_series))

    coefficients_by_inclination: list[list[float]] = []
    r_squared_by_inclination: list[float] = []
    samples_by_inclination: list[int] = []
    for inclination in unique_inclinations:
        slice_df = samples.filter(pl.col("inclination_deg") == inclination)
        coeffs, r2, _, _ = _fit_beta_curve(slice_df, degree)
        coefficients_by_inclination.append(coeffs)
        r_squared_by_inclination.append(r2)
        samples_by_inclination.append(len(slice_df))

    a = samples["area_m2"].to_numpy()
    c = samples["cr"].to_numpy()
    m = samples["mass_kg"].to_numpy()
    y = samples["dv_per_year_mps"].to_numpy()
    beta = c * a / m

    surface = ResponseSurface(
        coefficients=list(coefficients_by_inclination[0]),
        degree=degree,
        n_samples=len(samples),
        r_squared=0.0,
        bounds=SurrogateBounds(
            area_m2=(float(a.min()), float(a.max())),
            cr=(float(c.min()), float(c.max())),
            mass_kg=(float(m.min()), float(m.max())),
            beta=(float(beta.min()), float(beta.max())),
            inclination_deg=(float(min(unique_inclinations)), float(max(unique_inclinations))),
        ),
        metadata={},
        inclination_nodes_deg=list(unique_inclinations),
        coefficients_by_inclination=coefficients_by_inclination,
        r_squared_by_inclination=r_squared_by_inclination,
        samples_by_inclination=samples_by_inclination,
    )

    y_hat = surface.predict_array(
        a,
        c,
        m,
        inclination_deg=inclination_series,
    )

    ss_res = float(np.sum((y - y_hat) ** 2))
    ss_tot = float(np.sum((y - y.mean()) ** 2))
    r2 = 1.0 - ss_res / ss_tot if ss_tot > 0 else 0.0

    return ResponseSurface(
        coefficients=list(coefficients_by_inclination[0]),
        degree=degree,
        n_samples=len(samples),
        r_squared=r2,
        bounds=surface.bounds,
        metadata={
            "feature": "beta = cr * area_m2 / mass_kg",
            "inclination_feature": "inclination_deg",
            "target": "dv_per_year_mps",
            "fit": (
                "per-inclination beta polynomial with linear interpolation of coefficients "
                "over inclination_deg"
                if len(unique_inclinations) > 1
                else "numpy.polynomial.polynomial.polyfit (ordinary least squares)"
            ),
        },
        inclination_nodes_deg=list(unique_inclinations),
        coefficients_by_inclination=coefficients_by_inclination,
        r_squared_by_inclination=r_squared_by_inclination,
        samples_by_inclination=samples_by_inclination,
    )
