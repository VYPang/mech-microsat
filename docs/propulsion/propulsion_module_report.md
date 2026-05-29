# Fixed-Thruster Propulsion Module Formulation and Baseline Thruster Selection

## 1. Introduction

This note documents the first propulsion formulation adopted for the Sol-Sentinel preliminary design framework. The purpose of the propulsion module is not to design a new electric thruster, but to translate the orbit-maintenance demand delivered by the orbit module into the propulsion quantities required by the rest of the system design loop. In the current architecture, propulsion receives the annualized orbit-maintenance burden from the SRP surrogate, combines it with a fixed baseline thruster specification and a small set of mission assumptions, and returns the power, mass, volume, and feasibility quantities needed for conceptual design.

The present note is formulation-focused rather than result-focused. No propulsion trade-study results or optimization campaign outputs are presented here. Instead, the emphasis is on the governing relations, the constraints used to define feasibility, the simplifying assumptions adopted at this stage, and the rationale for selecting the ThrustMe NPT30-I2-1.5U as the baseline propulsion unit.

## 2. Role of the Propulsion Module in the Design Loop

At the system level, the propulsion module sits downstream of the orbit-maintenance model and upstream of the power and budget closures. The orbit module supplies an annualized station-keeping burden,

$$
\Delta V_{avg} \quad [\mathrm{m/s/yr}],
$$

where $\Delta V_{avg}$ is the annualized orbit-maintenance burden predicted by the orbit surrogate. This quantity is interpreted as the maintenance velocity increment required to sustain the selected Sun-Earth L4 reference orbit. The propulsion module combines this quantity with the current total wet spacecraft mass,

$$
M_{tot},
$$

where $M_{tot}$ is the current total wet spacecraft mass carried through the budget loop,

and a fixed thruster specification to determine:

- the propulsion burn power passed to the power subsystem,
- the mission propellant mass carried into the mass budget,
- the propulsion subsystem mass carried into the mass budget,
- the propulsion subsystem volume carried into the volume budget,
- and the burn-duration and total-impulse checks used to evaluate whether the selected thruster can support the required station keeping.

This abstraction is appropriate for the current project stage because the problem is one of existing-engine selection and system-level closure, not detailed electric-thruster design.

## 3. Fixed-Thruster Baseline and Mission Assumptions

The propulsion model is built around a fixed baseline engine, the ThrustMe NPT30-I2-1.5U. For the first implementation, the following single-point values are adopted from the published ranges using the midpoint rule where needed:

$$
F_{thr} = 0.7\ \mathrm{mN},
$$

$$
P_{thr} = 50\ \mathrm{W},
$$

$$
\text{Isp}_{thr} = 2400\ \mathrm{s},
$$

$$
I_{tot,max} = 9500\ \mathrm{N\,s},
$$

$$
V_{prop} = 1.5\ \mathrm{U}.
$$

Here $F_{thr}$ is the nominal thrust of the selected engine during an active correction burn, $P_{thr}$ is the corresponding burn-mode electrical power, $\text{Isp}_{thr}$ is the specific impulse of the selected operating point, $I_{tot,max}$ is the published maximum total impulse capability of the propulsion package, and $V_{prop}$ is the propulsion subsystem packaged volume.

The mission-level assumptions used together with the engine baseline are:

$$
T_{life} = 3\ \mathrm{yr},
$$

$$
\Delta t_{cycle} = 30\ \mathrm{days},
$$

where $T_{life}$ is the propulsion-sizing mission lifetime and $\Delta t_{cycle}$ is the time between planned correction events,

and a delta-V sizing margin of 20%.

The 3-year mission lifetime is chosen to remain consistent with the current SRP surrogate, which was fit from 3-year orbit propagations. The 30-day correction cadence is a simplifying operational assumption that gives a realistic event timescale for a low-thrust EP system without forcing unrealistically frequent corrections in the first conceptual model. The 20% delta-V margin is included because the orbit module currently supplies a drift-proxy maintenance burden rather than the output of a closed-loop guidance and control simulation.

## 4. Input-Output Relation Formulation

### 4.1. Orbit input and delta-V margin

The orbit model provides the annualized maintenance burden

$$
\Delta V_{avg}.
$$

To include a first-pass design margin, the propulsion model defines an effective annual maintenance burden

$$
\Delta V_{eff} = 1.2\,\Delta V_{avg}.
$$

Here $\Delta V_{eff}$ is the effective annual maintenance burden after including the 20% sizing margin. This effective value is used in all downstream propulsion sizing relations.

### 4.2. Per-cycle correction demand

