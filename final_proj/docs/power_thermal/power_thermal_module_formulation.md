# Fixed-Mode Power and Thermal Formulation

## 1. Purpose

This note defines the first Power and Thermal formulations for the Sol-Sentinel optimization framework under the following project-level assumptions:

- the communications hardware has already been fixed to a selected flight-available antenna and transceiver package,
- the propulsion hardware has already been fixed to the NPT30 baseline defined in the propulsion module,
- the power system is sized only for the station-keeping correction mode,
- the battery is allowed to support part of the correction burn, but must retain a prescribed post-burn state of charge,
- the power subsystem mass includes a solar-array mass term that scales with solar-array area,
- and the thermal model is treated as a hot-case radiator-sizing problem rather than a full hot/cold transient thermal model.

For the first implementation, the thermal subsystem mass and volume contributions are neglected because the detailed thermal hardware layout has not yet been defined.

Under these assumptions, the role of the Power module is not to optimize an EPS architecture from scratch. Instead, it translates the fixed station-keeping electrical demand and the fixed battery policy into:

- the solar-array area required to support station keeping,
- the battery power and energy drawn during a correction burn,
- the power dissipated internally and passed to Thermal,
- the EPS mass and volume bookkeeping terms passed to Budget,
- and the battery feasibility checks needed to confirm that the chosen battery can support the burn.

The role of the Thermal module is to translate that hot-case dissipated power and the selected surface optical properties into:

- the radiator area required to remain below the operational hot-case limit,
- the SRP optical coefficient passed to Orbit,
- the thermal subsystem mass and volume bookkeeping terms passed to Budget,
- and the hot-case feasibility checks needed to confirm that the design remains below the governing temperature limit.

This note is written to match the current optimization scaffold in `final_proj/source/optimization/sol_sentinel.py`, while also documenting one recommended interface update:

- the finished Orbit module should receive `C_r` directly from Thermal rather than `rho_eff`, because the orbit implementation now uses the cannonball SRP coefficient explicitly.

---

## 2. Upstream Coupling and Required Inputs

The present Power and Thermal formulations sit downstream of fixed subsystem choices and downstream of the fixed-thruster propulsion model.

### 2.1. Propulsion input used by Power

The Propulsion module provides the on-state thruster electrical power

$$
P_{ion} = P_{thr}
$$

stored in the optimizer state as

- `propulsion_power_w`

For the current NPT30 baseline, this quantity is the electrical draw during an active correction burn, not an annual average.

Because the battery-support policy depends on burn duration, the Power module also requires the propulsion burn-duration result

$$
t_{burn}
$$

which is already computed inside the propulsion diagnostics, even though it is not yet a formal optimizer variable.

### 2.2. Power output used by Thermal and Orbit

The Power module returns:

- `solar_array_area_m2`
- `power_dissipated_w`

The solar-array area feeds Orbit directly because it changes the SRP-sensitive exposed area. The dissipated power feeds Thermal because it sets the hot-case heat rejection requirement.

### 2.3. Thermal output used by Orbit

The Thermal module should provide the cannonball SRP coefficient

$$
C_r
$$

to Orbit.

If backward compatibility with the current scaffold is temporarily required, then Thermal may still report

$$
\rho_{eff} = C_r - 1
$$

but the recommended physical optimizer-side interface is now `C_r` directly.

---

## 3. Fixed Assumptions and Baseline Constants

### 3.1. Station-keeping-only EPS sizing policy

The first Power module is sized only on the station-keeping correction mode.

This means:

- the solar array is not sized on a downlink mode,
- the battery is not sized by eclipse logic,
- and the thermal hot case is also taken from station keeping.

This is justified because the spacecraft operates near Sun-Earth L4 with continuous sunlight, and because the propulsion burn mode is the largest single electrical load.

### 3.2. Fixed station-keeping base loads

The fixed non-propulsion station-keeping loads adopted from the current subsystem selections are:

- payload load: `2.2 W`
- communications receive-mode load: `6.4 W`
- ADCS load: `4.0 W`
- CDH load: `0.7 W`
- EPS housekeeping load: `2.1 W`
- thermal heater allowance: `0.5 W`

The fixed station-keeping base load is therefore

$$
P_{base,sk} = 15.9\ \mathrm{W}
$$

before adding the propulsion burn load.

### 3.3. Propulsion burn load used by Power

The Power module should treat the propulsion burn load as an upstream coupled input from Propulsion:

$$
P_{ion} = \text{propulsion\_power\_w}
$$

