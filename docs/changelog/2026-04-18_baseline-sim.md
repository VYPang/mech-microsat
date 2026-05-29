# Changelog — v0.1 Baseline CR3BP Simulation

**Date range:** April 18, 2026  
**Author:** Member A (Dynamicist & Lead Programmer)

---

## Assumptions

These assumptions were made at the start of the development and remain in effect
for all results produced by this version of the code.

| # | Assumption | Justification |
|---|-----------|---------------|
| 1 | **Transit phase is out of scope.** The CubeSat is assumed to already be injected into the L4 region. | Per project plan §1: "The design of the interplanetary transit phase is excluded from this scope." |
| 2 | **Two-body gravity only (CR3BP).** The simulation includes the Sun (central body) and Earth (perturber) via SPICE ephemeris. No other planets, moons, or relativistic effects are modelled. | Baseline orbit characterisation; higher-fidelity perturbations (Jupiter, Venus) are deferred to a later iteration. |
| 3 | **No Solar Radiation Pressure (SRP).** The cannonball SRP model is not yet enabled. | This version establishes the unperturbed reference orbit. SRP will be added in the next phase to quantify station-keeping ΔV. |
| 4 | **Point-mass spacecraft.** The satellite is modelled as a 24 kg point mass (12U placeholder) with no attitude dynamics. | Attitude coupling is negligible for orbit-level analysis at this stage. |
| 5 | **L4 initial conditions via +60° rotation of Earth's SPICE state.** The satellite's position is Earth's position rotated +60° about the ecliptic normal. The velocity is Earth's velocity rotated +60°, then decomposed as v·cos(i) in-plane + v·sin(i) out-of-plane. | Preserves vis-viva energy (same semi-major axis → same orbital period → no secular drift relative to Earth). |
| 6 | **Ecliptic-plane inclination is a free parameter.** The out-of-plane oscillation always has a ~1-year period set by solar gravity; only the amplitude changes with inclination. | Linearised z-equation of motion near L4: z̈ ≈ −n²z gives T = 2π/n ≈ 1 yr. |
| 7 | **Earth propagation for rotating-frame transform uses two-body Keplerian model.** SPICE ephemeris (DE430) only covers to ~2650 CE, so for long-duration runs the Earth reference path is propagated analytically from the initial SPICE state. | Allows arbitrarily long simulations (tested up to 1000 yr). The error from neglecting planetary perturbations on Earth's orbit is acceptable for visualisation purposes. |

---

## Summary of Changes

### 1. Initial Conditions (`source/initial_conditions.py`)

- Implemented `compute_l4_state(epoch_utc, inclination_deg)` → returns `L4State` dataclass with satellite and Earth position/velocity in Sun-centred ECLIPJ2000.
- **Bug fix (v1):** Original implementation added v_z = v_circ·tan(i) on top of the full in-plane speed → total speed = v_circ/cos(i) → ~3.2% excess orbital energy → satellite circled the Sun instead of librating near L4.
- **Bug fix (v2):** First fix used v_circ = √(GM/r) at instantaneous distance (perihelion, 0.983 AU) → correct circular orbit at that radius but period ≈ 356 days ≠ 365 days → ~9°/yr drift.
- **Final fix:** Use Earth's actual SPICE velocity (which encodes a = 1.000 AU via vis-viva), rotate it to L4, decompose as v·cos(i) in-plane + v·sin(i) out-of-plane. Preserves total speed → same semi-major axis → same period. Verified: θ range 54.3°–60.7° (proper tadpole libration).
- Implemented `get_earth_states()` using vectorised two-body Keplerian propagation (replaces SPICE ephemeris loop). Solves Kepler's equation via Newton-Raphson. Works for any duration with no ephemeris coverage limit.

### 2. Basilisk N-body Simulation (`source/cr3bp_sim.py`)

- Implemented `run_cr3bp_baseline()` using Basilisk's `gravBodyFactory` (Sun central + Earth perturber), `spacecraft.Spacecraft`, and SPICE interface.
- Added Rich progress bar (elapsed + ETA) by stepping the simulation in sub-intervals and updating after each.
- **Chunked simulation** for durations > 584 years: BSK's nanosecond timer uses uint64_t which overflows at ~584 yr. The simulation is split into 500-yr segments with state continuity between chunks.