The maintenance demand over one correction interval is

$$
\Delta V_{cycle} = \Delta V_{eff} \cdot \frac{\Delta t_{cycle}}{1\ \mathrm{yr}}.
$$

Here $\Delta V_{cycle}$ is the velocity correction that must be delivered during one correction event.

For the current total wet spacecraft mass, the corresponding impulse required per correction event is

$$
I_{cycle,req} = M_{tot}\,\Delta V_{cycle}.
$$

Here $I_{cycle,req}$ is the impulse required for one correction event.

### 4.3. Burn duration and duty cycle

Because the engine thrust is fixed, the time required to deliver the per-cycle correction is

$$
t_{burn} = \frac{I_{cycle,req}}{F_{thr}} = \frac{M_{tot}\,\Delta V_{cycle}}{F_{thr}}.
$$

Here $t_{burn}$ is the burn duration required to complete one correction event. This is one of the key propulsion feasibility quantities. It determines how long the engine must remain on during a correction event.

The corresponding duty cycle is

$$
\delta = \frac{t_{burn}}{\Delta t_{cycle}},
$$

where $\delta$ measures the fraction of each correction interval during which the engine is firing.

### 4.4. Power sent to the power module

The propulsion electrical load sent to the power subsystem is defined as the burn-mode engine power,

$$
P_{ion} = P_{thr}.
$$

Here $P_{ion}$ is the propulsion power variable passed to the power subsystem.

This is an intentional modeling choice. The propulsion-power output is not a cycle-averaged or yearly averaged power. It is the electrical demand during an active correction burn, because that operating condition is expected to be the relevant one for preliminary EPS sizing.

The cycle-averaged propulsion power,

$$
\bar{P}_{cycle} = \delta P_{thr},
$$

where $\bar{P}_{cycle}$ is the average propulsion power over one correction interval, is still useful as a secondary diagnostic, but it is not the main quantity passed to the power subsystem in the present formulation.

### 4.5. Mission propellant mass

The total station-keeping velocity increment over mission life is

$$
\Delta V_{life} = \Delta V_{eff} T_{life}.
$$

Here $\Delta V_{life}$ is the total station-keeping velocity increment accumulated over the full mission lifetime.

Using the fixed specific impulse, the mission propellant mass is obtained from the rocket equation as

$$
M_{prop} = M_{tot}\left(1 - e^{-\Delta V_{life}/(g_0 \text{Isp}_{thr})}\right).
$$

Here $M_{prop}$ is the mission propellant mass required for orbit maintenance and $g_0$ is standard gravitational acceleration.

Because the current orbit-maintenance delta-V is very small, the small-delta-V approximation is also informative:

$$
M_{prop} \approx M_{tot}\frac{\Delta V_{life}}{g_0 \text{Isp}_{thr}}.
$$

This propellant mass is carried explicitly into the spacecraft total wet-mass budget.

### 4.6. Propulsion mass and volume bookkeeping

The NPT30 publishes a total wet package mass rather than a dry hardware mass. To keep the system-level bookkeeping consistent, the current formulation decomposes the published wet package mass into an inferred hardware mass and an inferred propellant-capacity term.

From the published total impulse capability,

$$
M_{prop,max} = \frac{I_{tot,max}}{g_0 \text{Isp}_{thr}}.
$$

Here $M_{prop,max}$ is the propellant capacity implied by the published total impulse capability of the selected engine package.

The propulsion hardware mass used in the budget model is then approximated as

$$
M_{prop,sys} = M_{wet,published} - M_{prop,max}.
$$

Here $M_{prop,sys}$ is the propulsion subsystem mass carried into the system budget as hardware mass, and $M_{wet,published}$ is the vendor-published wet mass of the full propulsion package.

The propulsion volume is taken directly from the packaged format factor,

$$
V_{prop} = 1.5\ \mathrm{U}.
$$

This mass split is a bookkeeping assumption adopted for optimizer consistency. It should not be interpreted as a vendor-certified dry-mass figure.

## 5. Constraints and Feasibility Conditions

The propulsion formulation defines three main feasibility conditions.

### 5.1. Burn-duration constraint

The correction burn must fit within the adopted correction interval:

$$
t_{burn} \le \Delta t_{cycle}.
$$

This condition is equivalent to requiring the duty cycle to remain below unity.

### 5.2. Total-impulse constraint

The selected engine must be able to deliver the required mission impulse over the mission lifetime:

$$
M_{tot}\,\Delta V_{life} \le I_{tot,max}.
$$

This is the clearest first-pass check that the selected engine has enough total capability for the orbit-maintenance mission.

