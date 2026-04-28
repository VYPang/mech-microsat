# Sizing Solver and Optimization Framework

This document describes the implemented Sol-Sentinel system-level sizing framework as it exists in the current codebase.

The framework now works primarily as a deterministic solver. For a fixed JSON configuration, it closes the subsystem feedback loop and returns one converged spacecraft design point: total wet mass, packed volume, solar-array area, effective reflectivity, propellant mass, burn duration, and related diagnostics. An outer optimization layer still exists, but it is optional and is not the default workflow in the current low-inclination configuration.

## 1. High-Level Principle

The current framework solves the spacecraft design as a low-dimensional coupled algebraic system.

The guiding idea is:

1. Each subsystem computes algebraic outputs from the current shared system state.
2. The coupled outputs are fed forward through the subsystem chain.
3. The solver repeatedly sweeps through that chain until the coupled variables stop changing within a prescribed tolerance.

This is a fixed-point multidisciplinary analysis (MDA), not a Newton solver and not a large external MDO framework. That choice is appropriate here because the current Sol-Sentinel problem is dominated by a small number of tightly coupled subsystem quantities rather than by a large sparse derivative structure.

For a fixed mission definition and fixed subsystem assumptions, the framework therefore behaves as a sizing solver, not as a search over a broad design space.

## 2. Packages and Solver Roles

The current implementation uses the following packages and tools:

- Python standard library for data structures, configuration loading, and orchestration.
- A project-local nonlinear solver in `final_proj/source/optimization/analysis.py` through the `FixedPointAnalysis` class.
- SciPy only for the optional outer optimization script in `final_proj/scripts/run_optimization.py` via `scipy.optimize.minimize`.
- Typer for the command-line interface.
- Rich for formatted terminal summaries.

The important point is that the main sizing solve does not currently rely on SciPy's root-finding routines or on an external MDO package. The main nonlinear solve is the custom ordered fixed-point loop implemented locally in the repository.

## 3. Package Contents

The optimization-side package is structured as follows:

- `state.py`: immutable system-state container passed between modules.
- `equations.py`: `Equation` dataclass for explicit input-output relations.
- `modules.py`: discipline wrappers such as `EquationModule` and `PlaceholderModule`.
- `analysis.py`: the fixed-point solver that performs the Gauss-Seidel iteration.
- `problem.py`: design-variable, objective, and constraint containers for optional outer optimization.
- `orbit_module.py`: adapter around the SRP response-surface surrogate.
- `comms_module.py`: config-driven fixed communications bookkeeping module.
- `power_thermal_module.py`: config-driven station-keeping power model and hot-case thermal model.
- `propulsion_module.py`: config-driven fixed-thruster propulsion model.
- `sol_sentinel.py`: system assembly, startup-input loading, objective loading, and budget closure.
- `variables.py`: canonical internal names, symbols, units, and ownership metadata.

The user-facing entry points are:

- `final_proj/scripts/run_design_point.py`: the default sizing solver.
- `final_proj/scripts/run_optimization.py`: optional outer optimization wrapper.

## 4. Canonical Variable Names

The framework adopts snake-case internal names while preserving the XDSM symbols in metadata.

| Internal name | XDSM symbol | Meaning |
|---|---|---|
| `range_to_l4_m` | `R_{L4}` | Earth-to-L4 range sent to Comms |
| `data_rate_bps` | `DataRate` | Communications throughput requirement |
| `payload_power_w` | `P_{payload}` | Payload electrical load |
| `temperature_requirement_k` | `T_{req}` | Thermal requirement |
| `solar_array_area_m2` | `A_{sa}` | Solar-array area from Power |
| `effective_reflectivity` | `\rho_{eff}` | Effective optical coefficient from Thermal |
| `delta_v_mps_per_year` | `\Delta V_{avg}` | Orbit-maintenance proxy from Orbit |
| `propulsion_power_w` | `P_{ion}` | Electrical draw from Propulsion |
| `burn_duration_s` | `t_{burn}` | Burn duration produced by Propulsion |
| `propellant_mass_kg` | `M_{prop}` | Propellant mass from Propulsion |
| `total_wet_mass_kg` | `M_{tot}` | Total mass from Budget |
| `total_volume_u` | `V_{tot}` | Total packed volume from Budget |

The full registry lives in `final_proj/source/optimization/variables.py`.

## 5. Current Implemented Module Chain

The default assembly in `sol_sentinel.py` follows the current XDSM order:

1. `Comms`
2. `Power`
3. `Thermal`
4. `Orbit`
5. `Propulsion`
6. `Budget`

In the current baseline, these are not just placeholders. They are loaded as real config-driven modules when a shared optimizer config file is provided:

- `Comms`: fixed communications bookkeeping module.
- `Power`: station-keeping power and battery sizing module.
- `Thermal`: hot-case radiator and effective-reflectivity module.
- `Orbit`: SRP surrogate evaluation module.
- `Propulsion`: fixed-thruster propulsion sizing module.
- `Budget`: total mass and total packed-volume closure module.

The coupled variables iterated by `FixedPointAnalysis` are:

- `tx_power_w`
- `solar_array_area_m2`
- `power_dissipated_w`
- `effective_reflectivity`
- `delta_v_mps_per_year`
- `propulsion_power_w`
- `burn_duration_s`
- `propellant_mass_kg`
- `propulsion_mass_kg`
- `propulsion_volume_u`
- `total_wet_mass_kg`
- `total_volume_u`

These variables define the feedback loop that the solver must close.

## 6. How the Current Solver Solves the Problem

The solver workflow is:

