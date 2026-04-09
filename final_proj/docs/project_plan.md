# ME4890 Final Project Proposal: Project Sol-Sentinel
**Mission:** 12U Space Weather Forecasting CubeSat at Sun-Earth L4  
**Team Size:** 4 Members  
**Form Factor:** 12U CubeSat  

## 1. Mission Overview
The objective of this mission is to design a standalone 12U CubeSat positioned at the Sun-Earth Lagrange 4 (L4) point to serve as an early-warning space weather observatory. By trailing the Sun-Earth line by 60 degrees, the CubeSat will detect Coronal Mass Ejections (CMEs) and solar wind variations days before they impact Earth. 

**Scope Limitation:** To focus deeply on operational orbital dynamics and system design within the 12U constraint, this project assumes the CubeSat has already been successfully injected into the L4 region. The design of the interplanetary transit phase is excluded from this scope.

## 2. Technical Challenges & Feasibility (Marking Criterion #3)
While L4 is dynamically stable (unlike L1/L2), the mission presents several highly coupled engineering challenges:
1.  **Orbital Perturbations:** Because a 12U CubeSat has a low mass-to-area ratio, Solar Radiation Pressure (SRP) acts as a solar sail, pushing the satellite out of the L4 tadpole orbit.
2.  **Deep-Space Communications:** Transmitting early-warning data across 1 Astronomical Unit (1 AU) requires a deployable high-gain antenna and high RF power.
3.  **Thermal Management:** At L4, the spacecraft experiences zero eclipses (constant 100% solar flux). Rejecting the heat from the Sun, the payload, and the high-power transmitter is a critical design driver.

## 3. Iterative Design Methodology (Marking Criterion #4)
Our team will utilize a Concurrent Engineering approach to solve the heavily coupled design constraints. The primary iterative loop will focus on the **SRP-Power-Mass Trade-off**:
*   *Larger solar panels* provide more power for the deep-space transmitter.
*   However, larger panels increase *Solar Radiation Pressure (SRP)*.
*   Increased SRP causes faster orbital drift, requiring a *larger ion propulsion system* and more propellant to maintain station-keeping.
*   More propellant takes up more physical volume, risking a breach of the strict *12U volume limit*. 
*   **Goal:** Iterate these parameters until the mass, power, and volume budgets close successfully.

## 4. Team Structure & Work Division

### Sub-Team 1: Orbital Dynamics & Propulsion (The Platform Team)
**Focus:** Simulating the L4 environment and designing the station-keeping system.

*   **Member A: Dynamicist & Lead Programmer**
    *   Formulate the Circular Restricted Three-Body Problem (CR3BP) equations of motion for the Sun-Earth system.
    *   Develop a custom Python numerical solver (using `scipy.integrate`) to simulate the CubeSat's behavior at L4.
    *   Implement the Solar Radiation Pressure (SRP) perturbation model into the simulation.
    *   *Deliverable:* Python code and graphical plots showing orbital drift over a 2-year lifespan.

*   **Member B: Propulsion Engineer**
    *   Utilize the drift data from Member A to calculate the total $\Delta V$ required for station-keeping over the mission lifetime.
    *   Select an appropriate miniaturized Electric/Ion propulsion system (e.g., electrospray or miniature Hall-effect thruster).
    *   Calculate the required propellant mass and the physical volume ("U" space) of the thruster/tank system.
    *   *Deliverable:* Propulsion system specifications and power requirements to feed into the system budget.

### Sub-Team 2: Systems & Payload (The Operations Team)
**Focus:** Selecting weather forecasting equipment, power, thermal, and maintaining the 12U budget.

*   **Member C: Payload & Communications Engineer**
    *   Select COTS (Commercial Off-The-Shelf) miniaturized space weather instruments (e.g., Solar Magnetometer, EUV Imager) and determine their data output and physical volume.
    *   Design the deep-space Communications Link Budget to transmit data across 1 AU to Earth's Deep Space Network (DSN).
    *   Select a deployable X-Band antenna and calculate the required transmitter power.
    *   *Deliverable:* Payload layout and peak power consumption profile.

