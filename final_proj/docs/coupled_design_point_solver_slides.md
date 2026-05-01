# Coupled Design-Point Solver Slide Prep

## 1. Purpose of Project

The project purpose should be presented as preliminary design-point finding for the Sol-Sentinel CubeSat concept at Sun-Earth L4.

The main goal is not to claim a global optimum over a rich spacecraft geometry space. The present models are still low fidelity, several subsystem choices are already fixed, and the structural configuration has not yet been frozen. Instead, the current framework is used to compute one self-consistent spacecraft design point for a selected orbit case and a selected set of subsystem assumptions.

The baseline quantities of interest are:

- total wet mass $M_{tot}$
- total packed volume $V_{tot}$
- solar-array area $A_{sa}$
- effective reflectivity $\rho_{eff}$
- annualized station-keeping burden $\Delta V_{avg}$
- propellant mass $M_{prop}$
- burn duration $t_{burn}$

This framing also leaves room for repeated case studies. The same coupled solver can be rerun for different surrogate cases, such as low-inclination and high-inclination reference orbits, without changing the basic mathematical story.

For the current presentation horizon, it is reasonable to stop at the cannonball-SRP solver story and present higher-fidelity faceted SRP, panel-angle coupling, and transfer-orbit design as clearly labeled future work rather than partially implemented scope.

For slide language, prefer:

- solve
- converge
- compare cases
- sensitivity study
- coupled design-point solver

Avoid using optimization language as the main story unless it is clearly labeled as future work.

---

## 2. Problem Statement

The current problem should be posed as a coupled fixed-point solve rather than an optimization problem.

Given fixed problem data $p$, find the coupled design-point state $x_c$ such that

$$
x_c = G(x_c; p)
$$

or equivalently

$$
R(x_c; p) = x_c - G(x_c; p) = 0
$$

where:

- $p$ contains the fixed mission requirements, subsystem assumptions, selected propulsion package, selected SRP surrogate case, payload bookkeeping terms, and startup seeds
- $G(\cdot)$ denotes one full sweep through the coupled subsystem chain
- $R(\cdot)$ is the closure residual of the coupled system

For slide purposes, a compact state vector can be shown as

$$
x_c =
\begin{bmatrix}
A_{sa} \\
\rho_{eff} \\
\Delta V_{avg} \\
t_{burn} \\
M_{prop} \\
M_{tot}
\end{bmatrix}
$$

This emphasizes the key converged quantities without overwhelming the audience with every internal bookkeeping variable.

For the current implementation, $V_{tot}$ should be presented separately as a reported budget-check output rather than as a true fixed-point unknown. The current equations do compute total packed volume in the Budget block, but that quantity does not feed back into any upstream discipline.

If multiple orbit-surrogate cases are compared, the extension is simply

$$
x_j^\star = \mathrm{Solve}(p_j), \qquad j = 1, \dots, N
$$

where each $p_j$ corresponds to one selected case, for example:

- low-inclination surrogate
- high-inclination surrogate
- future inclination-aware surrogate surface

This is the right place to explain that cross-case comparison is performed by rerunning the same solver, not by turning the present framework back into a high-dimensional optimizer.

Heatmaps involving quantities such as burn separation or battery reserve policy should be framed as sensitivity analysis around the baseline solver, not as the central governing formulation.

---

## 3. Solver

The current framework is best described as a coupled design-point solver using an ordered Gauss-Seidel style multidisciplinary analysis loop.

For one design-point solve, the modules are evaluated in the following order:

1. Comms
2. Power
3. Thermal
4. Orbit
5. Propulsion
6. Budget

After one full sweep, the updated coupled state is compared against the previous coupled state. The convergence measure is

$$
r^{(k)} = \max_i
\frac{\left|x_i^{(k)} - x_i^{(k-1)}\right|}
{\max\left(1, \left|x_i^{(k)}\right|\right)}
$$

and the solve is declared converged when

$$
r^{(k)} \le 10^{-6}
$$

Key solver message for slides:

- the solver takes one selected case and closes the feedback loop between SRP burden, propulsion, power, thermal response, and total spacecraft mass
- the output is one converged design point
- different orbit assumptions are handled by rerunning the same solver with different case data

Important presentation clarification:

- the online solve uses the Orbit SRP surrogate
- Basilisk is used offline to generate the surrogate data set
- the detailed surrogate-generation story should be introduced when presenting the Orbit module slide, not before the online solver flow is established

---

## 4. Description of Each Module Physics Modeling

### Power and Thermal

Primary note: [Fixed-Mode Power and Thermal Formulation](power_thermal/power_thermal_module_formulation.md)

Recommended slide message:

- Power sizes the required solar-array area for station-keeping mode
- Battery support is allowed during the burn, but a post-burn state-of-charge requirement must still be satisfied
- Power passes solar-array area and dissipated power downstream
- Thermal converts dissipated power and assumed optical properties into hot-case heat-rejection metrics and the effective reflectivity passed to Orbit
- Thermal mass and volume are still simplified bookkeeping terms in the present baseline

The important coupling is that solar-array area affects both the power closure and the SRP-sensitive exposed area seen by Orbit.

### Orbit

Primary note: [Solar Radiation Pressure Response Curve and Surrogate Validation](srp_response_curve_result/srp_response_curve_report.md)

Supporting note: [Basilisk Workflow Note](bsk.md)

Recommended slide message:

- The online Orbit block does not propagate Basilisk directly during every solver iteration
- Instead, it evaluates a precomputed surrogate derived from Basilisk SRP runs
- The present surrogate uses a cannonball SRP representation driven mainly by area, reflectivity, and mass
- Its main output to the rest of the system is the annualized station-keeping burden $\Delta V_{avg}$
- This is the correct point in the slide flow to explain how the response curve was generated and how later case comparisons may include low-inclination, high-inclination, or future inclination-aware surrogate cases

