# Faceted SRP, Panel Angle, and Inclination Formulation

## 1. Purpose

This note defines a first faceted Solar Radiation Pressure (SRP) formulation for the Sol-Sentinel sizing framework when the spacecraft geometry is no longer reduced to one cannonball area.

The immediate goal is to make the solar-panel hinge angle a physically meaningful design parameter while keeping the model simple enough to fit into the current coupled design-point solver.

The proposed first-pass geometry is:

`| 2x3U solar panel | 1x3U body | 2x3U solar panel |`

with one symmetric panel deployment angle on each side of the main body.

This note answers three questions:

1. Can we assume the main body always points toward the Sun?
2. Is the intended model the N-plate SRP model?
3. How do panel angle and orbit inclination enter a clear delta-V formulation?

The short answers are:

1. Yes. As a first attitude assumption, we can assume the sun-facing body normal is always aligned with the spacecraft-to-Sun line.
2. Yes. The correct higher-fidelity replacement for the current cannonball model is an N-plate or faceted SRP model.
3. Under perfect sun-pointing, panel angle directly affects both solar power and SRP force, but inclination enters only weakly unless the orbit family, attitude law, or control model is also made more realistic.

---

## 2. Recommended First Attitude Assumption

For a first structured model, assume the spacecraft body frame `B` is always sun-pointing:

$$
\hat{x}_B(t) = \hat{s}(t),
$$

where `\hat{s}(t)` is the unit vector from the spacecraft toward the Sun.

This means:

- the main sun-facing body surface normal always points toward the Sun,
- the panel hinge angle is defined relative to a body frame that is itself tied to the Sun line,
- the panel angle becomes a clean geometric design variable,
- and the power and SRP models use the same incidence geometry.

This is a defensible first assumption because it gives a well-defined coupling between:

- solar-panel incidence angle,
- generated electrical power,
- SRP disturbance,
- orbit-maintenance burden,
- propulsion power demand,
- and total mass/power closure.

However, this assumption has one important consequence:

if the body always sun-points perfectly, then the Sun incidence angles in the body frame are almost constant, so orbit inclination does not strongly change the local SRP force magnitude. In that case, inclination influences delta-V mainly through the orbit dynamics and control burden, not through the plate incidence geometry alone.

---

## 3. Relation to the N-Plate SRP Model

Yes, this is the N-plate SRP model.

Conceptually, the spacecraft is represented as `N` illuminated plates. Each plate has:

- area `A_i`,
- outward unit normal `\hat{n}_i`,
- specular optical coefficient `\rho_{s,i}`,
- diffuse optical coefficient `\rho_{d,i}`,
- and an illumination condition based on the plate normal and Sun direction.

To avoid sign ambiguity, define:

- `\hat{s}(t)` = unit vector from spacecraft to Sun,
- `\mu_i(t) = \max\left(0, \hat{n}_i(t) \cdot \hat{s}(t)\right)` = illuminated projected-area factor,
- `P_\odot(r)` = solar radiation pressure magnitude at heliocentric distance `r`.

Then one clear N-plate SRP acceleration model is

$$
\mathbf{a}_{\mathrm{SRP}}(t)
= -\frac{P_\odot(r(t))}{m_{\mathrm{sat}}}
\sum_{i=1}^{N}
A_i \, \mu_i(t)
\left[
\left(1 - \rho_{s,i}\right) \hat{s}(t)
+ 2\left(\rho_{s,i}\mu_i(t) + \frac{\rho_{d,i}}{3}\right) \hat{n}_i(t)
\right].
$$

This is the same class of faceted SRP model as the equation discussed in the literature image, but written with an explicit projected-area factor `\mu_i` so the illumination condition is easier to read.

The solar-radiation-pressure magnitude is

$$
P_\odot(r) = P_{1\mathrm{AU}}\left(\frac{1\,\mathrm{AU}}{r}\right)^2,
$$

with

$$
P_{1\mathrm{AU}} \approx 4.56 \times 10^{-6}\ \mathrm{N/m^2}.
$$

When the vehicle stays near 1 AU, this term changes only weakly.

---

## 4. First Geometry for Sol-Sentinel

### 4.1. Body frame

Define the spacecraft body frame so that:

- `\hat{x}_B` points from the spacecraft toward the Sun,
- `\hat{y}_B` is along the 3U body long axis,
- `\hat{z}_B` is the left-right panel span axis.

Under perfect sun-pointing,

$$
\hat{s}(t) = \hat{x}_B.
$$

### 4.2. Main body and panel normals

Let the sun-facing main body face have area `A_b` and normal

$$
\hat{n}_b = \hat{x}_B.
$$

Let each deployable panel have front-side illuminated area `A_p` and a symmetric hinge angle `\alpha` about the `\hat{y}_B` axis.

Take the left and right panel normals as

$$
\hat{n}_L = \cos\alpha\,\hat{x}_B + \sin\alpha\,\hat{z}_B,
$$

