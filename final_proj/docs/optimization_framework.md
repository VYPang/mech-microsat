# Optimization Framework Scaffold

This document defines the first scaffold for the Sol-Sentinel system-level optimization loop. The goal is not to jump straight into a full MDO package, but to create a defensible preliminary-design architecture that matches the current XDSM and can absorb teammate equations with minimal rewiring.

## 1. Recommended Architecture

For this project, the right level of complexity is:

1. A manual fixed-point multidisciplinary analysis (MDA) loop for the coupled subsystem feedbacks.
2. A thin optimization layer above that loop for design variables, objectives, and constraints.
3. SciPy as the eventual outer optimizer once the subsystem equations are ready.

This matches the project guidelines in [docs/AGENT.md](docs/AGENT.md): the problem is low-dimensional, algebraic, and dominated by a few feedback paths rather than by large sparse Jacobians. An OpenMDAO-sized framework would add overhead without improving the preliminary-design fidelity.

The implemented scaffold therefore uses:

- `final_proj/source/orbit/` for all orbital propagation, SRP sweep, validation, and surrogate files.
- `final_proj/source/optimization/` for optimizer-side state management, module interfaces, equations, fixed-point analysis, and problem definitions.

## 2. Package Contents

The new optimization package is structured as follows:

- `state.py`: immutable system-state container passed between modules.
- `equations.py`: `Equation` dataclass for explicit input-output relations.
- `modules.py`: `EquationModule` and `PlaceholderModule` discipline wrappers.
- `analysis.py`: Gauss-Seidel fixed-point loop that closes the XDSM feedback paths.
- `problem.py`: design-variable, objective, and constraint containers for the future outer optimizer.
- `orbit_module.py`: adapter that exposes the current SRP surrogate as an optimization discipline.
- `sol_sentinel.py`: the project-specific module chain, placeholder definitions, and budget closure.
- `variables.py`: canonical variable names, symbols, units, and ownership.

## 3. Canonical Variable Names

The scaffold adopts snake-case internal names while preserving the XDSM symbols in metadata.

| Internal name | XDSM symbol | Meaning |
|---|---|---|
| `range_to_l4_m` | `R_{L4}` | Earth-to-L4 range sent to Comms |
| `data_rate_bps` | `DataRate` | Communications throughput requirement |
| `payload_power_w` | `P_{payload}` | Payload electrical load |
| `temperature_requirement_k` | `T_{req}` | Thermal requirement |
| `solar_array_area_m2` | `A_{sa}` | Solar-array area from Power |
| `effective_reflectivity` | `\rho_{eff}` | Equivalent optical coefficient from Thermal |
| `delta_v_mps_per_year` | `\Delta V_{avg}` | Orbit-maintenance proxy from Orbit |
| `propulsion_power_w` | `P_{ion}` | Electrical draw from Propulsion |
| `propellant_mass_kg` | `M_{prop}` | Propellant mass from Propulsion |
| `total_wet_mass_kg` | `M_{tot}` | Total mass from Budget |
| `total_volume_u` | `V_{tot}` | Total volume from Budget |

The full registry lives in `final_proj/source/optimization/variables.py`.

## 4. Current Module Chain

The default assembly in `sol_sentinel.py` follows the current XDSM order:

1. `Comms`
2. `Power`
3. `Thermal`
4. `Orbit`
5. `Propulsion`
6. `Budget`

The feedback variables are iterated by `FixedPointAnalysis` until convergence:

- `tx_power_w`
- `solar_array_area_m2`
- `power_dissipated_w`
- `effective_reflectivity`
- `delta_v_mps_per_year`
- `propulsion_power_w`
- `propellant_mass_kg`
- `propulsion_mass_kg`
- `propulsion_volume_u`
- `total_wet_mass_kg`
- `total_volume_u`

This gives the project a real MDA loop immediately, even before every subsystem equation is finished.

## 5. Orbit Integration

The orbit block is already wired to the real SRP surrogate through `OrbitSurrogateModule`.

Its current interface is:

- Inputs: `solar_array_area_m2`, `effective_reflectivity`, `total_wet_mass_kg`, `propellant_mass_kg`
- Outputs: `delta_v_mps_per_year`, `ballistic_coefficient_m2_per_kg`, `orbit_mass_for_srp_kg`

At the moment, the surrogate still evaluates on total wet mass because that is how the SRP response surface was fit. `propellant_mass_kg` is kept as an explicit optimizer-side input so a later higher-fidelity orbit model can revise the mass policy without changing the rest of the framework.

## 6. How Teammates Should Add Equations

Each teammate can replace a placeholder module with an `EquationModule` as soon as they have algebraic relations. The framework does not require them to touch the solver internals.

Example:

```python
from final_proj.source.optimization import Equation, EquationModule

power_module = EquationModule(
    name="power",
    equations=(
        Equation(
            name="solar-array area",
            output="solar_array_area_m2",
            inputs=("payload_power_w", "tx_power_w", "propulsion_power_w"),
            evaluator=lambda state: (
                state.get("payload_power_w")
                + state.get("tx_power_w")
                + state.get("propulsion_power_w")
            ) / 120.0,
        ),
        Equation(
            name="power subsystem mass",
            output="power_mass_kg",
            inputs=("solar_array_area_m2",),
            evaluator=lambda state: 3.0 * state.get("solar_array_area_m2"),
        ),
    ),
)
```

Then rebuild the analysis with that module:

```python
from pathlib import Path

from final_proj.source.optimization import build_sol_sentinel_analysis

analysis = build_sol_sentinel_analysis(
    Path("final_proj/output/low_inc/srp_surrogate.json"),
    power_module=power_module,
)
```

## 7. Startup State and Initial Guesses

Before every module has equations, the scaffold still needs startup values for variables that appear before their producing discipline has run once. The `FixedPointAnalysis.startup_inputs` property lists exactly what must be present in the initial state.

Example:

```python
from pathlib import Path

from final_proj.source.optimization import build_sol_sentinel_analysis

analysis = build_sol_sentinel_analysis(
    Path("final_proj/output/low_inc/srp_surrogate.json")
)

print(analysis.startup_inputs)
```

While modules are still placeholders, you can seed their outputs directly in the startup state. As soon as a teammate replaces a placeholder with real equations, those seeded outputs can be removed.

## 8. Suggested Next Implementation Order

1. Replace the Comms placeholder with the link-budget equations.
2. Replace the Power placeholder with array, battery, and EPS mass relations.
3. Replace the Thermal placeholder with optical-property and radiator sizing equations.
4. Replace the Propulsion placeholder with thruster power, propellant mass, and tank sizing equations.
5. Add objectives and constraints in `problem.py`, then wrap the MDA loop in `scipy.optimize.minimize`.

This order matches the current XDSM and keeps the orbit surrogate usable throughout the build-out.