Recommended Orbit-slide presentation note:

- show the current SRP response-curve figure from [srp_response_surface.png](srp_response_curve_result/srp_response_surface.png)
- explain that the collapse onto ballistic coefficient is a consequence of the present cannonball SRP model
- state explicitly that, in the current preliminary framework, changing orbit inclination does not produce a large difference in the SRP-maintenance curve because the model does not yet include faceted geometry, attitude-dependent projected area, or a controller-based station-keeping law
- clarify that this does not mean inclination is unimportant physically; rather, it means the current simplified maintenance model is not rich enough to make inclination a strong online design driver
- note that, under the current preliminary framework, inclination is more likely to matter through transfer-orbit delta-v than through the online SRP-maintenance surrogate

### Propulsion

Primary note: [Fixed-Thruster Propulsion Formulation](propulsion/propulsion_fixed_thruster_formulation.md)

Recommended slide message:

- Propulsion is treated as a fixed-thruster sizing bridge, not an engine-design problem
- It converts the orbit-maintenance burden into burn duration, propellant mass, propulsion subsystem mass, propulsion subsystem volume, and propulsion power draw
- This makes Propulsion the bridge between the orbit response and the system-level mass and power closure
- The propulsion package is fixed first, then the solver checks what that package implies for the rest of the spacecraft

### Other Blocks in the Online Solver

For the current presentation, Comms and Budget can be described briefly rather than given full standalone theory slides.

- Comms is currently a fixed-input bookkeeping block that passes transmitter power, mass, and volume into the design-point closure
- Budget closes total wet mass for the feedback loop and also reports total packed volume as a packaging check

---

## 5. Slides Flow Design

The slide flow should follow the online solver sequence. The surrogate-generation explanation should appear when the Orbit module is introduced.

### Recommended Slide-by-Slide Flow

1. **Project Purpose**
   Present the mission context and explain that the current objective is preliminary design-point finding rather than high-dimensional design optimization.

2. **Why a Coupled Design-Point Solver**
   Explain why the current fidelity level supports a solver story better than an optimizer story: fixed subsystem selections, no structural geometry model, and no credible panel-shape sensitivity yet.

3. **Problem Statement**
   Show the high-level formulation
   $$
   x_c = G(x_c; p)
   $$
   and the equivalent residual form
   $$
   R(x_c; p) = 0
   $$
   Then define the main solved quantities in the compact state vector.

4. **XDSM / Solver Architecture**
   Show the updated XDSM and explain that it represents one coupled design-point solve with feedback closure rather than an outer optimization loop.

5. **Power and Thermal Module**
   Introduce the Power and Thermal physics together because they are tightly linked through solar-array area, dissipated power, and optical properties. Show only the detailed equations relevant to this subsystem here.

6. **Orbit Module and SRP Surrogate**
   Introduce the offline Basilisk sweep, the SRP response curve, and the surrogate used inside the online solver. Show [srp_response_surface.png](srp_response_curve_result/srp_response_surface.png) here. Use this slide to explain both the value of the surrogate and the present limitation: the cannonball SRP model collapses strongly onto ballistic coefficient, so low- versus high-inclination differences in maintenance delta-v remain small in the current framework.

7. **Propulsion Module**
   Show how $\Delta V_{avg}$ is converted into burn duration, propellant mass, and propulsion package implications. Present the detailed propulsion equations only on this slide.

8. **Budget Closure and Convergence Logic**
   Explain that the subsystem outputs feed the budget closure, which updates total wet mass for the coupled loop and also reports total packed volume as a bookkeeping output. Show the residual definition and the convergence criterion.

9. **Baseline Converged Design Point**
   Present the baseline solved results: total mass, total volume, solar-array area, reflectivity, annualized delta-v, propellant mass, and burn duration. Make clear that total volume is a reported packaging result, not one of the active feedback unknowns in the present solver.

10. **Case Comparison and Sensitivity Studies**
   Use this slide for low-inclination versus high-inclination comparisons, or for heatmaps and response studies involving selected assumptions such as burn separation or battery reserve policy. Frame these as reruns or sensitivities around the same solver, not as a global optimization campaign. If the low- and high-inclination maintenance results are very similar, say so directly and explain that this is a limitation of the current SRP representation rather than evidence that inclination never matters.

11. **Limitations**
   State the current modelling limits explicitly:
   - no structural geometry model
   - no panel-shape sensitivity in the online solver
   - surrogate based on low-order SRP variables
   - several subsystem choices fixed a priori
   - total packed volume is presently a bookkeeping check rather than a quantity that feeds back into another subsystem model
   - current cannonball SRP model makes inclination weakly visible in maintenance delta-v
   - transfer-orbit delta-v effects of inclination are outside the present preliminary solver and should be stated as future work rather than implied by the current surrogate

12. **Next Steps**
   Present the natural path forward:
   - test high-inclination and additional surrogate cases
   - expand sensitivity analyses
   - add higher-fidelity geometric or structural coupling later
   - add faceted SRP and panel-angle coupling if inclination or geometry is to become a true design variable
   - add transfer-orbit analysis separately if inclination-driven insertion cost is to be compared
   - only reconsider optimization after physically meaningful design variables exist

### Slide-Authoring Guardrails

When another agent or teammate converts this note into slides, the narrative should keep the following discipline:

- describe the framework as a coupled design-point solver
- present repeated low-inc / high-inc runs as case comparison
- present heatmaps as sensitivity studies
- avoid claiming a final optimum or a geometry-driven optimization result
- explain the offline surrogate-generation step only when the Orbit module is introduced
- if inclination appears to have weak effect in the current results, frame that as a model-fidelity limitation, not as a general physical conclusion