$$
\hat{n}_R = \cos\alpha\,\hat{x}_B - \sin\alpha\,\hat{z}_B.
$$

For this model,

$$
0 \le \alpha \le \frac{\pi}{2},
$$

where:

- `\alpha = 0` means both panels are flat and fully sun-facing,
- larger `\alpha` reduces projected solar area,
- and `\alpha = \pi/2` means the panel fronts are edge-on to the Sun.

### 4.3. Illumination factors

Because the body is sun-pointing,

$$
\mu_b = \hat{n}_b \cdot \hat{s} = 1,
$$

$$
\mu_L = \hat{n}_L \cdot \hat{s} = \cos\alpha,
$$

$$
\mu_R = \hat{n}_R \cdot \hat{s} = \cos\alpha.
$$

This is the core reason panel angle becomes meaningful immediately.

---

## 5. Solar Power Formulation

If only the two deployable panels are active solar-cell surfaces, then the instantaneous electrical power is

$$
P_{\mathrm{SA}}(t)
= 2\,\eta_{\mathrm{SA}}\,S_\odot(r(t))\,A_p\cos\alpha,
$$

where:

- `\eta_{\mathrm{SA}}` is the effective solar-array conversion efficiency,
- `S_\odot(r)` is the solar flux at heliocentric distance `r`.

If the front body face also carries active cells, then add

$$
\eta_{\mathrm{body}}\,S_\odot(r(t))\,A_b.
$$

Under the sun-pointing assumption, panel angle directly controls available electrical power through `\cos\alpha`.

---

## 6. Faceted SRP Formulation for the 3-Plate Front Geometry

For the first reduced model, consider the three front illuminated surfaces only:

1. the sun-facing body face,
2. the left panel front face,
3. the right panel front face.

The bus side faces, back faces, and panel back faces can be added later if needed.

### 6.1. Body-face contribution

For the main body face, `\mu_b = 1` and `\hat{n}_b = \hat{s}`, so its SRP acceleration contribution is purely along the Sun-spacecraft line:
For the main body face, `\mu_b = 1` and `\hat{n}_b = \hat{s}`, so its SRP acceleration contribution is purely along the Sun-spacecraft line:

$$
\mathbf{a}_b
= -\frac{P_\odot(r)}{m_{\mathrm{sat}}}
A_b
\left[
\left(1 - \rho_{s,b}\right)
+ 2\left(\rho_{s,b} + \frac{\rho_{d,b}}{3}\right)
\right]
\hat{s}.
$$

Define the body optical coefficient lump

$$
C_b = \left(1 - \rho_{s,b}\right) + 2\left(\rho_{s,b} + \frac{\rho_{d,b}}{3}\right),
$$

so that

$$
\mathbf{a}_b = -\frac{P_\odot(r)}{m_{\mathrm{sat}}} A_b C_b \hat{s}.
$$

### 6.2. One panel contribution

For either panel front face,

$$
\mu_p = \cos\alpha.
$$

The SRP contribution of one panel is

$$
\mathbf{a}_p
= -\frac{P_\odot(r)}{m_{\mathrm{sat}}}
A_p \cos\alpha
\left[
\left(1 - \rho_{s,p}\right)\hat{s}
+ 2\left(\rho_{s,p}\cos\alpha + \frac{\rho_{d,p}}{3}\right)\hat{n}_p
\right].
$$

### 6.3. Symmetric left-right pair

Because the left and right panels are symmetric,

- the lateral `\hat{z}_B` components cancel,
- the net SRP acceleration remains along `\hat{s}`.

Therefore the total front-geometry SRP acceleration becomes

$$
\mathbf{a}_{\mathrm{SRP}}(t;\alpha)
= -\frac{P_\odot(r(t))}{m_{\mathrm{sat}}}
\Bigg[
A_b C_b
+ 2A_p \cos\alpha
\left(
\left(1 - \rho_{s,p}\right)
+ 2\left(\rho_{s,p}\cos\alpha + \frac{\rho_{d,p}}{3}\right)\cos\alpha
\right)
\Bigg]
\hat{s}(t).
$$

This is the clearest first-pass analytical result for the proposed geometry.

It shows directly that:

- panel area `A_p` matters,
- panel angle `\alpha` matters,
- optical coefficients matter,
- spacecraft mass matters through `1 / m_{\mathrm{sat}}`,
- and symmetric panel deployment removes lateral SRP components in this simplified case.

---

## 7. Delta-V Proxy Formulation

### 7.1. Current proxy used in this project

The current project does not yet compute closed-loop station-keeping burns from a controller. It uses accumulated non-gravitational drift as a proxy for the required maintenance burden.

Under the faceted model, keep the same definition:

$$
\Delta \mathbf{V}_{\mathrm{SRP}}(T; \alpha, i)
= \int_0^T \mathbf{a}_{\mathrm{SRP}}\left(t; \alpha, i\right)\,dt,
$$

