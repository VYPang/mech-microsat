# Selected Libraries Manual

## Table of Contents
- [1. Tudatpy: Orbital Dynamics & 3-Body Problem](#1-tudatpy-orbital-dynamics--3-body-problem)
- [2. OpenMDAO: System Optimization](#2-openmdao-system-optimization-wrapping-tudatpy)
- [3. Astropy: Role & Necessity](#3-astropy-role--necessity)

## 1. Tudatpy: Orbital Dynamics & 3-Body Problem

Is `tudatpy` suitable for the 3-body problem to compute the orbit in sun-earth L4 and calculate propulsion forces required to keep the cubesat in position?

Yes, tudatpy is well-suited for this problem. It has dedicated support for both the Circular Restricted Three-Body Problem (CR3BP) and full N-body dynamics with thrust modeling. Here's how the relevant capabilities map to your needs:

## 1. Three-Body Problem & Lagrange Point Support

Tudat has a dedicated `circular_restricted_three_body_problem` namespace with a `LibrationPoint` class that can compute the location of all five Lagrange points (L1–L5), including L4: [1](#0-0) 

The L4 location computation is tested and verified against reference values: [2](#0-1) 

There is also a dedicated CR3BP state derivative model for propagating orbits in the rotating frame: [3](#0-2) 

## 2. Full Dynamics Propagation (Recommended Approach)

For a realistic station-keeping analysis, you'd likely want the **full dynamics** propagation rather than the idealized CR3BP. Tudat provides helper functions to set up both and compare them side-by-side: [4](#0-3) [5](#0-4) 

In the full dynamics approach, you set up point-mass (or higher-fidelity) gravitational accelerations from both the Sun and Earth acting on your CubeSat, plus any other perturbations (solar radiation pressure, third-body gravity from the Moon/Jupiter, etc.). [6](#0-5) [7](#0-6) 

## 3. Thrust / Station-Keeping Force Modeling

Tudat has a comprehensive thrust acceleration framework. You can model your station-keeping propulsion using:

- **Constant thrust**: `ConstantThrustMagnitudeWrapper` for a fixed thrust level [8](#0-7) 

- **Custom thrust as a function of time/state**: `CustomThrustMagnitudeWrapper` for a guidance law [9](#0-8) 

- **Engine-based thrust** with configurable direction and magnitude guidance, including mass consumption tracking: [10](#0-9) 

The Python bindings expose these as `thrust_from_all_engines`, `thrust_from_engine`, etc.: [11](#0-10) 

You can also use `custom_acceleration` to define any arbitrary force function: [12](#0-11) 

## Suggested Approach

A practical workflow for your problem would be:

1. **Compute the Sun-Earth L4 position** using the `LibrationPoint` class with `LagrangeLibrationPoints::l4`.
2. **Set up a full-dynamics propagation** with Sun and Earth point-mass gravity (and optionally Moon, Jupiter, SRP) acting on your CubeSat, initialized near L4.
3. **Propagate without thrust** first to observe the natural drift (L4 is linearly stable for the Sun-Earth system, but perturbations from other bodies cause drift).
4. **Add a thrust acceleration** (constant, custom, or feedback-based) and iterate on the thrust magnitude/direction to maintain position within a desired tolerance around L4.
5. **Track propellant consumption** via the coupled mass propagation to determine delta-V and fuel budget.

One important clarification: the Sun-Earth L4 point is actually **linearly stable** (unlike L1, L2, L3), so a CubeSat placed there with the right initial conditions would naturally remain in a tadpole orbit around L4 without propulsion. The station-keeping budget depends on how tightly you want to stay near L4 and what perturbations (other planets, SRP, etc.) you include in your model. Tudat can model all of these.

### Citations

**File:** include/tudat/astro/gravitation/librationPoint.h (L51-55)
```text
class LibrationPoint
{
public:
    //! Lagrange libration points.
    enum LagrangeLibrationPoints { l1, l2, l3, l4, l5 };
```

**File:** tests/test_tudat/src/astro/gravitation/unitTestLibrationPoints.cpp (L147-169)
```cpp
BOOST_AUTO_TEST_CASE( testComputationOfLocationOfL4LibrationPoint )
{
    // Declare and initialize Earth-Moon mass parameter from (Mireles James, 2006).
    const double earthMoonMassParameter = 0.012277471;

    // Set expected location of L4.
    const Eigen::Vector3d expectedLocationOfL4( 0.487722529, 0.86602540378444, 0.0 );

    // Declare L4 libration point object with Earth-Moon mass parameter and Newton-Raphson method
    // with 1000 iterations as maximum and 1.0e-14 relative X-tolerance.
    circular_restricted_three_body_problem::LibrationPoint librationPointL4( earthMoonMassParameter,
                                                                             std::make_shared< NewtonRaphson<> >( 1.0e-14, 1000 ) );

    // Compute location of Lagrange libration point.
    librationPointL4.computeLocationOfLibrationPoint( circular_restricted_three_body_problem::LibrationPoint::l4 );

    // Determine location of libration point in Earth-Moon system.
    const Eigen::Vector3d positionOflibrationPointL4 = librationPointL4.getLocationOfLagrangeLibrationPoint( );

    // Check if computed location of L4 matches expected location.
    BOOST_CHECK_CLOSE_FRACTION( expectedLocationOfL4.x( ), positionOflibrationPointL4.x( ), 1.0e-15 );
    BOOST_CHECK_CLOSE_FRACTION( expectedLocationOfL4.y( ), positionOflibrationPointL4.y( ), 1.0e-14 );
    BOOST_CHECK_SMALL( positionOflibrationPointL4.z( ), std::numeric_limits< double >::min( ) );
```

**File:** include/tudat/astro/propagators/stateDerivativeCircularRestrictedThreeBodyProblem.h (L32-58)
```text
class StateDerivativeCircularRestrictedThreeBodyProblem
{
public:
    //! Default constructor.
    /*!
     * Default constructor that defines the state derivative for a given CRTBP system.
     * \param aMassParameter A value for mass parameter of CRTBP.
     */
    StateDerivativeCircularRestrictedThreeBodyProblem( const double aMassParameter ): massParameter( aMassParameter ) { }

    //! Compute state derivative.
    /*!
     * Computes the state derivative of CRTBP.
     * \param time Time.
     * \param cartesianState Cartesian state.
     * \return State derivative.
     */
    Eigen::Vector6d computeStateDerivative( const double time, const Eigen::Vector6d& cartesianState );

protected:
private:
    //! Mass parameter.
    /*!
     * Value of mass parameter for the CRTBP.
     */
    double massParameter;
};
```

**File:** include/tudat/simulation/propagation_setup/propagationCR3BPFullProblem.h (L22-49)
```text
simulation_setup::BodyListSettings setupBodySettingsCR3BP( const double distancePrimarySecondary,
                                                           const std::string& namePrimaryBody,
                                                           const std::string& nameSecondaryBody,
                                                           const std::string& frameOrientation = "ECLIPJ2000",
                                                           const double primaryGravitationalParameter = TUDAT_NAN,
                                                           const double secondaryGravitationalParameter = TUDAT_NAN );

//! Setup CR3BP system of bodies.
/*!
 * Setup CR3BP system of bodies. The two primaries, as well as the third, smaller body to be propagated are defined in the system of bodies.
 * The two primaries are in circular orbit about their barycenter, orbiting it with the same mean motion, so that they stay
 * aligned during propagation.
 * \param distancePrimarySecondary Distance between primaries    [m].
 * \param namePrimaryBody Name of the primary body.
 * \param nameSecondaryBody Name of the secondary body.
 * \param nameBodyToPropagate Name of the third, smaller body to be propagated.
 * \param frameOrientation Orientation of frame in which to propagate
 * \param primaryGravitationalParameter Gravitational parameter of primary
 * \param secondaryGravitationalParameter Gravitational parameter of secondary
 * \return Body Map modelling the CR3BP.
 */
simulation_setup::SystemOfBodies setupBodyMapCR3BP( const double distancePrimarySecondary,
                                                    const std::string& namePrimaryBody,
                                                    const std::string& nameSecondaryBody,
                                                    const std::string& nameBodyToPropagate,
                                                    const std::string& frameOrientation = "ECLIPJ2000",
                                                    const double primaryGravitationalParameter = TUDAT_NAN,
                                                    const double secondaryGravitationalParameter = TUDAT_NAN );
```

**File:** include/tudat/simulation/propagation_setup/propagationCR3BPFullProblem.h (L90-98)
```text
void propagateCR3BPAndFullDynamicsProblem(
        const double initialTime,
        const std::shared_ptr< numerical_integrators::IntegratorSettings< double > > integratorSettings,
        const std::shared_ptr< propagators::TranslationalStatePropagatorSettings< double > > propagatorSettings,
        const simulation_setup::SystemOfBodies& bodies,
        const std::vector< std::string >& bodiesCR3BP,
        std::map< double, Eigen::Vector6d >& directPropagationResult,
        std::map< double, Eigen::Vector6d >& cr3bpPropagationResult,
        std::map< double, Eigen::VectorXd >& dependentVariableValues );
```

**File:** include/tudat/simulation/propagation_setup/createAccelerationModels.h (L57-64)
```text
std::shared_ptr< basic_astrodynamics::AccelerationModel< Eigen::Vector3d > > createDirectGravitationalAcceleration(
        const std::shared_ptr< Body > bodyUndergoingAcceleration,
        const std::shared_ptr< Body > bodyExertingAcceleration,
        const std::string& nameOfBodyUndergoingAcceleration,
        const std::string& nameOfBodyExertingAcceleration,
        const std::shared_ptr< AccelerationSettings > accelerationSettings,
        const std::string& nameOfCentralBody = "",
        const bool isCentralBody = 0 );
```

**File:** include/tudat/simulation/propagation_setup/createAccelerationModels.h (L80-87)
```text
std::shared_ptr< basic_astrodynamics::AccelerationModel< Eigen::Vector3d > > createThirdBodyGravitationalAcceleration(
        const std::shared_ptr< Body > bodyUndergoingAcceleration,
        const std::shared_ptr< Body > bodyExertingAcceleration,
        const std::shared_ptr< Body > centralBody,
        const std::string& nameOfBodyUndergoingAcceleration,
        const std::string& nameOfBodyExertingAcceleration,
        const std::string& nameOfCentralBody,
        const std::shared_ptr< AccelerationSettings > accelerationSettings );
```

**File:** include/tudat/astro/propulsion/thrustMagnitudeWrapper.h (L94-101)
```text
class ConstantThrustMagnitudeWrapper : public ThrustMagnitudeWrapper
{
public:
    ConstantThrustMagnitudeWrapper( const double thrustMagnitude, const double specificImpulse ):
        thrustMagnitude_( thrustMagnitude ), specificImpulse_( specificImpulse )
    {
        massRate_ = computePropellantMassRateFromSpecificImpulse( thrustMagnitude_, specificImpulse_ );
    }
```

**File:** include/tudat/astro/propulsion/thrustMagnitudeWrapper.h (L186-207)
```text
class CustomThrustMagnitudeWrapper : public ThrustMagnitudeWrapper
{
public:
    //! Constructor
    /*!
     * Constructor
     * \param thrustMagnitudeFunction Function returning thrust as a function of time.
     * \param specificImpulseFunction Function returning specific impulse as a function of time.
     * \param isEngineOnFunction Function returning whether the function is on (returns true if so) at a given time.
     * \param customThrustResetFunction Custom function that is to be called when signalling that a new time step is
     * being started (empty by default)
     */
    CustomThrustMagnitudeWrapper( const std::function< double( const double ) > thrustMagnitudeFunction,
                                  const std::function< double( const double ) > specificImpulseFunction ):
        thrustMagnitudeFunction_( thrustMagnitudeFunction ), specificImpulseFunction_( specificImpulseFunction ),
        currentThrustMagnitude_( TUDAT_NAN ), currentSpecificImpulse_( TUDAT_NAN ), isSpecificImpulseConstant_( false )
    { }

    CustomThrustMagnitudeWrapper( const std::function< double( const double ) > thrustMagnitudeFunction, const double specificImpulse ):
        thrustMagnitudeFunction_( thrustMagnitudeFunction ), specificImpulseFunction_( [ = ]( const double ) { return specificImpulse; } ),
        currentThrustMagnitude_( TUDAT_NAN ), currentSpecificImpulse_( TUDAT_NAN ), isSpecificImpulseConstant_( true )
    { }
```

**File:** include/tudat/astro/propulsion/thrustAccelerationModel.h (L48-78)
```text
//! Class used for computing an acceleration due to a continuous thrust.
/*!
 *  Class used for computing an acceleration due to a continuous thrust. The thrust magnitude and direction (in the
 *  propagation frame) are retrieved from separate functions provided by tye user.
 */
class ThrustAcceleration : public basic_astrodynamics::AccelerationModel< Eigen::Vector3d >
{
public:
    /*!
     * Constructor.
     * \param thrustMagnitudeFunction Function returning the current magnitude of the thrust. Any dependencies of the
     * thrust on (in)dependent variables is to be handled by the thrustUpdateFunction.
     * \param inertialThrustDirectionFunction Function returning the direction of the thrust (as a unit vector).
     * Any dependencies of the thrust on (in)dependent variables is to be handled by the thrustUpdateFunction.
     * \param bodyMassFunction Function returning the current mass of the body being propagated.
     * \param massRateFunction Function returning total propellant mass rate from the thrust system.
     * \param associatedThrustSource ID associated with the source of the thrust (i.e. engine name).
     * \param thrustUpdateFunction Function used to update the thrust magnitude and direction to current time (default empty)
     * \param timeResetFunction Function to reset the time in the classes to which the thrustUpdateFunction function directs,
     * default empty.
     * \param requiredModelUpdates List of environment models that are to be updated before computing the acceleration,
     * list is included here to account for versatility of dependencies of thrust model (guidance) algorithms. Default empty.
     */
    ThrustAcceleration( const std::vector< std::shared_ptr< system_models::EngineModel > > thrustSources,
                        const std::shared_ptr< ThrustDirectionCalculator > thrustDirectionWrapper,
                        const std::function< double( ) > bodyMassFunction,
                        const std::map< propagators::EnvironmentModelsToUpdate, std::vector< std::string > >& requiredModelUpdates =
                                std::map< propagators::EnvironmentModelsToUpdate, std::vector< std::string > >( ) ):
        AccelerationModel< Eigen::Vector3d >( ), thrustSources_( thrustSources ), thrustDirectionCalculator_( thrustDirectionWrapper ),
        bodyMassFunction_( bodyMassFunction ), requiredModelUpdates_( requiredModelUpdates ), saveThrustContributions_( false )
    { }
```

**File:** src/tudatpy/dynamics/propagation_setup/acceleration/expose_acceleration.cpp (L1391-1410)
```cpp
    m.def( "thrust_from_all_engines",
           &tss::thrustAccelerationFromAllEngines,
           R"doc(

 Creates settings for thrust acceleration using a single engine models.

 Creates settings for thrust acceleration by combining thrust from all engines defined in the body. See the `user guide <https://docs.tudat.space/en/latest/_src_user_guide/state_propagation/propagation_setup/translational/thrust_models.html>`_
 for more details on the definition of a thrust model in Tudat.

 Returns
 -------
 ThrustAccelerationSettings
     Thrust acceleration settings object.






     )doc" );
```

**File:** include/tudat/simulation/propagation_setup/accelerationSettings.h (L586-617)
```text
//! @get_docstring(CustomAccelerationSettings.__docstring__)
class CustomAccelerationSettings : public AccelerationSettings
{
public:
    CustomAccelerationSettings( const std::function< Eigen::Vector3d( const double ) > accelerationFunction ):
        AccelerationSettings( basic_astrodynamics::custom_acceleration ), accelerationFunction_( accelerationFunction )
    { }

    CustomAccelerationSettings( const std::function< Eigen::Vector3d( const double ) > accelerationFunction,
                                const std::function< double( const double ) > scalingFunction ):
        AccelerationSettings( basic_astrodynamics::custom_acceleration ),
        accelerationFunction_(
                std::bind( &applyAccelerationScalingFunction, accelerationFunction, scalingFunction, std::placeholders::_1 ) )
    { }

    std::function< Eigen::Vector3d( const double ) > accelerationFunction_;
};

//! @get_docstring(customAccelerationSettings)
inline std::shared_ptr< AccelerationSettings > customAccelerationSettings(
        const std::function< Eigen::Vector3d( const double ) > accelerationFunction,
        const std::function< double( const double ) > scalingFunction = nullptr )
{
    if( scalingFunction == nullptr )
    {
        return std::make_shared< CustomAccelerationSettings >( accelerationFunction );
    }
    else
    {
        return std::make_shared< CustomAccelerationSettings >( accelerationFunction, scalingFunction );
    }
}
```
## 2. OpenMDAO: System Optimization Wrapping Tudatpy
I am trying to design a cubesat on sun-earth L4 orbit. I found out that the 3 body station keeping problem can be computed through tudatpy library. I think I would need to take initial guess of engine mass and also with spec required to deduce thermal control, communication and hence battery size and solar panel size as payload mass. These would then be passed into tudatpy to see how much delta v is required to keep the satellite in orbit. Can I combine this repo with using tudatpy repo for orbit simulation?

Yes, you can combine OpenMDAO with tudatpy. OpenMDAO is specifically designed as a multidisciplinary design, analysis, and optimization (MDAO) framework that lets you couple different discipline analyses together — exactly the kind of workflow you're describing.

## Integration Approaches

### 1. Custom `ExplicitComponent` wrapping tudatpy (recommended)

The most natural approach is to write a custom `ExplicitComponent` that calls tudatpy directly inside its `compute()` method. Since both OpenMDAO and tudatpy are Python libraries, they can coexist in the same process:

```python
import openmdao.api as om
# import tudatpy as needed

class StationKeepingComp(om.ExplicitComponent):
    def setup(self):
        # Inputs from your sizing disciplines
        self.add_input('total_mass', val=1.0, units='kg')
        self.add_input('engine_thrust', val=0.001, units='N')
        # ... other inputs

        # Outputs from orbit simulation
        self.add_output('delta_v_annual', val=0.0, units='m/s')
        self.add_output('fuel_mass_required', val=0.0, units='kg')

    def setup_partials(self):
        # tudatpy won't give you analytic derivatives, so use finite difference
        self.declare_partials(of='*', wrt='*', method='fd')

    def compute(self, inputs, outputs):
        total_mass = inputs['total_mass']
        # Call tudatpy here to run your CR3BP / station-keeping simulation
        # ... set up tudatpy propagation, compute delta-v ...
        outputs['delta_v_annual'] = computed_delta_v
        outputs['fuel_mass_required'] = computed_fuel_mass
```

This pattern is the standard way to wrap any external Python library in OpenMDAO. The `ExplicitComponent` base class requires you to implement `setup()` (declare inputs/outputs) and `compute()` (evaluate outputs from inputs). [1](#0-0) 

Since tudatpy won't provide analytic derivatives, you declare finite-difference partials with `self.declare_partials(of='*', wrt='*', method='fd')`. [2](#0-1) 

### 2. `ExternalCodeComp` (if tudatpy runs as a separate script)

If you prefer to run your tudatpy simulation as a standalone Python script (e.g., reading inputs from a file and writing outputs to a file), OpenMDAO provides `ExternalCodeComp` for exactly this: [3](#0-2) 

The `ParaboloidExternalCodeComp` test example shows the pattern — write inputs to a file, run the external script, parse outputs from a file: [4](#0-3) 

## Suggested Model Architecture

Your cubesat design problem maps naturally to an OpenMDAO `Group` with coupled subsystems:

```
Problem
└── model (Group)
    ├── engine_sizing (ExplicitComponent)        # engine mass, thrust specs
    ├── thermal_control (ExplicitComponent)      # thermal mass from specs
    ├── comms_sizing (ExplicitComponent)         # comm system mass/power
    ├── power_sizing (ExplicitComponent)         # battery + solar panel sizing
    ├── mass_rollup (ExplicitComponent)          # total mass summation
    ├── station_keeping (ExplicitComponent)      # <-- wraps tudatpy
    └── fuel_budget (ExplicitComponent)          # delta-v → fuel mass
```

The coupling between `fuel_budget` and `mass_rollup` (fuel mass affects total mass, which affects required delta-v) creates a feedback loop. OpenMDAO handles this with nonlinear solvers like `NonlinearBlockGS` (Gauss-Seidel) or `NewtonSolver`. [5](#0-4) 

You can then attach an optimization driver (`ScipyOptimizeDriver` or `pyOptSparseDriver`) to minimize total mass or maximize payload, with design variables for engine specs, solar panel area, etc. [6](#0-5) 

## Key Considerations

- **Derivatives**: tudatpy simulations are expensive and won't provide analytic gradients. Use `method='fd'` for finite-difference derivatives, or consider gradient-free optimizers (e.g., `SimpleGADriver`, `DifferentialEvolutionDriver`, or `COBYLA` via `ScipyOptimizeDriver`).
- **Performance**: Each finite-difference perturbation requires a full tudatpy propagation. Minimize the number of design variables that flow into the station-keeping component to keep the cost manageable.
- **Convergence**: The mass feedback loop (fuel mass ↔ total mass ↔ delta-v) is a classic MDO coupling. OpenMDAO's `NonlinearBlockGS` solver will iterate this to convergence automatically.

### Citations

**File:** openmdao/core/explicitcomponent.py (L19-88)
```python
class ExplicitComponent(Component):
    """
    Class to inherit from when all output variables are explicit.

    Parameters
    ----------
    **kwargs : dict of keyword arguments
        Keyword arguments that will be mapped into the Component options.

    Attributes
    ----------
    _has_compute_partials : bool
        If True, the instance overrides compute_partials.
    _vjp_hash : int or None
        Hash value for the last set of inputs to the compute_primal function.
    _vjp_fun : function or None
        The vector-Jacobian product function.
    """

    def __init__(self, **kwargs):
        """
        Store some bound methods so we can detect runtime overrides.
        """
        super().__init__(**kwargs)

        self._has_compute_partials = overrides_method('compute_partials', self, ExplicitComponent)
        self.options.undeclare('assembled_jac_type')
        self._vjp_hash = None
        self._vjp_fun = None

    @property
    def nonlinear_solver(self):
        """
        Get the nonlinear solver for this system.
        """
        return self._nonlinear_solver

    @nonlinear_solver.setter
    def nonlinear_solver(self, solver):
        """
        Raise an exception.
        """
        raise RuntimeError(f"{self.msginfo}: Explicit components don't support nonlinear solvers.")

    @property
    def linear_solver(self):
        """
        Get the linear solver for this system.
        """
        return self._linear_solver

    @linear_solver.setter
    def linear_solver(self, solver):
        """
        Raise an exception.
        """
        raise RuntimeError(f"{self.msginfo}: Explicit components don't support linear solvers.")

    def _configure(self):
        """
        Configure this system to assign children settings and detect if matrix_free.
        """
        if is_undefined(self.matrix_free):
            self.matrix_free = overrides_method('compute_jacvec_product', self, ExplicitComponent)

    def _jac_wrt_iter(self, wrt_matches=None):
        """
        Iterate over (name, start, end, vec, slice, dist_sizes) for each column var in the jacobian.

        Parameters
```

**File:** openmdao/components/tests/test_external_code_comp.py (L261-299)
```python
class ParaboloidExternalCodeComp(om.ExternalCodeComp):
    def setup(self):
        self.add_input('x', val=0.0)
        self.add_input('y', val=0.0)

        self.add_output('f_xy', val=0.0)

        self.input_file = 'paraboloid_input.dat'
        self.output_file = 'paraboloid_output.dat'

        # providing these is optional; the component will verify that any input
        # files exist before execution and that the output files exist after.
        self.options['external_input_files'] = [self.input_file]
        self.options['external_output_files'] = [self.output_file]

        # If you want to write your command as a list, the code below will also work.
        # self.options['command'] = [
        #     sys.executable, 'extcode_paraboloid.py', self.input_file, self.output_file
        # ]

        self.options['command'] = ('{} extcode_paraboloid.py {} {}').format(
                                   sys.executable, self.input_file, self.output_file)

    def compute(self, inputs, outputs):
        x = inputs['x'].item()
        y = inputs['y'].item()

        # generate the input file for the paraboloid external code
        with open(self.input_file, 'w') as input_file:
            input_file.write('%.16f\n%.16f\n' % (x, y))

        # the parent compute function actually runs the external code
        super().compute(inputs, outputs)

        # parse the output file from the external code and set the value of f_xy
        with open(self.output_file, 'r') as output_file:
            f_xy = float(output_file.read())

        outputs['f_xy'] = f_xy
```

**File:** openmdao/components/tests/test_external_code_comp.py (L321-323)
```python
    def setup_partials(self):
        # this external code does not provide derivatives, use finite difference
        self.declare_partials(of='*', wrt='*', method='fd')
```

**File:** openmdao/components/external_code_comp.py (L234-308)
```python
class ExternalCodeComp(ExplicitComponent):
    """
    Run an external code as a component.

    Default stdin is the 'null' device, default stdout is the console, and
    default stderr is ``external_code_comp_error.out``.

    Parameters
    ----------
    **kwargs : dict of keyword arguments
        Keyword arguments that will be mapped into the Component options.

    Attributes
    ----------
    stdin : str or file object
        Input stream external code reads from.
    stdout : str or file object
        Output stream external code writes to.
    stderr : str or file object
        Error stream external code writes to.
    _external_code_runner : ExternalCodeDelegate object
        The delegate object that handles all the running of the external code for this object.
    return_code : int
        Exit status of the child process.
    """

    def __init__(self, **kwargs):
        """
        Intialize the ExternalCodeComp component.
        """
        self._external_code_runner = ExternalCodeDelegate(self)
        super().__init__(**kwargs)

        self.stdin = DEV_NULL
        self.stdout = None
        self.stderr = "external_code_comp_error.out"

        self.return_code = 0

    def _declare_options(self):
        """
        Declare options before kwargs are processed in the init method.

        Options are declared here because this class is intended to be subclassed by
        the end user. The `initialize` method is left available for user-defined options.
        """
        super()._declare_options()
        self._external_code_runner.declare_options()

    def check_config(self, logger):
        """
        Perform optional error checks.

        Parameters
        ----------
        logger : object
            The object that manages logging output.
        """
        # check for the command
        self._external_code_runner.check_config(logger)

    def compute(self, inputs, outputs):
        """
        Run this component.

        User should call this method from their overriden compute method.

        Parameters
        ----------
        inputs : Vector
            Unscaled, dimensional input variables read via inputs[key].
        outputs : Vector
            Unscaled, dimensional output variables read via outputs[key].
        """
        self._external_code_runner.run_component()
```

**File:** openmdao/core/group.py (L262-266)
```python
        if not self._nonlinear_solver:
            self._nonlinear_solver = NonlinearRunOnce()
        if not self._linear_solver:
            self._linear_solver = LinearRunOnce()

```

**File:** openmdao/drivers/scipy_optimizer.py (L20-42)
```python
_optimizers = {'Nelder-Mead', 'Powell', 'CG', 'BFGS', 'Newton-CG', 'L-BFGS-B',
               'TNC', 'COBYLA', 'SLSQP'}
if Version(scipy_version) >= Version("1.1"):  # Only available in newer versions
    _optimizers.add('trust-constr')

# For 'basinhopping' and 'shgo' gradients are used only in the local minimization
_gradient_optimizers = {'CG', 'BFGS', 'Newton-CG', 'L-BFGS-B', 'TNC', 'SLSQP', 'dogleg',
                        'trust-ncg', 'trust-constr', 'basinhopping', 'shgo'}
_hessian_optimizers = {'trust-constr', 'trust-ncg'}
_bounds_optimizers = {'L-BFGS-B', 'TNC', 'SLSQP', 'trust-constr', 'dual_annealing', 'shgo',
                      'differential_evolution', 'basinhopping', 'Nelder-Mead'}
if Version(scipy_version) >= Version("1.11"):
    # COBYLA supports bounds starting with SciPy Version 1.11
    _bounds_optimizers |= {'COBYLA'}

_constraint_optimizers = {'COBYLA', 'SLSQP', 'trust-constr', 'shgo'}
_constraint_grad_optimizers = _gradient_optimizers & _constraint_optimizers
if Version(scipy_version) >= Version("1.4"):
    _constraint_optimizers.add('differential_evolution')
    _constraint_grad_optimizers.add('differential_evolution')

_eq_constraint_optimizers = {'SLSQP', 'trust-constr'}
_global_optimizers = {'differential_evolution', 'basinhopping'}
```

## 3. Astropy: Role & Necessity

With the adoption of `tudatpy` for full propagation and MDO via `openmdao`, the role of **`astropy`** is significantly reduced but still beneficial. 

- **Why it might be redundant:** `tudatpy` inherently uses SPICE kernels for planetary ephemerides, frame transformations (e.g., J2000 to Sun-Earth rotating frames), and time conversions (TDB, UTC). 
- **Why we should keep it:** `astropy` remains the Python standard for standalone unit conversions (`astropy.units`), independent coordinate checks, payload calculations (e.g., figuring out the angular size of the Sun or Earth from 1 AU), and rapid astronomical constant lookups without the overhead of instantiating a full `tudatpy` SPICE environment. 

**Verdict:** Use `tudatpy` for all central mathematical modeling in the orbital dynamics propagation and optimization loops. Retain `astropy` as an auxiliary tool for simple data validation, unit handling, and side-calculations.