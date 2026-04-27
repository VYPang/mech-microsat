# Candidate Electric Propulsion Systems

## 1. Purpose

This note records the three candidate electric-propulsion systems currently under consideration for the first Sol-Sentinel propulsion model.

It also identifies which published specifications are required by the fixed-thruster propulsion formulation in `final_proj/docs/propulsion_fixed_thruster_formulation.md`.

The three current candidates are:

1. ThrustMe NPT30-I2-1.5U
2. Busek BIT-3
3. Busek BHT-200

---

## 2. Which published engine specs matter to the formulation?

The fixed-thruster propulsion formulation needs the following engine-side inputs.

| Required formulation input | Meaning | Why it is needed |
|---|---|---|
| `F_thr` | Nominal thrust during burn | Converts per-cycle impulse demand into burn duration |
| `P_thr` | Nominal electrical power during burn | Passed into the Power module as `propulsion_power_w` |
| `Isp_thr` | Nominal specific impulse | Converts total mission delta-V into propellant mass |
| `M_prop_sys` | Propulsion subsystem mass | Sent to Budget as `propulsion_mass_kg` |
| `V_prop_sys` | Propulsion subsystem packed volume | Sent to Budget as `propulsion_volume_u` |
| `I_tot_max` | Maximum available total impulse | Used for mission feasibility screening when published |

Secondary useful information:

| Secondary spec | Use |
|---|---|
| mass type (dry or wet) | Needed to avoid double-counting propellant mass |
| package dimensions / form factor | Needed to estimate packed volume in U |
| thrust vector accuracy | Useful for pointing / control discussion, not currently needed in the first optimizer equations |
| throttle range | Allows choosing a nominal operating point instead of a single fixed point |

Project rule for ranged specs:

- If a range is published and the first model needs a single number, use the midpoint of the published range unless a different nominal operating point is selected explicitly.

---

## 3. Candidate engine summary

### 3.1. ThrustMe NPT30-I2-1.5U

Source: user-provided datasheet summary based on the ThrustMe NPT30-I2-1.5U specification.

| Published specification | Value |
|---|---|
| Thrust | 0.3 to 1.1 mN |
| Total impulse | up to 9500 N s |
| Specific impulse | up to 2400 s |
| Format factor | 1.5U |
| Dimensions | 93 x 93 x 155 mm |
| Total wet mass | 1.7 kg |
| Total power | 35 to 65 W |
| Thrust vector accuracy | < 1 deg |

Inputs available directly to the formulation:

- `F_thr`: yes, from the thrust range
- `P_thr`: yes, from the power range
- `Isp_thr`: yes
- `M_prop_sys`: partially; published mass is total wet mass, so the dry/wet bookkeeping convention must be chosen
- `V_prop_sys`: yes, from 1.5U format or physical dimensions
- `I_tot_max`: yes

Default single-point values if the midpoint rule is used:

- nominal thrust: 0.7 mN
- nominal power: 50 W

Strengths for this project:

- explicitly packaged for CubeSat scale
- integrated format factor already given in U
- low enough power range to fit the current 12U conceptual-design problem
- iodine storage avoids high-pressure tanking complexity
- strongest currently available packaging data of the three candidates

Main caution:

- published mass is total wet mass, so the propulsion-model mass convention must be documented carefully if mission propellant is also modeled separately

---

### 3.2. Busek BIT-3

Source: public Busek BIT-3 product page.

| Published specification | Value |
|---|---|
| System power | 56 to 75 W |
| Thrust | up to 1.1 mN |
| Specific impulse | up to 2150 s |
| System dry mass | 1.40 kg with gimbal |
| Delta-V statement | up to 2.39 km/s for a 14 kg CubeSat |
| Propellant note | iodine-compatible RF ion system |

Inputs available directly to the formulation:

- `F_thr`: yes
- `P_thr`: yes
- `Isp_thr`: yes
- `M_prop_sys`: yes, dry mass is published
- `V_prop_sys`: not explicitly available in the accessible public summary
- `I_tot_max`: not explicitly available in the accessible public summary

Default single-point value if the midpoint rule is applied to power:

- nominal power: 65.5 W

Strengths for this project:

- CubeSat-relevant power range
- iodine-compatible
- dry mass is published directly, which simplifies optimizer bookkeeping
- performance level is close to the NPT30 class

Main cautions:

- package volume is not available in the accessible summary
- no directly published total impulse value was recovered from the public summary used here

---

### 3.3. Busek BHT-200

Source: public Busek BHT-200 product page.

| Published specification | Value |
|---|---|
| Discharge power | 200 W |
| Thrust | 13 mN |
| Specific impulse | 1390 s |
| Demonstrated impulse | 74.88 kN s |
| Predicted total impulse | > 140 kN s |
| Propellant note | iodine-compatible versions have been delivered |

Inputs available directly to the formulation:

- `F_thr`: yes
- `P_thr`: yes
- `Isp_thr`: yes
- `M_prop_sys`: not explicitly available in the accessible public summary
- `V_prop_sys`: not explicitly available in the accessible public summary
- `I_tot_max`: yes

Strengths for this project:

- very mature thruster with strong flight heritage
- total impulse capability is far above the current station-keeping requirement

Main cautions:

- 200 W operating power is much larger than the other two candidates and would strongly drive EPS sizing
- thrust level is far larger than the currently estimated orbit-maintenance need, so it is likely oversized for the first 12U conceptual-design loop
- package mass and volume were not available in the accessible public summary used here

---

## 4. Recommended first baseline candidate

Given the currently available published information, the most suitable first baseline candidate for the optimization framework is:

## ThrustMe NPT30-I2-1.5U

Reason for selection:

1. It is the most complete package-level candidate among the three for the current formulation: thrust, power, specific impulse, total impulse, dimensions, form factor, and total wet mass are all available.
2. Its 35 to 65 W power range is consistent with CubeSat-class EPS sizing and is much easier to integrate into the current 12U conceptual design than a 200 W Hall thruster.
3. Its 0.3 to 1.1 mN thrust range is in the same micropropulsion class as BIT-3, which is more appropriate for the very small orbit-maintenance burden currently predicted by the SRP surrogate.
4. Its 1.5U packaging is directly usable in the optimizer without inventing a volume estimate from incomplete public data.
5. It reflects the actual project need more closely: selecting a realistic packaged propulsion option, not designing a custom engine from scratch.

The BIT-3 remains a strong backup option because it publishes dry mass clearly and has a very similar thrust / power class. The BHT-200 is useful as a higher-power comparison case but is not the best first baseline for this optimizer loop.

---

## 5. Data mapping for the first NPT30 baseline

If the midpoint rule is used for ranged specs, the first fixed-thruster model can use:

| Formulation variable | Initial baseline value |
|---|---|
| `F_thr` | 0.7 mN |
| `P_thr` | 50 W |
| `Isp_thr` | 2400 s |
| `M_prop_sys` | 1.7 kg total wet package, pending final bookkeeping convention |
| `V_prop_sys` | 1.5U |
| `I_tot_max` | 9500 N s |

Open bookkeeping item:

- Because the published NPT30 mass is total wet mass, the project must decide whether the mission propellant mass computed from the rocket equation is already embedded in the 1.7 kg package, or whether the 1.7 kg figure should be decomposed into hardware mass plus carried propellant for optimizer consistency.

Until a better split is available, that 1.7 kg number should be treated explicitly as a simplifying assumption rather than as a precise dry-mass value.