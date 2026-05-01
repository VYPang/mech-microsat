import pyxdsm.XDSM as XDSM

# Initialize the XDSM object
x = XDSM.XDSM()

# 1. Define the Systems (Nodes)
x.add_system('SOL', XDSM.SOLVER, (r'\text{Fixed-Point}', r'\text{Sizing Solver}'))
x.add_system('COM', XDSM.FUNC, r'\text{Comms}')
x.add_system('PWR', XDSM.FUNC, r'\text{Power}')
x.add_system('THM', XDSM.FUNC, r'\text{Thermal}')
x.add_system('ORB', XDSM.FUNC, (r'\text{Orbit SRP}', r'\text{Surrogate}'))
x.add_system('PRP', XDSM.FUNC, r'\text{Propulsion}')
x.add_system('BDG', XDSM.FUNC, (r'\text{6U Budget}', r'\text{Closure}'))

# 2. Define the Forward Connections (Upper Right Triangle)
x.connect('SOL', 'COM', r'R_{L4}, DataRate')
x.connect('SOL', 'PWR', r'P_{payload}')
x.connect('SOL', 'THM', r'T_{req}')
x.connect('SOL', 'BDG', r'M_{payload}, V_{payload}')
x.connect('COM', 'PWR', r'P_{tx}')
x.connect('PWR', 'THM', r'A_{sa}, P_{dissipated}')
x.connect('PWR', 'ORB', r'A_{sa}')
x.connect('THM', 'ORB', r'\rho_{eff}')
x.connect('ORB', 'PRP', r'\Delta V_{avg}')
x.connect('COM', 'BDG', r'M_{com}, V_{com}')
x.connect('PWR', 'BDG', r'M_{pwr}, V_{pwr}')
x.connect('THM', 'BDG', r'M_{thm}, V_{thm}')
x.connect('PRP', 'BDG', r'M_{prop}, V_{prop}')

# 3. Define the Feedback Connections (Lower Left Triangle)
# Power feedback: ion engine electrical draw closes the A_sa <-> P loop.
x.connect('PRP', 'PWR', r'P_{ion}, t_{burn}')
# Mass feedback: SRP acceleration scales as 1/m, so total wet mass enters Orbit.
x.connect('BDG', 'ORB', r'M_{tot}')
# Mass feedback: the rocket equation in Propulsion needs wet mass to size propellant.
x.connect('BDG', 'PRP', r'M_{tot}')

# 4. Define Inputs and Outputs
# Mission requirements and fixed subsystem assumptions define one design-point solve.
x.add_input('SOL', (r'\text{Mission req.}', r'\text{fixed assumptions}'))
# The orbit block uses the precomputed Basilisk-derived SRP response surface online.
x.add_input('ORB', (r'\text{Basilisk SRP}', r'\text{surrogate}'))

# Add external outputs from the Budget
x.add_output('BDG', (r'\text{Converged}', r'\text{design point}'), side='right')

# 5. Show the ordered Gauss-Seidel process used by the sizing solver.
x.add_process(['SOL', 'COM', 'PWR', 'THM', 'ORB', 'PRP', 'BDG', 'SOL'])

# 6. Output Formatting
# Compile the XDSM into a PDF
x.write('sol_sentinel_xdsm', build=True, outdir='final_proj/docs/xdsm')