In the current fixed-thruster NPT30 implementation, the Propulsion module evaluates this optimizer-state variable to the constant on-state burn power of the selected thruster. For the present NPT30 baseline that runtime value is

$$
P_{ion} = 50\ \mathrm{W}
$$

but the Power module should not hard-code that value internally. It should consume the value returned by Propulsion during the current MDA iteration.

If the selected engine remains the current NPT30 baseline, then the total station-keeping demand resolves numerically to

$$
P_{sk} = P_{base,sk} + P_{ion} = 15.9 + 50.0 = 65.9\ \mathrm{W}
$$

after the Propulsion module has been evaluated. In the formal Power-module formulation below, however, `P_ion` is retained symbolically because it is a coupled input.

### 3.4. Solar-array efficiency chain

The first Power model uses the chained electrical conversion efficiency

$$
\eta_{total} = \eta_{cell}\,\eta_{temp}\,\eta_{rad}\,\eta_{MPPT}\,\eta_{wiring}
$$

with the current baseline values:

- `eta_cell = 0.300`
- `eta_temp = 0.916`
- `eta_rad = 0.9409`
- `eta_MPPT = 1.000`
- `eta_wiring = 1.000`

so that

$$
\eta_{total} = 0.2586
$$

### 3.5. Solar flux constant

The Power and Thermal modules use

$$
S_0 = 1361\ \mathrm{W/m^2}
$$

which is the standard 1 AU solar flux and is consistent with the L4 operating distance for the present project.

### 3.6. Battery assumptions

The battery is fixed to the OPTIMUS-30 baseline with the following working assumptions:

- battery capacity: `E_batt,max = 30 Wh`
- maximum discharge current: `I_dis,max = 1.95 A`
- end-of-charge voltage: `8.26 V` typical, `8.4 V` maximum
- full-discharge voltage: `6.2 V` typical/minimum
- the battery is assumed to be fully charged at the start of every correction burn
- the battery must retain at least `60%` state of charge after the burn

The post-burn SOC requirement is written as

$$
SOC_{post} \ge SOC_{min,post} = 0.60
$$

so the maximum battery energy allowed to support one burn is

$$
E_{batt,usable} = (1 - SOC_{min,post}) E_{batt,max}
$$

For the current baseline,

$$
E_{batt,usable} = (1 - 0.60) \times 30 = 12\ \mathrm{Wh}
$$

### 3.7. Thermal hot-case assumptions

The thermal hot-case model uses:

- OSR emissivity: `epsilon = 0.80`
- OSR absorptivity: `alpha = 0.08`
- solar-array front-side absorptivity: `alpha_sa_front = 0.88`
- solar-array front-side reflectivity: `rho_sa_front = 0.12`
- solar-array back-side absorptivity: `alpha_sa_back = 0.08`
- solar-array back-side reflectivity: `rho_sa_back = 0.92`
- Stefan-Boltzmann constant: `sigma = 5.6696e-8 W/m^2/K^4`
- hot-case design temperature set by the most restrictive upper operating limit among the active components

For the first hot-case implementation, the solar-array thermal environment is modeled with the following additional simplifying assumptions:

- the active front side of the deployed array is Sun-facing during the hot case,
- the back side is not directly illuminated during that same hot case,
- and the non-electrical absorbed solar power on the array is treated as a heat source that must be rejected by the spacecraft thermal control system.

This gives the hot-case illumination factors

$$
\phi_{sa,front} = 1
$$

$$
\phi_{sa,back} = 0
$$

For the current payload set,

- SIS: `-20` to `+50 C`
- VHM: `-30` to `+55 C`
- MERiT: `-25` to `+55 C`
- DHU: `-40` to `+85 C`

the governing payload hot-case limit is

$$
T_{req} = 50^\circ \mathrm{C} = 323\ \mathrm{K}
$$

This is also consistent with the current EPS hot-side limit used in the earlier thermal sizing note.

---

## 4. Power Module Formulation

### 4.1. Station-keeping design load

The power demand used for the first EPS sizing pass is the total load during an active correction burn:

$$
P_{sk} = P_{base,sk} + P_{ion}
$$

where:

- `P_base,sk` is the fixed non-propulsion station-keeping load,
- `P_ion` is the on-state propulsion power from the fixed-thruster propulsion module.

Because `P_base,sk` is fixed by the current subsystem selections while `P_ion` is supplied by Propulsion, `P_sk` is a coupled quantity in the optimizer state rather than a hard-coded constant inside the Power module.

