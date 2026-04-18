# Sol-Sentinel — CR3BP Baseline Simulation

User guide for running the Sun-Earth L4 orbit simulation and visualisation pipeline.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Command Reference](#command-reference)
  - [Full Run (Simulate + Plot)](#full-run-simulate--plot)
  - [Visualise Only](#visualise-only)
  - [Orbit Info](#orbit-info)
- [Config File Format](#config-file-format)
  - [Simulation Section](#simulation-section)
  - [Visualisation Section](#visualisation-section)
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
```

Open the HTML files in `final_proj/output/low_inc/plots/` in a browser to view the results.

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

---

## Shipped Configs

| File | Inclination | Duration | Description |
|------|-------------|----------|-------------|
| `config/low_inc.json` | 7.25° | 50 yr | Solar ecliptic inclination — minimal out-of-plane excursion. |
| `config/recommand_inc.json` | 14.5° | 50 yr | Recommended inclination from literature — larger z-amplitude for better solar observation geometry. |

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

---

## Output Descriptions

| File | Description |
|------|-------------|
| **rotating_3d.html** | Static interactive Plotly 3D scatter in the Sun-centred synodic frame. Sun at origin, Earth pinned on +x axis, satellite trace coloured by time. Shows tadpole libration around L4. |
| **inertial_3d.html** | Lightweight browser animation (JS + Plotly restyle). Shows Earth and satellite both orbiting the Sun. Play/Pause button and time slider. Labelled head markers for Earth and Sat. |
| **z_vs_time.html** | Time series of the satellite's ecliptic-normal displacement with a dashed theoretical sinusoidal overlay. |

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
```