1. Build the module chain with `build_sol_sentinel_analysis(...)`.
2. Build an initial state from the configuration file using `load_optimizer_initial_state(...)`.
3. Run an ordered Gauss-Seidel sweep over the subsystem chain.
4. After each full sweep, measure the residual on the coupled variables.
5. Stop when the residual is below tolerance, or report failure if the iteration cap is reached.

The key numerical idea is the ordered Gauss-Seidel update. During one iteration, the modules are evaluated in sequence, and each module's outputs are written immediately into the shared `SystemState`. This means downstream modules in the same sweep see the most recently updated upstream values.

In code terms, one iteration is:

1. Evaluate `Comms`, update state.
2. Evaluate `Power`, update state.
3. Evaluate `Thermal`, update state.
4. Evaluate `Orbit`, update state.
5. Evaluate `Propulsion`, update state.
6. Evaluate `Budget`, update state.

Then the solver compares the new coupled-variable values against the previous iteration.

## 7. Convergence Criterion

The convergence criterion is implemented in `analysis.py` through a maximum relative residual over the coupled variables:

```text
r^(k) = max_i |x_i^(k) - x_i^(k-1)| / max(1, |x_i^(k)|)
```

where `i` runs over the coupled-variable list above.

Important details:

- The scale factor is `max(1, |current|)`, so very small variables do not create artificially large relative residuals.
- If either the previous or current value for a coupled variable is missing, the residual is treated as infinity.
- The solver stores the per-iteration residuals in `FixedPointResult.residual_history`.

The default solver settings used by `build_sol_sentinel_analysis(...)` are:

- tolerance: `1e-6`
- maximum iterations: `25`

The solve is declared converged when:

```text
r^(k) <= 1e-6
```

If convergence is not achieved after `25` sweeps, the solver returns the last state with `converged = False`.

## 8. Startup State and Initial Guesses

Because the subsystem chain is coupled, some quantities must be seeded before the first sweep. The initial state is built from two pieces:

1. Fixed externally specified inputs from the configuration.
2. Startup seeds for coupled variables that are needed before their producing discipline has completed one iteration.

`load_optimizer_fixed_inputs(...)` currently loads quantities such as:

- `range_to_l4_m`
- `data_rate_bps`
- `payload_power_w`
- `payload_mass_kg`
- `payload_volume_u`
- `temperature_requirement_k`

`load_optimizer_startup_seeds(...)` then adds seeded coupled values from `optimizer.startup_seed` in the JSON config. In the current baseline, these seeds include variables such as:

- `propulsion_power_w`
- `burn_duration_s`
- `total_wet_mass_kg`
- `propellant_mass_kg`

These are not the final answers. They are only the starting point that allows the fixed-point loop to begin.

The property `analysis.startup_inputs` reports exactly which values must exist in the initial state before the first solve.

## 9. Orbit Integration

The orbit block is already wired to the real SRP surrogate through `OrbitSurrogateModule`.

Its current interface is:

- Inputs: `solar_array_area_m2`, `effective_reflectivity`, `total_wet_mass_kg`, `propellant_mass_kg`
- Outputs: `delta_v_mps_per_year`, `ballistic_coefficient_m2_per_kg`, `orbit_mass_for_srp_kg`

At present, the surrogate still evaluates on total wet mass because that is how the SRP response surface was fit. `propellant_mass_kg` remains an explicit input so that a later higher-fidelity orbit model can revise the mass policy without requiring a framework rewrite.

## 10. Default User Workflow

The default way to use the framework today is to solve one config-defined design point:

```bash
python final_proj/scripts/run_design_point.py \
    --config final_proj/config/optimization_npt30_low_inc.json
```

That script:

1. Builds the config-driven module chain.
2. Loads fixed inputs and startup seeds from the JSON file.
3. Runs `FixedPointAnalysis.run(...)`.
4. Reports the converged state and subsystem diagnostics.

The current summary output includes quantities such as:

- total wet mass
- total packed volume
- solar-array area in `m^2`
- solar-array area as `1U-face` equivalent for quick CubeSat interpretation
- effective reflectivity
- delta-v proxy
- propellant mass
- burn duration and burn energy diagnostics

## 11. Optional Outer Optimization Layer

The outer optimization layer is still present, but it is now clearly secondary to the sizing solver.

Its role is:

1. Choose explicit design variables.
2. For each candidate vector, run the full fixed-point sizing solve.
3. Evaluate objectives from the converged state.
4. Let SciPy update the candidate vector.

The current wrapper for this is `final_proj/scripts/run_optimization.py`, which uses `scipy.optimize.minimize`.

However, the default low-inclination configuration now sets:

```json
"design_variables": []
```

so the baseline framework behaves as a solver by default. This is intentional: the current physically meaningful task is to solve for the coupled design point first, then decide later which outer design variables are worth optimizing.

The objective metadata is still config-driven through `optimizer.objective`, with `total_wet_mass_kg` currently the primary metric.

## 12. How the Framework Can Be Extended

The same architecture still supports future model growth.

Subsystem modules can be refined or replaced without changing the fixed-point solver internals. `build_sol_sentinel_analysis(...)` accepts injected module implementations, so a teammate can substitute a higher-fidelity discipline while keeping the same shared state and convergence logic.

The recommended next extensions are:

1. Improve subsystem fidelity where assumptions are still deliberately simple.
2. Use the sizing solver for parameter sweeps and sensitivity studies.
3. Introduce only physically meaningful outer design variables.
4. Re-enable outer optimization once the design space is worth searching.

This keeps the current solver stable while preserving a clean path toward a more complete MDO workflow later.