*   **Member D: Power, Thermal, and Systems Integrator**
    *   **Power:** Size the solar arrays to handle the massive constant load of the transmitter and ion thruster. (No eclipse battery sizing is required; small batteries will be used only for power conditioning).
    *   **Thermal:** Calculate the heat load (100% solar flux + internal electronics) and size thermal radiators to prevent the CubeSat from overheating.
    *   **Integration:** Maintain the Master Equipment List (MEL). Add up the mass and physical volume of all components from Members A, B, and C to ensure everything fits inside 12U. 
    *   *Deliverable:* Final System Mass/Volume/Power Budgets and iteration tracking.

## 5. Software & Tools
*   **Python:** For numerical integration (CR3BP solver), trajectory plotting, and System Optimization. A detailed analysis of our Multidisciplinary Design Optimization (MDO) library architecture (utilizing Tudatpy, OpenMDAO, and Astropy) can be found in the [library.md](library.md) manual.
*   **MATLAB / Excel:** For Link Budget and Power/Mass Budget tracking.
*   **CAD (Optional):** SolidWorks/Fusion360 to visually demonstrate that the selected components fit within a standard 12U dispenser volume.

## 6. Expected Results & Report Structure (Marking Criteria #1, #2, #5)
1.  **Abstract & Introduction:** Justifying the L4 space weather mission.
2.  **Mission Architecture:** Demonstrating the iterative design loop (Volume vs. Power vs. SRP).
3.  **Results & Analysis (Python):** Graphical evidence of the L4 orbital drift and the $\Delta V$ required to correct it.
4.  **Subsystem Design:** Evidence of COTS component selection (Propulsion, Comms, Payload).
5.  **Conclusion:** Final completed 12U design budgets and evidence of feasibility.
6.  **Appendix:** Full Python code used for simulations.

---

# Project Sol-Sentinel: Systems Architecture & XDSM Formulation

![XDSM Architecture](cubesat_xdsm.png)

## Overview
This document details the Extended Design Structure Matrix (XDSM) formulated for **Project Sol-Sentinel**, a 12U CubeSat designed for space weather forecasting at the Sun-Earth L4 Lagrange point. 

Because deep-space CubeSat design features highly coupled physical constraints, a linear design approach is insufficient. We utilized a **Concurrent Engineering** and Multidisciplinary Design Optimization (MDO) framework. The XDSM visualizes the data flow between sub-teams, highlighting the critical feedback loops required to close the design within a strict 12U / 24kg limit.

---

## 1. XDSM Formulation & Data Flow

The XDSM is divided into three distinct flow categories: the Global Inputs, the Forward Design Cascade, and the Iterative Feedback Loops.

### A. Global Inputs (Mission Requirements)
The **Systems Optimizer** acts as the mission architect. It defines the payload (scientific instruments) and the mission environment, passing static constraints to the subsystems:
*   **To Comms:** Passes $R_{L4}$ (Worst-case distance to Earth) and telemetry $DataRate$.
*   **To Power:** Passes $P_{payload}$ (Constant electrical draw of the instruments).
*   **To Thermal:** Passes $T_{req}$ (Operational temperature limits for the payload).
*   **To Budget:** Deducts $M_{payload}$ and $V_{payload}$ directly from the 12U constraints.

### B. The Forward Design Cascade
Subsystems size their hardware sequentially based on the inputs received:
1.  **Comms $\rightarrow$ Power:** The Comms team uses the Friis Transmission Equation to calculate the required transmitter power ($P_{tx}$) to push a signal across 1 AU, passing this load to the Power team.
2.  **Power $\rightarrow$ Thermal & Orbit:** The Power team sizes the Solar Array Area ($A_{sa}$) to satisfy $P_{tx} + P_{payload}$. $A_{sa}$ is passed to Thermal (for heat load) and Orbit (as a solar sail area).
3.  **Thermal $\rightarrow$ Orbit:** The Thermal team calculates the area-weighted effective reflectivity ($\rho_{eff}$) using the surface area of the solar panels and the chassis coating. This determines how much photon momentum is transferred to the spacecraft.
4.  **Orbit $\rightarrow$ Propulsion:** Using `tudatpy`, the Orbit team simulates the Solar Radiation Pressure (SRP) acting on $A_{sa}$ and $\rho_{eff}$. It calculates the orbital drift out of the L4 deadband and outputs the required station-keeping $\Delta V$.
5.  **Subsystems $\rightarrow$ Budget:** All disciplines pass their respective mass ($M$) and volume ($V$) parameters to the 12U Budget manager.

