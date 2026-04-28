from rich.console import Console
from rich.table import Table
from sgp4.api import Satrec
import math
from datetime import datetime, timedelta

# Input your TLE lines here
TLE_LINE1 = "1 42705U 98067LN  17137.36014421 +.00015120 +00000-0 +23025-3 0  9992"
TLE_LINE2 = "2 42705 051.6392 191.9665 0001959 144.6575 215.4546 15.54715550000127"

def mean_to_true_anomaly(M: float, e: float) -> float:
    """
    Convert Mean Anomaly to True Anomaly.
    Solves Kepler's Equation: M = E - e*sin(E) using Newton-Raphson.
    """
    E = M
    # Iteratively solve for Eccentric Anomaly (E)
    for _ in range(100):
        dE = (E - e * math.sin(E) - M) / (1 - e * math.cos(E))
        E -= dE
        if abs(dE) < 1e-8:
            break
            
    # Solve for True Anomaly (v)
    nu = 2 * math.atan2(math.sqrt(1 + e) * math.sin(E / 2),
                        math.sqrt(1 - e) * math.cos(E / 2))
    
    # Ensure nuance is between 0 and 2*pi
    return (nu + 2 * math.pi) % (2 * math.pi)
def main():
    """
    Parses a Two-Line Element (TLE) set, converts it into Keplerian elements, 
    and translates the epoch into a precise UTC datetime.
    """
    # Initialize Satrec object from SGP4
    sat = Satrec.twoline2rv(TLE_LINE1, TLE_LINE2)
    
    # Standard Earth gravitational parameter (WGS84) in km^3/s^2
    mu = 398600.4418
    
    # Extract Keplerian elements directly from SGP4 object
    e = sat.ecco
    inc = math.degrees(sat.inclo)
    raan = math.degrees(sat.nodeo)
    argp = math.degrees(sat.argpo)
    
    # SGP4 Mean Anomaly comes in radians
    M = sat.mo 
    
    # Convert Mean Anomaly to True Anomaly
    nu = mean_to_true_anomaly(M, e)
    nu_deg = math.degrees(nu)
    
    # Semimajor axis calculation
    # Mean motion (no_kozai) is provided in radians per minute by sgp4
    n_rad_s = sat.no_kozai / 60.0 
    
    if n_rad_s > 0:
        a = (mu / (n_rad_s ** 2)) ** (1/3)
    else:
        a = 0.0
        
    # Epoch parsing
    # TLE stores 2-digit years. Typically < 57 is 2000+, else 1900+
    year = sat.epochyr
    year_full = year + 2000 if year < 57 else year + 1900
    
    # Compute exact datetime from fractional epoch days
    epoch_datetime = datetime(year_full, 1, 1) + timedelta(days=sat.epochdays - 1)
    
    # Setup rich console table
    console = Console()
    table = Table(title="TLE to Keplerian Elements SGP4 Conversion", title_style="bold blue")
    
    table.add_column("Parameter", justify="right", style="cyan", no_wrap=True)
    table.add_column("Value", style="magenta")
    table.add_column("Unit", justify="left", style="green")
    
    table.add_row("Semimajor Axis (a)", f"{a:.3f}", "km")
    table.add_row("Eccentricity (e)", f"{e:.7f}", "-")
    table.add_row("Inclination (i)", f"{inc:.4f}", "deg")
    table.add_row("RAAN (Ω)", f"{raan:.4f}", "deg")
    table.add_row("Argument of Periapsis (ω)", f"{argp:.4f}", "deg")
    table.add_row("Mean Anomaly (M)", f"{math.degrees(M):.4f}", "deg")
    table.add_row("True Anomaly (ν)", f"{nu_deg:.4f}", "deg")
    
    # Spacer row
    table.add_section()
    table.add_row("Epoch (Fractional)", str(sat.epochdays), "days")
    table.add_row("Epoch (UTC Time)", epoch_datetime.strftime("%Y-%m-%d %H:%M:%S.%f")[:-3], "")
    
    console.print(table)

if __name__ == "__main__":
    main()
