# IceCube (Earth-1) CubeSat: Orbital Analysis and MATLAB Simulation Setup

## 1. Introduction
This report details the orbital analysis, power requirement, and disturbance evaluation for the IceCube (Earth-1) CubeSat. IceCube is a 3U CubeSat funded by NASA, designed to demonstrate a commercial 874-GHz submillimeter-wave radiometer for observing atmospheric cloud ice. 

IceCube was launched as cargo aboard the Cygnus OA-7 mission on April 18, 2017, and was successfully deployed into Low Earth Orbit (LEO) from the International Space Station (ISS) on May 16, 2017. Because it was deployed directly from the ISS, the United States Space Surveillance Network catalogs IceCube under the parent launch of the ISS (1998), assigning it the International Designator 1998-067LN and the NORAD Catalog ID 42705 [1]. 

## 2. Baseline Orbital Parameters (TLE)
To conduct accurate simulations for the MATLAB CubeSat toolbox (Tasks 1–3) and GMAT (Task 4), it is necessary to establish the satellite's initial orbit prior to significant atmospheric degradation. The baseline orbital parameters for this report are derived from the earliest available Two-Line Element (TLE) set acquired from the Space-Track.org database, with an epoch of May 17, 2017 (one day post-deployment) [1]. 

The baseline TLE used for this analysis is as follows:

```text
1 42705U 98067LN  17137.36014421 +.00015120 +00000-0 +23025-3 0  9992
2 42705 051.6392 191.9665 0001959 144.6575 215.4546 15.54715550000127
```

## 3. Extracted Keplerian Elements
To properly extract the Keplerian elements from the baseline TLE, the Simplified General Perturbations No. 4 (SGP4) mathematical model was utilized [2]. The SGP4 propagator is the standard algorithm designated to evaluate Two-Line Elements by taking into account secular and periodic orbital perturbations, such as Earth's oblateness (J2, J3, J4 harmonics), atmospheric drag, and third-body gravitational effects. Using a Python-based SGP4 implementation, the implicit Keplerian parameters were parsed, and Kepler's equation was iteratively solved using Newton-Raphson approximation to convert the SGP4 Mean Anomaly to True Anomaly.

The following initial Keplerian orbital elements required for the MATLAB simulation environment were extracted:

* **Semi-Major Axis (*a*):** 6781.117 km
* **Eccentricity (*e*):** 0.0001959 (Nearly circular)
* **Inclination (*i*):** 51.6392°
* **Right Ascension of the Ascending Node (*RAAN* / *Ω*):** 191.9665°
* **Argument of Perigee (*ω*):** 144.6575°
* **Mean Anomaly (*M*):** 215.4546°
* **True Anomaly (*ν*):** 215.4416°

Based on the semimajor axis of 6781.117 km (and an Earth radius of ~6371 km), the mean altitude is approximately **410 km** Above Mean Sea Level (AMSL). This perfectly aligns with typical deployment altitudes from the ISS.

## 4. Epoch Time Conversion
The TLE epoch defines the exact date and time of the measurement, which is required for the MATLAB solar radiation and eclipse calculations. The epoch from Line 1 is `17137.36014421`. 

**Decoding the Epoch:**
* **17:** The two-digit year (2017).
* **137:** The 137th day of the year (May 17).
* **.36014421:** The fractional portion of the day. 
  * Hours: 0.36014421 × 24 = 8.64345 (8 Hours)
  * Minutes: 0.64345 × 60 = 38.607 (38 Minutes)
  * Seconds: 0.607 × 60 = 36.459 (36.459 Seconds)

Therefore, the exact UTC Epoch time is **May 17, 2017, at 08:38:36.459 UTC**.

## 5. Power Requirements
According to [1], the spacecraft bus of IceCube was a 3U customised CubeSat. The EPS (Electrical Power Subsystem) consisted of two 3U double deployable solar arrays - which produced 30 W at BOL (Beginning of Life) - and a 2U body-mounted array for power generation. A 40 Wh battery was used during eclipse operations. The battery system of the IceCube CubeSat is evaluated with a maximum Depth of Discharge (DoD) of 35% [3]. Since there is no public data detailing the exact solar panel efficiency for the IceCube CubeSat, we reference the NASA state-of-the-art report for small spacecraft technology and assume an efficiency of 29% calculations [4]. According to the same technical report, the power conversion efficiency is typically 0.8.

## 6. References
[1] Space-Track.org, "Historical Two-Line Element Sets for NORAD ID 42705 (1998-067LN)," United States Space Command / 18th Space Defense Squadron. [Online]. Available: https://www.space-track.org. [Accessed: *Insert Today's Date*].

[2] D. Vallado, P. Crawford, R. Hujsak, and T. S. Kelso, "Revisiting Spacetrack Report #3," in *AIAA/AAS Astrodynamics Specialist Conference and Exhibit*, Keystone, Colorado, Aug. 2006.

[3] J. Esper, D. Wu, B. Abresch, B. Flaherty, C. Purdy, J. Hudeck, J. Rodriguez, and T. Daisey, "NASA IceCube: CubeSat demonstration of a commercial 883-GHz cloud radiometer," 2018.

[4] "State of the art: Small spacecraft technology," Tech. Rep. ARC-E-DAA-TN58827, Dec. 2018.