### C. The Iterative Feedback Loops
The design is driven by two critical feedback loops that force numerical iteration:
1.  **The Physics Loop ($P_{ion}$):** The Propulsion system selects an Ion Engine to provide the necessary $\Delta V$. This engine requires significant electrical power ($P_{ion}$), which is passed *backward* to the Power system. This forces $A_{sa}$ to increase, which increases SRP, which increases $\Delta V$, which increases $P_{ion}$. The system must iterate until this coupled interaction reaches a stable physical baseline.
2.  **The Budget Loop ($M_{tot}, V_{tot}$):** If the converged physical baseline exceeds 24kg or 12U, the Budget manager passes a failure state to the Systems Optimizer. The Optimizer must then downgrade a mission constraint (e.g., lower the $DataRate$ or accept a narrower thermal margin) and trigger a new global iteration.

---

## 2. Assumptions and Limitations

To ensure computational efficiency and scope the project appropriately for the ME4890 constraints, the following assumptions and limitations were implemented in this XDSM formulation:

### Assumption 1: Decoupling of Orbit and Comms ($R_{L4}$ Variation)
While the spacecraft drifts within a $\pm 1^\circ$ deadband around the L4 point, the actual distance to Earth ($R_{L4}$) fluctuates by approximately 2.6 million kilometers. However, we assume $R_{L4}$ is a constant input rather than a dynamic feedback variable from the Orbit node. 
*   *Justification:* A 2.6 million km fluctuation at a 1 AU distance yields a negligible ~0.15 dB variation in Free Space Path Loss. This is easily absorbed by a standard 3.0 dB deep-space link margin. Therefore, the Optimizer passes a static, worst-case $R_{max}$ (e.g., 1.02 AU) to the Comms subsystem to guarantee link closure without creating an unnecessary computational feedback loop.

### Assumption 2: Orbit Insertion is Excluded
The design framework assumes the CubeSat has already been delivered to the L4 vicinity by a rideshare mothership (e.g., an ESPA ring on an interplanetary mission). 
*   *Justification:* Calculating the trans-lunar or interplanetary injection trajectory requires hundreds of meters-per-second of $\Delta V$, which would dominate the entire design and mask the nuanced operational physics of L4 station-keeping.

### Assumption 3: Absence of Eclipses
Because the spacecraft operates at the Sun-Earth L4 point, it is never shadowed by the Earth or the Moon. 
*   *Justification:* Standard LEO battery sizing equations (which rely on orbital period eclipse fractions) are not used. Battery sizing is assumed to be minimal and dictated strictly by power-conditioning requirements (e.g., managing short-term current spikes from the Ion Engine or X-band transmitter).

### Limitation 1: Simplified Thermal Node Analysis
The thermal environment assumes a simplified, isothermal, area-weighted approach to calculate $\rho_{eff}$ and steady-state temperature ($T_{eq}$). We do not employ a full 3D Finite Element Nodal model. Consequently, transient thermal shadowing from deployable antennas or solar arrays is not captured.

### Limitation 2: Impulsive $\Delta V$ Approximation
The `tudatpy` orbital simulation calculates total $\Delta V$ required to maintain the deadband. We assume this $\Delta V$ can be applied impulsively or near-impulsively. In reality, low-thrust ion engines require continuous firing over days, which introduces slight gravity-loss inefficiencies not fully captured in a pure impulsive budget.