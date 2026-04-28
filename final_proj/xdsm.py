import pyxdsm.XDSM as XDSM

# Initialize the XDSM object
x = XDSM.XDSM()

# 1. Define the Systems (Nodes)
x.add_system('OPT', 'Optimization', r'\text{Systems Optimizer}')
x.add_system('COM', 'Function', r'\text{Comms}')
x.add_system('PWR', 'Function', r'\text{Power}')
x.add_system('THM', 'Function', r'\text{Thermal}')
x.add_system('ORB', 'Function', r'\text{Orbit (Basilisk SRP)}')
x.add_system('PRP', 'Function', r'\text{Propulsion}')
x.add_system('BDG', 'Function', r'\text{12U Budget}')

# 2. Define the Forward Connections (Upper Right Triangle)
x.connect('OPT', 'COM', r'R_{L4}, DataRate')
x.connect('OPT', 'PWR', r'P_{payload}')
x.connect('OPT', 'THM', r'T_{req}')
x.connect('OPT', 'BDG', r'M_{payload}, V_{payload}')
x.connect('COM', 'PWR', r'P_{tx}')
x.connect('PWR', 'THM', r'A_{sa}, P_{dissipated}')
x.connect('PWR', 'ORB', r'A_{sa}')
x.connect('THM', 'ORB', r'C_r')
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
# Propellant mass shifts the ballistic coefficient mid-design, so it is also fed back to Orbit.
x.connect('PRP', 'ORB', r'M_{prop}')
x.connect('BDG', 'OPT', r'M_{tot}, V_{tot}')

# 4. Define Inputs and Outputs
# Add external inputs to the Optimizer
x.add_input('OPT', r'\text{Mission Req}, \text{12U limits}')

# Add external outputs from the Budget
x.add_output('BDG', r'\text{Final Design}', side='right')

# 5. Output Formatting
# Compile the XDSM into a PDF
x.write('sol_sentinel_xdsm', build=True, outdir='final_proj/docs/xdsm')