If the Propulsion module evaluates to the present NPT30 baseline value `P_ion = 50 W`, then `P_sk` resolves to `65.9 W`, but the Power-module formulation should retain `P_sk` symbolically.

### 4.2. Solar-array power available during burn

Because the spacecraft operates near L4 under continuous sunlight, the solar array continues producing power during the correction burn. The solar-array power available at the bus is modeled as

$$
P_{sa} = S_0\,\eta_{total}\,A_{sa}
$$

where:

- `A_sa` is the solar-array area to be solved for,
- `S_0` is the 1 AU solar flux constant,
- `eta_total` is the chained electrical efficiency.

### 4.3. Battery power required during burn

If the solar array does not cover the full station-keeping load, the battery supplies the deficit:

$$
P_{batt,burn} = \max\left(0,\ P_{sk} - P_{sa}\right)
$$

This battery-support formulation is what allows the optimizer to trade solar-array area against temporary battery draw during the burn.

### 4.4. Battery energy used during burn

Let the propulsion module provide the burn duration `t_burn` for one correction event. The battery energy consumed during that burn is

$$
E_{batt,burn} = P_{batt,burn}\,t_{burn,h}
$$

where

$$
t_{burn,h} = \frac{t_{burn}}{3600}
$$

is the burn duration expressed in hours.

The post-burn SOC requirement then becomes

$$
E_{batt,burn} \le E_{batt,usable} = (1 - SOC_{min,post}) E_{batt,max}
$$

With the current baseline,

$$
E_{batt,burn} \le 12\ \mathrm{Wh}
$$

This can be rearranged into a direct solar-array lower bound:

$$
A_{sa} \ge \frac{P_{sk} - E_{batt,usable}/t_{burn,h}}{S_0\,\eta_{total}}
$$

with the understanding that the numerator is floored at zero if the battery alone could in principle support the event energetically.

### 4.5. Battery discharge-power limit

The battery must also be able to deliver the instantaneous burn deficit, not just the total burn energy.

The battery-side discharge-power limit is modeled as

$$
P_{batt,burn} \le P_{batt,max}
$$

with

$$
P_{batt,max} = \eta_{dc}\,V_{batt,support}\,I_{dis,max}
$$

where:

- `eta_dc` is the battery-to-bus conversion efficiency,
- `V_batt,support` is the assumed battery support voltage during the burn,
- `I_dis,max` is the battery maximum discharge current.

Because a detailed regulated-bus architecture has not yet been defined, the first formulation should document the voltage assumption explicitly in the configuration file.

Two useful reference values from the current battery data are:

$$
P_{batt,max} = 6.2 \times 1.95 = 12.09\ \mathrm{W}
$$

using the conservative full-discharge voltage, and

$$
P_{batt,max} = 8.26 \times 1.95 = 16.11\ \mathrm{W}
$$

using the typical end-of-charge voltage.

The conservative choice is safer until a bus-regulation model or discharge-voltage curve is added.

### 4.6. Recharge feasibility between burns

The assumption that every correction burn starts at full charge requires a recharge check between burns.

Let the time between planned burns be `Delta_t_cycle`, and let the non-burn load be approximated in the first model as the base station-keeping load with the thruster off:

$$
P_{nonburn} = P_{base,sk}
$$

Then the recharge power available between burns is

$$
P_{recharge} = \max\left(0,\ P_{sa} - P_{nonburn}\right)
$$

and the recharge energy over the rest of the cycle is

$$
E_{recharge} = P_{recharge}\,(\Delta t_{cycle,h} - t_{burn,h})
$$

where `Delta_t_cycle,h` is the correction interval expressed in hours.

To justify the fully charged start-of-burn assumption, the design should satisfy

$$
E_{recharge} \ge E_{batt,burn}
$$

This is the L4 replacement for standard LEO eclipse battery sizing. Instead of recharging after eclipse, the battery is recharged between occasional station-keeping burns under continuous sunlight.

### 4.7. Power dissipated and passed to Thermal

The internal dissipated power is defined as

$$
P_{diss} = P_{sk} - P_{useful,out}
$$

During station keeping there is no transmit-mode RF output, so the first model takes

$$
P_{useful,out} = 0
$$

and therefore

$$
P_{diss} = P_{sk}
$$

This means `power_dissipated_w` is also a coupled quantity: once `P_ion` is known from Propulsion, `P_diss` follows directly from the station-keeping power balance.

If the Propulsion module evaluates to the current NPT30 baseline, then `P_diss` resolves numerically to `65.9 W`, but that numerical value should not be embedded as a fixed constant in the formal Power-module equations.

