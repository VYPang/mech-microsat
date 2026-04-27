# Fixed-Thruster Propulsion Formulation

## 1. Purpose

This note defines the first propulsion formulation for the Sol-Sentinel optimization framework under the assumption that the propulsion technology has already been fixed to one existing electric-propulsion unit.

The role of the propulsion module is therefore not to design a new engine. Instead, it translates the orbit-maintenance burden from the Orbit module into:

- the propulsion power draw passed to the Power module,
- the propellant mass required over mission life,
- the propulsion subsystem mass carried into the Budget module,
- the propulsion subsystem volume carried into the Budget module,
- and the burn-duration / duty-cycle checks needed to confirm that the chosen thruster is feasible.

This matches the current optimization scaffold in `final_proj/source/optimization/sol_sentinel.py`, where Propulsion sits between Orbit and Budget and already exposes the variables:

- `delta_v_mps_per_year`
- `propulsion_power_w`
- `propellant_mass_kg`
- `propulsion_mass_kg`
- `propulsion_volume_u`

---

## 2. Upstream Orbit Input

The Orbit module provides the annual orbit-maintenance burden

$$
\Delta V_{avg} \quad [\mathrm{m/s/yr}],
$$

stored in the optimizer state as

- `delta_v_mps_per_year`

This quantity comes from the SRP surrogate and represents the annualized maintenance demand for the fixed low-inclination L4 reference orbit and the 3-year SRP propagation used to fit the surrogate.

For the first propulsion model, this value is treated as the required station-keeping velocity correction that must be delivered repeatedly during the mission.

---

## 3. Fixed-Thruster Assumption

For this first formulation, the propulsion hardware is assumed to be fixed to one flight-available engine family. Once a thruster is fixed, the propulsion module no longer solves for a new thrust-to-power relation. Instead, it reads the engine's published operating point and checks whether the mission demand can be met.

The chosen engine contributes the following fixed inputs to the propulsion model:

- `F_thr`: nominal thrust during burn [N]
- `P_thr`: nominal electrical power draw during burn [W]
- `Isp_thr`: nominal specific impulse [s]
- `M_prop_sys`: propulsion subsystem mass carried into Budget [kg]
- `V_prop_sys`: propulsion subsystem packed volume carried into Budget [U]
- `I_tot_max`: maximum available total impulse [N s], if published

If the vendor publishes a range instead of a single number, the current project rule is to use the midpoint of the published range as the nominal operating point unless a different operating point is chosen explicitly.

---

## 4. Additional Mission Assumptions

The propulsion equations require the following mission-level assumptions in addition to the orbit output:

- `M_tot`: current total wet spacecraft mass from Budget [kg]
- `T_life`: mission lifetime [yr]
- `Delta_t_cycle`: time between planned correction events [s]
- `t_burn_max`: optional upper bound on acceptable burn duration per correction [s]

For the current project baseline:

- `T_life = 3 yr`
- the orbit surrogate remains the same 3-year low-inclination case used in the SRP sweep
- `Delta_t_cycle` is still a user-chosen operations assumption and should be fixed before implementation (for example weekly or monthly correction)

---

## 5. Core Formulation

### 5.1. Per-cycle correction demand

Convert the annualized orbit-maintenance burden into the velocity correction required over one correction interval:

$$
\Delta V_{cycle} = \Delta V_{avg} \cdot \frac{\Delta t_{cycle}}{1\ \mathrm{yr}}
$$

This is the amount of velocity correction the propulsion system must provide during one station-keeping event.

### 5.2. Required impulse per correction

For the current spacecraft mass level,

$$
I_{cycle,req} = M_{tot} \cdot \Delta V_{cycle}
$$

where `M_tot` is the total wet mass passed from Budget.

### 5.3. Burn duration for the fixed thruster

If the engine is fixed, the burn time needed to deliver the required correction is

$$
t_{burn} = \frac{I_{cycle,req}}{F_{thr}} = \frac{M_{tot} \cdot \Delta V_{cycle}}{F_{thr}}
$$

This is the central feasibility output. It answers the question: given the orbit-maintenance demand and the chosen engine thrust, how long must one correction burn last?

### 5.4. Duty cycle

The fraction of time spent firing over one correction interval is

$$
\delta = \frac{t_{burn}}{\Delta t_{cycle}}
$$

This is useful for later EPS and operations reasoning, even if it is not yet a formal optimizer variable.

### 5.5. Power passed to the Power module