### 3. Rotating-Frame Transform (`source/rotating_frame.py`)

- Implemented `to_rotating_frame(df, epoch_et)` — transforms inertial trajectory into Sun-centred synodic frame where Earth sits on +x axis.
- Vectorised using `np.einsum` for the per-timestep rotation matrices.
- Also stores inertial Earth positions (`x_earth`, `y_earth`, `z_earth`) in the DataFrame for the inertial animation.

### 4. Visualisation (`source/visualize.py`)

- **rotating_3d.html** — dark-themed Plotly 3D scatter in the rotating frame (Sun at origin, Earth on +x, satellite coloured by time). Includes ecliptic plane surface.
- **inertial_3d.html** — lightweight browser animation (pure JS + Plotly `restyle`). Shows Sun, Earth, and satellite moving in the inertial frame with Play/Pause button and time slider. Stores trajectory arrays once (no frame duplication). Labelled head markers with white outlines for visibility.
  - Earlier Plotly-frames approach produced a 1.14 GB file; replaced with the JS-restyle method → ~150 KB.
- **z_vs_time.html** — out-of-plane displacement vs time with theoretical sinusoidal overlay.
- `plot_rotating_xy` (2D top-down) was implemented but later removed from the output set.
- Downsampling (`_downsample`) keeps all HTML files small (~2–7 MB for rotating 3D, ~150 KB for inertial animation).

### 5. Config System (`config/*.json`)

- JSON configs restructured into `simulation` and `visualization` sections:
  ```json
  {
      "simulation": {
          "epoch_utc": "...",
          "duration_years": 50.0,
          "timestep_s": 300.0,
          "inclination_deg": 7.25
      },
      "visualization": {
          "output_dir": "...",
          "inertial_3d_points": 2000,
          "rotating_3d_points": 50000
      }
  }
  ```
- `inertial_3d_points` controls time resolution of the inertial animation.
- `rotating_3d_points` controls point count of the rotating-frame 3D scatter.
- Two configs shipped: `low_inc.json` (7.25°) and `recommand_inc.json` (14.5°).

### 6. CLI & Script Interface (`scripts/run_baseline.py`)

- Config-driven script with Typer CLI.
- `--viz-only` flag: skips simulation, loads saved `.parquet`, re-runs rotating-frame transform and plot generation.
- `--info` flag: prints L4 and Earth state vectors (position in AU and km, velocity in km/s), Earth→L4 separation, and ΔV magnitude, then exits. Intended for transfer orbit design by teammates.
- Rich summary tables printed per config section on every run.
- SPICE state reset (`spice.reset()` + kernel reload) after BSK simulation to prevent `SpiceEMPTYSTRING` errors during post-processing.

### 7. Data Pipeline

- Trajectory saved as Parquet via Polars (`cr3bp_baseline.parquet`).
- Typical file sizes: ~50–200 MB depending on duration and timestep.
- Output directory structure: `output/<config_name>/cr3bp_baseline.parquet` and `output/<config_name>/plots/*.html`.

---

## Verified Results

| Config | Duration | Inc | θ range (rotating) | z amplitude | Status |
|--------|----------|-----|--------------------|-------------|--------|
| recommand_inc | 50 yr | 14.5° | ~54°–67° | ±0.258 AU | ✓ |
| low_inc | 50 yr | 7.25° | ~54°–67° | ±0.127 AU | ✓ |
| low_inc | 200 yr | 7.25° | — | ±0.127 AU | ✓ |
| multi-chunk test | 600 yr | 7.25° | — | — | ✓ |

---

## Known Limitations / Next Steps

1. **Add SRP cannonball model** — `radiationPressure.RadiationPressure()` with tunable area and reflectivity coefficient.
2. **Parameter sweeps** — vary (A_sa, c_R) on the reference orbit and record time-averaged station-keeping ΔV.
3. **Response surface / surrogate model** — fit ΔV_avg = f(A_sa, c_R) for use in system-level optimisation.
4. **OpenMDAO integration** — plug the surrogate into the coupled Orbit-SRP-Propulsion-Power-Mass trade loop.
5. **Stage 2 orbit tuning** — with the optimised spacecraft frozen, vary orbit parameters around L4.