$$
\Delta V_{\mathrm{proxy}}(T; \alpha, i)
= \left\|\Delta \mathbf{V}_{\mathrm{SRP}}(T; \alpha, i)\right\|,
$$

$$
\Delta V_{\mathrm{yr}}(\alpha, i)
= \frac{\Delta V_{\mathrm{proxy}}(T; \alpha, i)}{T / 1\,\mathrm{yr}}.
$$

This is the natural direct replacement for the current cannonball-response quantity.

### 7.2. Better long-term quantity for later work

The more physical maintenance metric is a controller-based station-keeping cost,

$$
\Delta V_{\mathrm{ctrl}}(T; \alpha, i)
= \sum_{k=1}^{N_{\mathrm{burn}}} \left\|\Delta \mathbf{v}_k\right\|,
$$

where the correction sequence is generated by an actual guidance and control rule for the chosen L4 orbit family.

This is the quantity that will make inclination matter more strongly, because different orbit families can have different sensitivity to the same SRP disturbance field.

---

## 8. Where Inclination Enters

This is the key modeling point.

### 8.1. Under perfect sun-pointing, inclination enters weakly in the local plate force

In the model above,

$$
\mu_b = 1,
\qquad
\mu_L = \mu_R = \cos\alpha,
$$

which are independent of inclination.

Therefore, if the spacecraft remains near 1 AU,

$$
P_\odot(r(t;i)) \approx P_{1\mathrm{AU}},
$$

and the local SRP force magnitude is almost independent of orbit inclination `i`.

In other words, under this first attitude assumption,

- panel angle strongly affects SRP and power,
- inclination does not strongly affect local plate incidence geometry.

### 8.2. Inclination can still enter through the orbit dynamics

Even if the local force magnitude is similar, the orbit-maintenance burden can still depend on inclination because the disturbance acts on different orbit families.

The orbit dynamics are conceptually

$$
\dot{x} = f_{\mathrm{L4}}(x; i) + B(x)\,\mathbf{a}_{\mathrm{SRP}}(t; \alpha),
$$

so the same SRP acceleration can map into different long-term orbit drift depending on the selected inclined orbit family and the station-keeping rule.

This is the correct place for inclination dependence in a sun-pointing faceted model.

### 8.3. If you want inclination to become a stronger design variable

Inclination becomes much more visible if at least one of the following is introduced:

1. the spacecraft is not perfectly sun-pointing at all times,
2. the payload requires an off-Sun boresight constraint,
3. panel articulation is limited or scheduled rather than always fixed,
4. different L4 orbit families are truly retuned rather than generated only by a simple initial-velocity tilt,
5. the maintenance metric is controller-based rather than only the integrated SRP acceleration norm.

---

## 9. Recommended First Solver-Ready Formulation

For the first implementation, keep the model deliberately simple.

### 9.1. Proposed design and case inputs

- `panel_area_m2 = A_p`
- `panel_hinge_angle_deg = \alpha`
- `spacecraft_mass_kg = m_{sat}`
- `panel_specular_coeff = \rho_{s,p}`
- `panel_diffuse_coeff = \rho_{d,p}`
- `body_specular_coeff = \rho_{s,b}`
- `body_diffuse_coeff = \rho_{d,b}`
- `orbit_inclination_deg = i` as a case parameter, not necessarily an optimizer variable yet

### 9.2. Proposed orbit/power outputs

- `delta_v_mps_per_year`
- `solar_array_generated_power_w`
- `effective_projected_panel_area_m2 = 2A_p\cos\alpha`
- optionally `srp_accel_equivalent_mps2`

### 9.3. Recommended implementation sequence

1. Replace the current cannonball effective area with a faceted front-geometry model.
2. Assume perfect sun-pointing body attitude.
3. Introduce one symmetric panel angle `\alpha`.
4. Compute both generated power and SRP acceleration from the same geometry.
5. Propagate the orbit and compute `\Delta V_{\mathrm{yr}}` exactly as before.
6. Treat inclination first as a case parameter, not as a free design variable.
7. Only promote inclination to a real design variable after the orbit family and control model are upgraded.

---

## 10. Practical Conclusion

Yes, we can assume that the main body surface normal always points toward the Sun as a first-pass attitude law.

Yes, the right physics model for this is the N-plate faceted SRP model rather than the current cannonball model.

Under that assumption, the panel hinge angle is a very meaningful design parameter because it changes both:

- the solar power input through `\cos\alpha`, and
- the SRP disturbance through the same geometry.

However, if the body is perfectly sun-pointing, orbit inclination will not strongly affect the local plate-force magnitude by itself. Inclination will mainly enter through:

- the selected L4 orbit family,
- the long-term orbital response to SRP,
- and, later, the station-keeping control law.

That means the best immediate next step is:

1. add panel angle to the faceted SRP and power model,
2. keep inclination as a case parameter,
3. and only later upgrade the orbit-family and control model if inclination is to become a strong design variable.