### 4.8. Power subsystem mass and volume bookkeeping

The optimization scaffold also requires `power_mass_kg` and `power_volume_u`.

Because `A_sa` is a coupled design quantity, the Power module should include an explicit solar-array mass term. A recommended first bookkeeping closure is

$$
M_{pwr} = M_{eps,fixed} + M_{batt,fixed} + \sigma_{sa}\,A_{sa}
$$

$$
V_{pwr} = V_{eps,fixed} + V_{batt,fixed} + k_{sa}\,A_{sa}
$$

where:

- `M_eps,fixed` is the fixed EPS electronics mass,
- `M_batt,fixed` is the fixed battery mass,
- `sigma_sa` is the solar-array areal mass density,
- `V_eps,fixed` is the fixed EPS electronics packaged volume,
- `V_batt,fixed` is the fixed battery packaged volume,
- `k_sa` is the solar-array areal packing coefficient converted to volume units.

This is the minimum mass model needed so that larger solar-array areas feed back into the total spacecraft mass through Budget.

---

## 5. Thermal Module Formulation

### 5.1. Governing hot-case temperature requirement

The first thermal model is a single hot-case equilibrium model. The hot-case requirement is set by the smallest upper operating limit among the active components considered in the design loop:

$$
T_{req} = \min\left(T_{hot,1},\ T_{hot,2},\ \ldots\right)
$$

For the current payload set,

$$
T_{req} = 323\ \mathrm{K}
$$

This first formulation does not yet enforce lower operating limits, survival temperatures, heater duty-cycle logic, or a separate cold-case analysis.

### 5.2. Radiator area from hot-case equilibrium

The radiator must reject the internal electrical dissipation and the additional solar heat absorbed by the solar-array surface while remaining below the hot-case temperature limit.

The first-order solar-array absorbed heat term is written as

$$
Q_{sa,abs} = S_0 A_{sa}\left(\alpha_{sa,front}\phi_{sa,front} + \alpha_{sa,back}\phi_{sa,back} - \eta_{total}\right)
$$

Under the present hot-case assumptions,

$$
Q_{sa,abs} = S_0 A_{sa}\left(\alpha_{sa,front} - \eta_{total}\right)
$$

because the front side is Sun-facing and the back side is not directly illuminated.

Using the current optical assumptions,

$$
Q_{sa,abs} = S_0 A_{sa}(0.88 - 0.2586)
$$

This is the additional solar-array-driven thermal load that grows with `A_sa`.

Using the first-pass isothermal radiator balance,

$$
\underbrace{P_{diss}}_{\text{internal heat}}
+
\underbrace{Q_{sa,abs}}_{\text{solar-array heat}}
=
\underbrace{\epsilon\sigma A_{rad}T_{req}^4}_{\text{radiator emits}}
-
\underbrace{\alpha S_0 A_{rad}}_{\text{radiator absorbs sunlight}}
$$

so the radiator area is

$$
A_{rad} = \frac{P_{diss} + Q_{sa,abs}}{\epsilon\,\sigma\,T_{req}^4 - \alpha\,S_0}
$$

The current project also applies a 20% thermal sizing margin:

$$
A_{rad,final} = 1.2\,A_{rad}
$$

Because `P_diss` is supplied by the coupled Power module, `A_rad` and `A_rad,final` are also coupled outputs rather than fixed constants in the optimizer formulation.

Because `Q_{sa,abs}` depends on `A_sa`, the thermal hot case now includes a second explicit coupling from Power into Thermal in addition to the internal dissipated-power term.

If a single upstream power state is frozen for a reference calculation, then numerical radiator areas can be evaluated afterward, but those reference values should not appear as fixed constants in the formal Thermal-module equations.

### 5.3. Optical coefficient passed to Orbit

Because the Orbit module now uses the cannonball SRP coefficient directly, the recommended thermal output is the area-weighted cannonball reflectivity coefficient

$$
C_r = 1 + \rho_{weighted}
$$

where

$$
\rho_{weighted} = \frac{\sum_i \rho_i A_i}{\sum_i A_i}
$$

If the solar-array front and back surfaces scale with the optimized array area, one convenient first formulation is

$$
\rho_{weighted} = \frac{(\rho_{cell} + \rho_{back})A_{sa} + \sum_j \rho_j A_{j,fixed}}{2A_{sa} + \sum_j A_{j,fixed}}
$$

where:

