# Sol-Sentinel — CR3BP Baseline Simulation and SRP Sweep

User guide for running the Sun-Earth L4 baseline orbit simulation, visualisation pipeline, and SRP response-surface sweep.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Source Layout](#source-layout)
- [Command Reference](#command-reference)
  - [Full Run (Simulate + Plot)](#full-run-simulate--plot)
  - [Visualise Only](#visualise-only)
  - [Orbit Info](#orbit-info)
  - [SRP Sweep + Surrogate](#srp-sweep--surrogate)
  - [Surrogate Validation Study](#surrogate-validation-study)
- [Config File Format](#config-file-format)
  - [Simulation Section](#simulation-section)
  - [Visualisation Section](#visualisation-section)
  - [Sweep Config Format](#sweep-config-format)
  - [Validation Section](#validation-section)
- [Shipped Configs](#shipped-configs)
- [Output Structure](#output-structure)
- [Output Descriptions](#output-descriptions)
- [Examples](#examples)

---

## Prerequisites

All commands are run from the **workspace root** (`MECH Microsat/`), not from inside `final_proj/`.

```bash
# Create the virtual environment and install all dependencies (one-time)
uv sync
```

The first run will automatically download SPICE kernels to `~/.cache/bsk_support_data/` if they are not already present.

---

## Quick Start

```bash
# Run a 50-year simulation at 7.25° inclination and generate all plots
uv run python final_proj/scripts/run_baseline.py --config final_proj/config/low_inc.json

# Run the low-inclination SRP sweep and fit the surrogate model
uv run python final_proj/scripts/run_sweep.py --config final_proj/config/sweep_low_inc.json
```

Open the HTML files in `final_proj/output/low_inc/plots/` in a browser to view the results.

---

## Source Layout

- `final_proj/source/orbit/` contains all orbit, SRP sweep, validation, and surrogate code.
- `final_proj/source/optimization/` contains the preliminary fixed-point optimization scaffold that will absorb the subsystem equations from Comms, Power, Thermal, and Propulsion.
- See `final_proj/docs/optimization_framework.md` for the optimizer architecture and integration workflow.

---

## Command Reference

The entry point is always:

```bash
uv run python final_proj/scripts/run_baseline.py [OPTIONS]
```

### Full Run (Simulate + Plot)

Propagate the orbit with Basilisk, save trajectory to Parquet, transform to the rotating frame, and generate all HTML plots.

```bash
uv run python final_proj/scripts/run_baseline.py --config <path-to-config.json>
```

A Rich progress bar is displayed during the simulation showing elapsed time and ETA.

### Visualise Only

Skip the simulation and regenerate plots from a previously saved `.parquet` file. Useful for tweaking visualisation resolution without re-running the simulation.

```bash
uv run python final_proj/scripts/run_baseline.py --config <path-to-config.json> --viz-only
```

### Orbit Info

Print the L4 and Earth state vectors (position and velocity), the Earth→L4 separation distance, and the ΔV magnitude, then exit. No simulation is run. Useful for handing off initial conditions to a teammate designing the transfer orbit.

```bash
uv run python final_proj/scripts/run_baseline.py --config <path-to-config.json> --info
```

### SRP Sweep + Surrogate

Run a full-factorial sweep over solar-array area, reflectivity coefficient, and spacecraft mass on the low-inclination reference orbit. Each grid point runs a Basilisk propagation with cannonball SRP enabled, writes the raw samples to Parquet, fits a polynomial surrogate, and generates both an interactive HTML plot and a static report-ready PNG.

```bash
uv run python final_proj/scripts/run_sweep.py --config final_proj/config/sweep_low_inc.json
```

Useful flags:

```bash
# Refit the surrogate and regenerate the plot from an existing sample parquet
uv run python final_proj/scripts/run_sweep.py \
    --config final_proj/config/sweep_low_inc.json --fit-only

# Regenerate the plot only from an existing surrogate JSON + sample parquet
uv run python final_proj/scripts/run_sweep.py \
    --config final_proj/config/sweep_low_inc.json --plot-only
```

The sweep is append-safe. If you later widen the design-variable bounds or increase the grid resolution in the JSON config, re-running the command will only simulate the missing grid points and will preserve the existing Parquet samples.

### Surrogate Validation Study

The cannonball SRP response is expected to collapse exactly onto the ballistic coefficient `β = c_R · A / m`. The `--validate` flag generates a same-`β` study that proves this collapse and produces a static publication-style PNG figure for the report.

For each requested `β` target, the validator builds three families of design points (varying `A`, `c_R`, and `m` in turn while solving the third variable to keep `β` fixed), simulates each point with the full Basilisk SRP propagation, and overlays the resulting `ΔV/yr` against the fitted surrogate.

```bash
# Run the validation study (requires an existing surrogate JSON)
uv run python final_proj/scripts/run_sweep.py \
    --config final_proj/config/sweep_low_inc.json --validate

# Regenerate only the validation PNG from cached validation samples
uv run python final_proj/scripts/run_sweep.py \
    --config final_proj/config/sweep_low_inc.json --validate-plot-only
```

The validation samples Parquet is append-safe in the same way as the main sweep. The validation `duration_years` must match the duration used for the training sweep — `TotalAccumDV_CN_N` is duration-dependent (see the changelog), and a mismatch is rejected with a clear error before any propagation is launched.

---

## Config File Format

Each config is a JSON file with two sections: `simulation` and `visualization`.

```json
{
    "simulation": {
        "epoch_utc": "2026 MAY 01 00:00:00.0 (UTC)",
        "duration_years": 50.0,
        "timestep_s": 300.0,
        "inclination_deg": 7.25
    },
    "visualization": {
        "output_dir": "final_proj/output/low_inc",
        "inertial_3d_points": 2000,
        "rotating_3d_points": 50000
    }
}
```

### Simulation Section

| Parameter | Type | Description |
|-----------|------|-------------|
| `epoch_utc` | string | SPICE-compatible UTC epoch string for the simulation start. |
| `duration_years` | float | Propagation duration in Earth years. Supports values > 584 yr (automatically chunked). |
| `timestep_s` | float | Integration / recording timestep in seconds. Smaller = more accurate but larger parquet. |
| `inclination_deg` | float | Out-of-plane inclination relative to the ecliptic in degrees. Controls the z-oscillation amplitude (period is always ~1 year). |

### Visualisation Section

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `output_dir` | string | — | Directory for parquet data and HTML plots. |
| `inertial_3d_points` | int | 2000 | Number of time samples in the animated inertial-frame HTML. Lower = smaller file, coarser motion. |
| `rotating_3d_points` | int | 50000 | Number of points in the rotating-frame 3D scatter. Lower = smaller file, less detail. |

### Sweep Config Format

The SRP sweep uses a separate JSON config containing `simulation`, `grid`, `surrogate`, and `output` sections.

```json
{
    "simulation": {
        "epoch_utc": "2026 MAY 01 00:00:00.0 (UTC)",
        "inclination_deg": 7.25,
        "duration_years": 3.0,
        "timestep_s": 600.0
    },
    "grid": {
        "area_m2":  {"min": 0.02, "max": 0.30, "n": 5},
        "cr":       {"min": 1.0,  "max": 2.0,  "n": 5},
        "mass_kg":  {"min": 3.2,  "max": 24.0, "n": 5}
    },
    "surrogate": {
        "degree": 2
    },
    "output": {
        "samples_parquet": "final_proj/output/low_inc/srp_samples.parquet",
        "surrogate_json":  "final_proj/output/low_inc/srp_surrogate.json",
        "plot_html":       "final_proj/output/low_inc/plots/srp_response_surface.html",
        "plot_png":        "final_proj/output/low_inc/plots/srp_response_surface.png"
    }
}
```

#### Sweep `simulation` section

| Parameter | Type | Description |
|-----------|------|-------------|
| `epoch_utc` | string | SPICE-compatible UTC epoch string for the sweep start. |
| `inclination_deg` | float | Reference-orbit inclination for the SRP sweep. For now use the low-inclination orbit. |
| `duration_years` | float | Propagation length for each grid point. Recommended: 2 to 5 years. |
| `timestep_s` | float | Integration timestep for each grid point. |

#### Sweep `grid` section

Each axis is defined by `min`, `max`, and `n`, and is sampled on a linear grid.

| Parameter | Type | Description |
|-----------|------|-------------|
| `area_m2` | object | Solar-array effective area bounds and point count. |
| `cr` | object | SRP reflectivity coefficient bounds and point count. |
| `mass_kg` | object | Spacecraft wet-mass bounds and point count. |

#### Sweep `surrogate` section

| Parameter | Type | Description |
|-----------|------|-------------|
| `degree` | int | Polynomial degree used for the surrogate fit. Default is 2. |

#### Sweep `output` section

| Parameter | Type | Description |
|-----------|------|-------------|
| `samples_parquet` | string | Append-safe Parquet file storing all simulated grid points. |
| `surrogate_json` | string | JSON file storing the fitted surrogate coefficients and bounds. |
| `plot_html` | string | Plotly HTML visualising the samples and fitted surrogate. |
| `plot_png` | string | Static publication-style PNG of the fitted surrogate with a residual sub-plot. |

### Validation Section

The optional `validation` section drives the same-`β` collapse study used by `--validate` and `--validate-plot-only`.

```json
"validation": {
    "beta_targets": [0.005, 0.02, 0.05, 0.10, 0.15],
    "n_per_family": 6,
    "samples_parquet": "final_proj/output/low_inc/srp_validation_samples.parquet",
    "plot_png":        "final_proj/output/low_inc/plots/srp_validation.png"
}
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `beta_targets` | list[float] | Target ballistic coefficients `β = c_R · A / m` (m²/kg) at which to evaluate the same-`β` slice. |
| `n_per_family` | int | Number of points used per family (`vary_A`, `vary_c_R`, `vary_m`) per `β` target. Triplets that fall outside the surrogate training bounds are silently dropped. |
| `samples_parquet` | string | Append-safe Parquet file storing the validation runs. |
| `plot_png` | string | Static publication-style PNG with the same-`β` overlay and a relative-residual sub-plot. |

---

## Shipped Configs

| File | Inclination | Duration | Description |
|------|-------------|----------|-------------|
| `config/low_inc.json` | 7.25° | 50 yr | Solar ecliptic inclination — minimal out-of-plane excursion. |
| `config/recommand_inc.json` | 14.5° | 50 yr | Recommended inclination from literature — larger z-amplitude for better solar observation geometry. |
| `config/sweep_low_inc.json` | 7.25° | 3 yr per grid point | Low-inclination SRP sweep over area, reflectivity, and mass. |

To create a new config, copy one of the above and edit the values.

---

## Output Structure

After a full run, the output directory contains:

```
final_proj/output/<config_name>/
├── cr3bp_baseline.parquet      # Full trajectory (t, x, y, z, vx, vy, vz in SI)
└── plots/
    ├── rotating_3d.html        # 3D rotating-frame view (Earth fixed on +x)
    ├── inertial_3d.html        # Animated inertial-frame view (Play/Pause + slider)
    └── z_vs_time.html          # Out-of-plane displacement vs time
```

After an SRP sweep, the low-inclination output directory also contains:

```text
final_proj/output/low_inc/
├── srp_samples.parquet              # Raw grid-point outputs: area, c_R, mass, ΔV_total, ΔV/yr
├── srp_surrogate.json               # Fitted polynomial surrogate coefficients and bounds
├── srp_validation_samples.parquet   # Same-β validation runs (added by --validate)
└── plots/
    ├── srp_response_surface.html    # Interactive Plotly fit + samples
    ├── srp_response_surface.png     # Static report figure: fit + residual
    └── srp_validation.png           # Static report figure: same-β collapse + residual
```

---

## Output Descriptions

| File | Description |
|------|-------------|
| **rotating_3d.html** | Static interactive Plotly 3D scatter in the Sun-centred synodic frame. Sun at origin, Earth pinned on +x axis, satellite trace coloured by time. Shows tadpole libration around L4. |
| **inertial_3d.html** | Lightweight browser animation (JS + Plotly restyle). Shows Earth and satellite both orbiting the Sun. Play/Pause button and time slider. Labelled head markers for Earth and Sat. |
| **z_vs_time.html** | Time series of the satellite's ecliptic-normal displacement with a dashed theoretical sinusoidal overlay. |
| **srp_response_surface.html** | Scatter of Basilisk SRP sweep samples with the fitted surrogate curve. The sweep is 3-D in `(A, c_R, m)`, but the cannonball SRP response collapses to the ballistic coefficient `β = c_R · A / m`, so the fitted response is shown against `β`. |
| **srp_response_surface.png** | Static publication-style figure (matplotlib, 300 dpi, serif). Top panel: all sweep samples overlaid with the fitted surrogate against `β`. Bottom panel: relative residual `(ΔV − Δ̂V)/Δ̂V [%]` with RMS and max-absolute deviation annotated. Intended for direct use in the report. |
| **srp_validation.png** | Static publication-style figure (matplotlib, 300 dpi, serif) generated by `--validate`. Top panel: surrogate curve overlaid with three families of same-`β` design points (vary `A`, vary `c_R`, vary `m`). Bottom panel: relative residual `(ΔV − Δ̂V)/Δ̂V [%]` with the RMS and max-absolute deviation annotated. Used in the report to justify the 1-D `β` surrogate. |

---

## Examples

```bash
# Run the recommended-inclination simulation
uv run python final_proj/scripts/run_baseline.py \
    --config final_proj/config/recommand_inc.json

# Re-plot with higher inertial animation resolution (edit the JSON first)
#   "inertial_3d_points": 4000
uv run python final_proj/scripts/run_baseline.py \
    --config final_proj/config/recommand_inc.json --viz-only

# Get state vectors for transfer orbit design
uv run python final_proj/scripts/run_baseline.py \
    --config final_proj/config/low_inc.json --info

# Run the default 10x10x10 low-inclination SRP sweep
uv run python final_proj/scripts/run_sweep.py \
    --config final_proj/config/sweep_low_inc.json

# Refit the surrogate after manually editing the sample parquet or config
uv run python final_proj/scripts/run_sweep.py \
    --config final_proj/config/sweep_low_inc.json --fit-only

# Generate the same-β validation study and report-ready PNG
uv run python final_proj/scripts/run_sweep.py \
    --config final_proj/config/sweep_low_inc.json --validate
```
