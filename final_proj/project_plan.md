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