- `rho_cell` is the reflectivity associated with the solar-cell face,
- `rho_back` is the reflectivity associated with the array back face,
- `A_j,fixed` are the other exposed fixed-geometry spacecraft surfaces.

For the current first-pass assumptions, the recommended values are:

- `rho_cell = 0.12`
- `rho_back = 0.92`

Under this formulation, `C_r` is also a coupled quantity because `A_sa` is a coupled Power-module output.

If a separate frozen-geometry reference study is retained outside the optimizer, then that study may report a single numerical `C_r` for that specific geometry. However, that reference value should not be treated as the formal Thermal-module output when `A_sa` is allowed to vary in the optimization loop.

If backward compatibility with the current optimizer scaffold is temporarily needed, then the equivalent legacy output is

$$
\rho_{eff} = C_r - 1
$$

but the physically correct interface for the finished cannonball Orbit block is `C_r`.

### 5.4. Thermal subsystem mass and volume bookkeeping

The optimization scaffold also requires `thermal_mass_kg` and `thermal_volume_u`.

For the first implementation, the thermal subsystem mass and volume contributions are neglected:

$$
M_{thm} = 0
$$

$$
V_{thm} = 0
$$

This is an explicit modeling assumption rather than a physical claim that thermal hardware has no mass or volume. It is adopted because the detailed thermal architecture, radiator packaging, heater layout, and body-surface allocation have not yet been frozen strongly enough to support a defensible thermal mass model.

Once the thermal hardware concept is better defined, the zero-mass assumption should be replaced by an explicit closure.

---

## 6. Feasibility Checks

### 6.1. Power feasibility checks

The Power module should check the following conditions.

#### 6.1.1. Battery energy reserve during burn

$$
E_{batt,burn} \le (1 - SOC_{min,post}) E_{batt,max}
$$

#### 6.1.2. Battery discharge-power limit

$$
P_{batt,burn} \le P_{batt,max}
$$

#### 6.1.3. Recharge feasibility before the next burn

$$
E_{recharge} \ge E_{batt,burn}
$$

This check is what makes the full-charge-at-burn-start assumption defensible.

### 6.2. Thermal feasibility checks

The Thermal module should check the following conditions.

#### 6.2.1. Positive radiator denominator

$$
\epsilon\,\sigma\,T_{req}^4 - \alpha\,S_0 > 0
$$

Otherwise the selected coating and temperature requirement cannot radiatively reject the absorbed solar heating.

#### 6.2.2. Hot-case temperature feasibility

The chosen radiator area must satisfy

$$
T_{eq} \le T_{req}
$$

which is equivalent to satisfying the radiator sizing equation above.

#### 6.2.3. SRP coefficient bounds

For the cannonball model,

$$
1 \le C_r \le 2
$$

so the chosen weighted optical properties should remain within that physically meaningful range.

---

## 7. Recommended Optimizer Interface

### 7.1. Power module

#### Inputs from the MDA loop or promoted diagnostics

- `propulsion_power_w`
- recommended promoted propulsion diagnostic: `burn_duration_s`

#### Fixed power parameters from configuration

- fixed station-keeping base-load breakdown or `P_base_sk`
- `solar_flux_w_per_m2 = 1361.0`
- solar-array efficiency-chain factors
- `battery_capacity_wh = 30.0`
- `battery_max_discharge_current_a = 1.95`
- `battery_min_soc_after_burn = 0.60`
- documented burn-support voltage assumption
- `correction_cadence_days = 30.0`

#### Outputs back into the optimizer state

- `solar_array_area_m2`
- `power_dissipated_w`
- `power_mass_kg`
- `power_volume_u`

#### Recommended diagnostics for reporting or later constraints

- `battery_power_during_burn_w`
- `battery_energy_during_burn_wh`
- `battery_soc_after_burn`
- `battery_recharge_margin_wh`
- `solar_array_power_during_burn_w`

### 7.2. Thermal module

#### Inputs from the MDA loop or configuration

- `power_dissipated_w`
- `solar_array_area_m2`
- `temperature_requirement_k` if kept as a general optimizer input, or a fixed hot-case requirement if frozen in configuration

#### Fixed thermal parameters from configuration

- `solar_flux_w_per_m2 = 1361.0`
- `emissivity_osr = 0.80`
- `absorptivity_osr = 0.08`
- spacecraft surface optical-property table
- fixed exposed-body surface areas, if the weighted-reflectivity model uses them

#### Outputs back into the optimizer state

- recommended physical output: `c_r`
- if temporary backward compatibility is needed: `effective_reflectivity = c_r - 1`
- `thermal_mass_kg`
- `thermal_volume_u`

