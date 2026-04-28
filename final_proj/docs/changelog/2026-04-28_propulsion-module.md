# Changelog — v0.3 Fixed-Thruster Propulsion Module

**Date range:** April 27–28, 2026  
**Author:** Member A (Dynamicist & Lead Programmer)

---

## Assumptions

These assumptions define the first propulsion implementation integrated into the Sol-Sentinel optimization scaffold.

| # | Assumption | Justification |
|---|-----------|---------------|
| 1 | **Propulsion is treated as an existing-engine selection problem, not an engine-design problem.** The module assumes one electric-propulsion unit is selected a priori and uses its published operating point. | This matches the project objective and lecture scope. The current task is to convert orbit-maintenance demand into propulsion requirements and system-level budget impacts, not to derive a new electric thruster design from first principles. |
| 2 | **The baseline engine is fixed to the ThrustMe NPT30-I2-1.5U.** | Among the currently reviewed candidates, the NPT30 provides the most complete package-level public data needed by the optimizer: thrust range, power range, specific impulse, total impulse, wet mass, dimensions, and packaged volume. |
| 3 | **Single-valued nominal engine inputs are taken from the midpoint of published ranges when a range is given.** | The optimizer requires one deterministic operating point for a first-pass algebraic module. This avoids adding a second optimization problem over throttle state before the rest of the system equations are complete. |
| 4 | **The mission lifetime is fixed to 3 years in the first propulsion implementation.** | This matches the 3-year propagation horizon used to fit the current SRP surrogate, preserving consistency between the orbit-maintenance input and the propulsion-sizing horizon. |
| 5 | **A 20% delta-V margin is applied to the orbit-maintenance burden before sizing propulsion.** | The SRP surrogate provides a drift-proxy maintenance demand rather than the output of a closed-loop station-keeping controller. The added margin is a simple way to absorb modeling simplification without claiming unearned precision. |
| 6 | **Station keeping is modeled as one correction event every 30 days.** | A monthly cadence gives an interpretable burn-duration timescale for a low-thrust EP system while avoiding unrealistically short daily corrections in the first conceptual design pass. |
| 7 | **`propulsion_power_w` is the on-state burn power during an active correction, not a yearly average.** | This is the power quantity most relevant to the downstream Power module, because correction mode is expected to drive the peak EPS demand. |
| 8 | **Propellant mass remains an explicit budget term, but the total spacecraft mass is treated as effectively constant over the mission.** | The mission propellant required by the current orbit-maintenance burden is extremely small compared with total wet mass, so neglecting the mass change during the mission is acceptable in the first fixed-thruster implementation. |
| 9 | **The NPT30 hardware mass is inferred from its published wet mass and total impulse capability when no dry-mass split is published.** | The optimization framework carries `propulsion_mass_kg` and `propellant_mass_kg` separately. To avoid double counting, the first implementation estimates hardware mass as wet mass minus the propellant capacity implied by the published total impulse and specific impulse. |

---

## Summary of Changes

### 1. Propulsion Configuration Model (`source/optimization/propulsion_module.py`)

- Added `MissionConfig` to hold mission-level propulsion assumptions:
  - mission lifetime,
  - delta-V safety margin,
  - correction cadence.
- Added `FixedThrusterSpec` to represent one selected propulsion package using published or assumed single-point values:
  - thrust,
  - burn power,
  - specific impulse,
  - package wet mass,
  - package volume,
  - total impulse capability.
- Added `PropulsionConfig` and a JSON loader so propulsion assumptions can be stored in a standalone config file rather than hard-coded into the optimizer.

### 2. Fixed-Thruster Propulsion Discipline (`source/optimization/propulsion_module.py`)

- Implemented `FixedThrusterPropulsionModule`, a new optimization discipline that consumes:
  - `delta_v_mps_per_year`,
  - `total_wet_mass_kg`.
- The module returns the optimizer outputs already reserved for Propulsion in the XDSM scaffold:
  - `propulsion_power_w`,
  - `propellant_mass_kg`,
  - `propulsion_mass_kg`,
  - `propulsion_volume_u`.
- The implementation applies the mission delta-V margin before sizing propulsion demand.
- The implementation converts the annualized orbit-maintenance burden into a mission total delta-V over the fixed 3-year mission lifetime.
- Propellant mass is computed with the rocket equation using the selected thruster's specific impulse.
- Propulsion hardware mass is resolved from the chosen thruster package data, using an inferred hardware-mass split when only wet mass is available.
- The propulsion subsystem volume is passed through from the fixed engine packaging data.

### 3. Diagnostics and Internal Feasibility Quantities (`source/optimization/propulsion_module.py`)

- Added a `diagnostics(...)` method to compute reporting and feasibility quantities that are not yet optimizer outputs:
  - effective annualized delta-V after margin,
  - per-cycle delta-V,
  - burn duration,
  - duty cycle,
  - required mission total impulse,
  - burn energy per correction.
- These diagnostics support later work on:
  - EPS sizing,
  - battery sizing,
  - operational burn planning,
  - engine feasibility checks.