### 5.3. Burn-power support constraint

The power subsystem must be able to support the engine's burn-mode electrical demand:

$$
P_{available,burn} \ge P_{thr}.
$$

Here $P_{available,burn}$ is the electrical power that the spacecraft can make available during an active correction burn. This condition links the propulsion module back to the power subsystem and is one of the reasons the propulsion power variable is defined as burn-mode power rather than a long-term average.

## 6. Assumptions Adopted in the First Formulation

Several simplifying assumptions are built into the first propulsion model.

First, the propulsion technology is fixed to one existing engine rather than optimized over a thruster catalog. This is adopted for simplicity and project relevance: the real design task is to determine whether a realistic, flight-available EP package can satisfy the station-keeping requirement, not to derive a new engine concept.

Second, a single nominal operating point is used for the selected engine. This avoids introducing a second optimization over throttle state or operating mode before the other subsystem models are complete.

Third, the mission lifetime is fixed to 3 years. This is adopted to remain consistent with the current SRP surrogate, which is itself duration-specific.

Fourth, the correction cadence is fixed to 30 days. This is a practical simplifying assumption that produces a meaningful burn-duration timescale for a low-thrust EP system while keeping the formulation algebraic and transparent.

Fifth, a 20% delta-V margin is added before propulsion sizing. This is adopted because the current orbit-maintenance input is a drift proxy rather than a controller-derived fuel budget.

Sixth, the spacecraft total mass is treated as effectively constant during the mission, even though the required mission propellant is included in the total wet mass. This is adopted because the required station-keeping propellant is expected to be extremely small compared with the spacecraft total wet mass, so the mass variation during the mission is negligible at the current fidelity level.

Seventh, the NPT30 hardware mass is inferred from the published wet mass and total impulse capability because no dry-mass split is presently available in the working data set. This is adopted as a bookkeeping device for optimizer consistency, not as a claim about the exact internal mass allocation of the flight package.

## 7. Why the NPT30-I2-1.5U Is Selected as the Baseline

The ThrustMe NPT30-I2-1.5U is selected as the baseline propulsion unit for four practical reasons.

First, it provides the most complete package-level data among the currently reviewed candidates. For the present formulation, thrust, power, specific impulse, total impulse, packaged size, and total mass are all needed. The NPT30 is the only current candidate for which this set is sufficiently complete to support the full first-pass formulation without inventing additional packaging assumptions.

Second, its power range is well aligned with CubeSat-class EPS sizing. A burn power of roughly 50 W is substantial enough to matter in the system design loop, yet still much more natural for a 12U conceptual design than a 200 W Hall thruster baseline.

Third, its thrust level is in the same micropropulsion class as other CubeSat EP systems such as the BIT-3 and is far better matched to the small orbit-maintenance burden predicted by the current SRP surrogate than a larger Hall thruster intended for much higher impulse levels.

Fourth, its 1.5U integrated packaging makes the mass and volume closure much easier in the first optimization loop. At this stage, that packaging clarity is more valuable than choosing a thruster with a much higher total capability than the present mission appears to require.

For these reasons, the NPT30 is the most suitable first baseline for the propulsion module, while the BIT-3 remains a credible backup candidate and the BHT-200 remains useful as a higher-power reference case rather than as the first optimizer baseline.

## 8. Limitations and Scope

This propulsion formulation is intentionally preliminary. It does not yet optimize across multiple engines, model throttle scheduling explicitly, propagate mass depletion continuously through the orbit model, or enforce all feasibility checks as formal optimizer constraints. Instead, it provides a transparent algebraic bridge between the orbit-maintenance burden and the propulsion quantities needed by the rest of the system-level design loop.

That is the right level of fidelity for the present stage of the project: simple enough to integrate into the multidisciplinary framework, yet detailed enough to connect the orbit-maintenance requirement to real propulsion, power, and budget implications.

## 9. Conclusion

The first Sol-Sentinel propulsion formulation treats propulsion as a fixed-thruster sizing and feasibility problem driven by the annualized orbit-maintenance burden from the SRP surrogate. With a fixed NPT30-I2-1.5U baseline, the formulation converts the orbit input into burn-mode power demand, per-cycle burn duration, mission propellant mass, propulsion subsystem mass, propulsion volume, and basic feasibility checks on burn duration, total impulse, and power support.

The main value of this formulation is not that it produces a final propulsion design, but that it closes the propulsion link in the coupled system design loop using physically interpretable relations and documented simplifying assumptions. It therefore provides a defensible first propulsion model for the broader Sol-Sentinel preliminary design framework.