#### Recommended diagnostics for reporting or later constraints

- `radiator_area_m2`
- `radiator_area_with_margin_m2`
- `hot_case_temperature_limit_k`
- `weighted_reflectivity`

### 7.3. Suggested configuration structure

The new battery-support policy should be stored explicitly in the optimization configuration file. A recommended structure is:

```json
{
  "power": {
    "solar_flux_w_per_m2": 1361.0,
    "stationkeeping_base_load_w": 15.9,
    "battery_capacity_wh": 30.0,
    "battery_max_discharge_current_a": 1.95,
    "battery_min_soc_after_burn": 0.60,
    "battery_support_voltage_v": 6.2,
    "minimum_solar_array_area_m2": 0.0,
    "solar_array_areal_mass_density_kg_per_m2": 4.0,
    "eta_cell": 0.300,
    "eta_temp": 0.916,
    "eta_rad": 0.9409,
    "eta_mppt": 1.0,
    "eta_wiring": 1.0
  },
  "thermal": {
    "solar_flux_w_per_m2": 1361.0,
    "temperature_requirement_k": 323.0,
    "emissivity_osr": 0.80,
    "absorptivity_osr": 0.08,
    "alpha_sa_front": 0.88,
    "rho_sa_front": 0.12,
    "alpha_sa_back": 0.08,
    "rho_sa_back": 0.92,
    "phi_sa_front": 1.0,
    "phi_sa_back": 0.0,
    "radiator_area_margin_fraction": 0.20
  }
}
```

If a less conservative battery power check is later preferred, only the documented support-voltage assumption needs to be updated without changing the rest of the formulation.

### 7.4. Remaining Quantities To Freeze Before Implementation

The present formulation is now structurally complete, but the following quantities should still be defined explicitly before the Power and Thermal modules are coded:

- whether the Power module will keep the current scaffold inputs `payload_power_w` and `tx_power_w` and reconstruct the station-keeping base load internally, or instead replace them with one fixed station-keeping base-load parameter `P_base,sk`
- `M_eps,fixed`: fixed EPS electronics mass [kg]
- `V_eps,fixed`: fixed EPS electronics packaged volume [U]
- `M_batt,fixed`: fixed battery mass [kg]
- `V_batt,fixed`: fixed battery packaged volume [U]
- `k_sa`: solar-array areal packing coefficient [U/m^2] if solar-array stowed volume is to be modeled
- `eta_dc` or an explicit decision to absorb DC-conversion effects into the battery-support voltage assumption
- whether the conservative battery-support voltage assumption `6.2 V` should remain in place or be replaced by a different bus-support policy
- whether the thermal input should remain the general optimizer variable `temperature_requirement_k` or be frozen directly to `323 K` for the first implementation
- the fixed body-surface areas that accompany the variable solar-array area in the `C_r` model
- whether the first implementation should treat all non-electrical absorbed solar-array power as loading the main spacecraft thermal node, or whether a separate solar-array heat-rejection credit should be introduced later
- whether the Orbit interface will be updated immediately from `effective_reflectivity` to `c_r`, or whether a temporary compatibility conversion will remain in place during the first implementation

---

## 8. Interpretation

The most important modeling consequence of this first Power and Thermal formulation is the following.

Only the subsystem selections, material properties, and battery-policy hyperparameters are fixed in this formulation. The quantities `P_ion`, `P_sk`, `P_diss`, `A_sa`, `A_rad`, and `C_r` remain coupled quantities that must be evaluated inside the MDA loop.

First, the solar array is no longer required to cover the full correction-burn power by itself. Instead, the solar array and battery share the burn load, with the battery support limited by a prescribed post-burn reserve.

Second, because the spacecraft operates near L4 with continuous sunlight, the relevant battery question is not eclipse survival. It is whether the battery can safely support the temporary power deficit during a correction burn and then recharge before the next correction event.

Third, the same station-keeping mode that drives the EPS sizing also drives the thermal hot case, because the internal electrical demand during that mode is the largest dissipated heat load in the current baseline.

Fourth, the finished Orbit module should receive `C_r` directly from Thermal. If the optimizer scaffold still uses `rho_eff`, that is now a naming mismatch rather than the preferred physical formulation.

Finally, the new post-burn SOC requirement is a true system-design hyperparameter. It should be treated as an explicit configuration parameter because it changes the optimizer response: a larger required post-burn reserve forces a larger solar array, while a smaller reserve allows more battery support during the correction burn.