Because the engine type is fixed, the propulsion module does not derive burn power from first principles in the first version. Instead, it passes the chosen thruster operating power directly to Power:

$$
P_{ion} = P_{thr}
$$

This should be interpreted as the propulsion electrical load during an active correction burn.

Therefore, the optimizer variable

- `propulsion_power_w`

should be treated as the on-state propulsion power draw, not the annual average power spread over a year.

For reporting only, the average propulsion power over one correction cycle can be written as

$$
\bar{P}_{cycle} = \delta \cdot P_{thr}
$$

but this averaged quantity is not what is currently passed to the Power module.

### 5.6. Total mission delta-V

The total orbit-maintenance demand over mission life is

$$
\Delta V_{life} = \Delta V_{avg} \cdot T_{life}
$$

with `T_life = 3 yr` in the first baseline case.

### 5.7. Propellant mass

Using the fixed thruster specific impulse,

$$
M_{prop} = M_{tot} \left(1 - e^{-\Delta V_{life}/(g_0 Isp_{thr})}\right)
$$

For the very small station-keeping delta-V values currently produced by the orbit surrogate, the small-delta-V approximation is often sufficient:

$$
M_{prop} \approx M_{tot} \cdot \frac{\Delta V_{life}}{g_0 Isp_{thr}}
$$

The optimizer variable returned by Propulsion is:

- `propellant_mass_kg = M_prop`

### 5.8. Propulsion subsystem mass and volume

Because the engine is fixed, the first propulsion model treats the hardware package as a constant imported from the chosen engine specification:

$$
M_{prop,sys} = \text{fixed engine package mass}
$$

$$
V_{prop} = \text{fixed engine package volume}
$$

These are mapped to the optimizer outputs:

- `propulsion_mass_kg`
- `propulsion_volume_u`

If the published engine mass is wet rather than dry, the project must decide whether to:

1. treat that published wet mass as the full propulsion package and avoid double-counting propellant, or
2. split it into hardware mass plus separately modeled propellant mass.

For optimizer consistency, the preferred convention is:

- `propulsion_mass_kg` = hardware package mass excluding separately modeled mission propellant when possible
- `propellant_mass_kg` = mission propellant consumed over the 3-year maintenance life

If the vendor only publishes total wet mass, that value should be documented as a simplifying assumption.

---

## 6. Feasibility Checks

Once the fixed-thruster equations are evaluated, the propulsion module should check the following conditions.

### 6.1. Burn-duration feasibility

The chosen engine must be able to complete the required correction within the allowed correction window:

$$
t_{burn} \le t_{burn,max}
$$

or, if no separate maximum burn duration is imposed,

$$
t_{burn} \le \Delta t_{cycle}
$$

### 6.2. Total impulse feasibility

If the engine publishes a total impulse capability, the mission demand must satisfy

$$
M_{tot} \cdot \Delta V_{life} \le I_{tot,max}
$$

### 6.3. Power feasibility

The Power module must be able to support the engine burn load:

$$
P_{available, burn} \ge P_{thr}
$$

This is why the propulsion output sent to Power is the on-state burn power rather than a yearly average.

---

## 7. Recommended First Optimizer Interface

For the current framework, the propulsion discipline can be implemented with:

### Inputs from the MDA loop

- `delta_v_mps_per_year`
- `total_wet_mass_kg`

### Fixed propulsion / mission parameters

- chosen engine nominal thrust `F_thr`
- chosen engine nominal power `P_thr`
- chosen engine nominal specific impulse `Isp_thr`
- chosen engine package mass
- chosen engine package volume
- chosen engine total impulse capability, if available
- mission lifetime `T_life = 3 yr`
- correction interval `Delta_t_cycle`

### Outputs back into the optimizer state

- `propulsion_power_w`
- `propellant_mass_kg`
- `propulsion_mass_kg`
- `propulsion_volume_u`

### Recommended diagnostic outputs for reporting or later constraints

- required burn duration `t_burn`
- correction-event delta-V `Delta_V_cycle`
- duty cycle `delta`
- required mission total impulse `I_life_req = M_tot * Delta_V_life`

---

## 8. Interpretation

The most important modeling consequence of fixing the engine is this:

- `delta_v_mps_per_year` determines how often and how long the thruster must fire,
- but it does not determine a new engine power level once the engine type is fixed.

In other words, the orbit model sizes the burn schedule and propellant usage, while the fixed engine specification provides the burn power level and package properties.

That is the correct abstraction for this project stage, because the real task is existing-engine selection and system closure, not detailed electric-thruster design.