### 4. Optimizer Integration (`source/optimization/sol_sentinel.py`, `source/optimization/__init__.py`)

- Extended `build_sol_sentinel_analysis(...)` so the propulsion discipline can be built automatically from a propulsion config JSON.
- Preserved backward compatibility with the existing placeholder-based scaffold: if no propulsion config is supplied, the old placeholder module remains available.
- Exported the new propulsion config and module builders through the optimization package `__init__` for direct use in scripts and notebooks.

### 5. Propulsion Assumption File (`config/optimization_npt30_low_inc.json`)

- Added a dedicated optimization config file for the first propulsion baseline.
- The initial file stores:
  - 3-year mission lifetime,
  - 20% delta-V margin,
  - 30-day correction cadence,
  - NPT30 midpoint thrust and power,
  - NPT30 specific impulse,
  - NPT30 wet mass,
  - NPT30 package volume,
  - NPT30 total impulse capability.
- Empty placeholders for other subsystem sections (`comms`, `power`, `thermal`) were retained so the file can later expand into a broader optimizer assumption file shared across all modules.

### 6. Documentation (`docs/propulsion/propulsion_fixed_thruster_formulation.md`, `docs/propulsion/propulsion_engine_candidates.md`)

- Added a dedicated propulsion-formulation note documenting:
  - the fixed-thruster abstraction,
  - the input-output relation from Orbit to Propulsion,
  - the mission assumptions required by the model,
  - the interpretation of burn power and duty cycle.
- Added a candidate-engine comparison note summarizing the three current EP options:
  - ThrustMe NPT30-I2-1.5U,
  - Busek BIT-3,
  - Busek BHT-200.
- Documented why the NPT30 is the current baseline candidate for implementation.

---

## Verified Results

| Case | Inputs | Verified result | Status |
|------|--------|-----------------|--------|
| Config load smoke test | `config/optimization_npt30_low_inc.json` | JSON assumptions load successfully into `PropulsionConfig`, `MissionConfig`, and `FixedThrusterSpec` | ✓ |
| Fixed-point optimizer smoke test | Real SRP surrogate + seeded placeholder values for non-propulsion modules | The analysis converged in 3 iterations with the fixed-thruster propulsion module inserted into the live optimization chain | ✓ |
| Propulsion output smoke test | Same converged fixed-point run | Returned `propulsion_power_w = 50 W`, `propulsion_volume_u = 1.5 U`, and a resolved hardware mass of approximately `1.296 kg` for the NPT30 baseline | ✓ |
| Mission propellant check | Same converged fixed-point run | Required propellant mass remained extremely small (`~6.05e-06 kg` in the smoke-test state), supporting the assumption that mission mass loss is negligible in the first implementation | ✓ |
| Diagnostic output wiring | Same converged fixed-point run | Burn duration, duty cycle, required total impulse, and burn energy are all computed successfully by `diagnostics(...)` | ✓ |

### Note on startup-state requirements

The current multidisciplinary analysis order still evaluates Power before Propulsion. As a result, `propulsion_power_w` remains a startup guess required by the first iteration of the Gauss-Seidel loop, even though Propulsion now computes that quantity on subsequent iterations. This is consistent with the existing placeholder-based scaffold and does not block the first propulsion implementation, but it should be revisited if a later refactor changes the module execution order or introduces tighter startup-state automation.

---

## Known Limitations / Next Steps

### Modelling limitation: fixed engine operating point

The first propulsion implementation uses one nominal operating point for the selected thruster rather than explicitly modeling throttle state or mode switching. This is appropriate for the current preliminary design stage, but it means the optimizer is not yet trading between different EP operating points or between different engines.

### Modelling limitation: inferred hardware-mass split

For the NPT30 baseline, the optimizer currently infers hardware mass from wet mass minus the propellant capacity implied by published total impulse and specific impulse. This keeps the optimizer bookkeeping internally consistent, but the split should be replaced by a vendor-published dry mass if one becomes available.

### Modelling limitation: no enforced feasibility constraints yet

The propulsion module computes burn duration, duty cycle, required total impulse, and burn energy, but these are not yet enforced as formal constraints in the outer optimizer. They are available for later use once the optimization problem definition matures.

### Next steps

1. **Promote propulsion diagnostics into formal optimization constraints** — enforce checks on burn duration, total impulse, and burn-power support once the problem formulation in `problem.py` is expanded.
2. **Integrate propulsion assumptions into a broader optimizer config** — extend the current propulsion config into a single project-level assumption file shared by Comms, Power, Thermal, Orbit, Propulsion, and Budget.
3. **Decide whether burn energy or duty cycle should feed directly into the Power module** — the current scaffold passes only burn power into Power, but battery sizing may later require an explicit energy or duty-cycle interface.
4. **Replace inferred NPT30 hardware mass if better vendor data becomes available** — the present split is useful for the first iteration but should not be treated as flight-qualified packaging truth.
5. **Write the propulsion report section for the project documentation** — now that the implementation and assumptions are fixed, the next documentation step is a formal report-style writeup of the propulsion formulation, assumptions, and baseline-engine rationale.