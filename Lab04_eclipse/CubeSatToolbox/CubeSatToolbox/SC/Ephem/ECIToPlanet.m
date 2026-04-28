function c = ECIToPlanet( jD, planet, kEarth )
	
%% Computes the matrix from mean of Aries 2000 to planet fixed frame. 
% Includes all of the planets and many of the moons. Returns the identity 
% matrix if the moon is unknown. For the Earth's moon it returns the true
% rotation matrix.
%--------------------------------------------------------------------------
%   Form:
%   c = ECIToPlanet( jD, planet, kEarth )	
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   jD         (1,1)  Julian date
%   planet     (1,:)  Name of the planet
%   kEarth     (1,1)  If 0 use TruEarth, if 1 is TruEarth with eofe,
%                     if <0 use Montenbruck (see also ECIToEF)
%
%   -------
%   Outputs
%   -------
%   c         (3,3)  Matrix from Mean of 2000.0 to planet fixed
%
%--------------------------------------------------------------------------
%   References: Seidelmann, ed. The Explanatory Supplement to the 
%               Astronomical Almanac, University Science Books, 1992,
%               p. 705.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1999 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   2016.1: Fixed rotation matrix and added a Mars demo
%--------------------------------------------------------------------------

% Demo
if( nargin < 1 )
  jD = Date2JD + linspace(0,1);
  u  = [1;0;0];
  n  = length(jD);
  uP = zeros(3,n);
  for k = 1:n
    uP(:,k) = ECIToPlanet( jD(k), 'mars' )*u;
  end
  
  Plot2D(jD-jD(1),uP,'Fraction of Day',{'u_x' 'u_y' 'u_z'},'ECI Vector in Mars frame')
  return
end
  

% Input processing
%-----------------
if( nargin < 1 )
  jD = [];
end

if( nargin < 2 )
  planet = [];
end

if( nargin < 3 )
  kEarth = -1;
end

% Defaults
%---------
if( isempty(jD) )
  jD = Date2JD;
end

if( isempty(planet) )
  planet = 'earth';
end

% Default
%--------
c = eye(3);

jDStandard = 2451545.0;
d          = jD - jDStandard;
T          = JD2T( jD );

switch( lower(planet) )
  case 'sun'
    c = MECIToPlanet( 286.13, 63.87, 84.1 + 14.1844*d );
    
  case 'mercury'
    c = MECIToPlanet( 281.01 - 0.003*T, 61.45 - 0.005*T, 329.71 + 6.1385025*d );
  
  case 'venus'
    c = MECIToPlanet( 272.72, 67.15, 160.26 - 1.4813596*d );
    
  case {'earth','earthhr'}
    if( kEarth < 0 )
      c = MECIToPlanet( -0.641*T, 90 - 0.557*T, 190.16 + 360.9856235*d ); % 190.16 from Ref 
    elseif( kEarth == 0 )
      c = TruEarth( T, 1 );
    else
      c = TruEarth( T );
    end   

  case 'mars'
    c = MECIToPlanet( 317.681 - 0.108*T, 52.886 - 0.061*T, 176.868 + 350.8919830*d );
    
  case 'jupiter'
    c = MECIToPlanet( 268.05 - 0.009*T, 64.49 + 0.003*T, 284.95 + 870.536*d );
    
  case 'saturn'
    c = MECIToPlanet(  40.58 - 0.036*T, 83.54 - 0.004*T, 38.90 + 810.7939024*d );
    
  case 'uranus'
    c = MECIToPlanet( 257.43, -15.1, 203.81 - 501.1600928*d );
    
  case 'neptune' 
    n = 6.2706 +  0.94785*T;
    c = MECIToPlanet(299.36 - 0.7*sin(n) , 43.46 - 0.51*cos(n), 253.18 + 536.3128492*d  - 0.48*sin(n));
    
  case 'pluto'
    c = MECIToPlanet( 313.02, 9.09, 236.77 - 56.3623195*d );
    
  otherwise
    switch Moons( planet )
      case 'earth'
        c = EarthMoonRotationMatrix( T );
    
      case 'mars'
        c = MarsMoonRotationMatrix( T, d, planet );
    
      case 'jupiter'
        c = JupiterMoonRotationMatrix( T, d, planet );
    
      case 'saturn'
        c = SaturnMoonRotationMatrix( T, d, planet );
    
      case 'uranus'
        c = UranusMoonRotationMatrix( T, d, planet );
    
      case 'neptune' 
        c = NeptuneMoonRotationMatrix( T, d, planet );
    
      case 'pluto'
        c = PlutoMoonRotationMatrix( T, d );
	
	otherwise
	  c = eye(3);
    end  
end

%--------------------------------------------------------------------------
%   References:   Montenbruck, O., Pfleger, T., "Astronomy on the Personal
%                 Computer, Second Edition." p. 140.
%--------------------------------------------------------------------------

function m = MECIToPlanet( alpha0, delta0, w )

degToRad = pi/180;
cW       = cos( w     *degToRad ); % Angle about pole
sW       = sin( w     *degToRad );
cA       = cos( alpha0*degToRad ); % Right Ascension
sA       = sin( alpha0*degToRad );
cD       = cos( delta0*degToRad ); % Declination
sD       = sin( delta0*degToRad );

sWsA     = sW*sA;
sWcA     = sW*cA;
cWsA     = cW*sA;
cWcA     = cW*cA;

e1       = [-cWsA - sWcA*sD,    cWcA - sWsA*sD,   sW*cD];
e2       = [ sWsA - cWcA*sD,   -sWcA - cWsA*sD,   cW*cD];
e3       = [          cA*cD,             sA*cD,      sD];


m        = [e1;e2;e3];

%--------------------------------------------------------------------------
%   References:   Seidelmann, The Explanatory Supplement to the 
%                 Astronomical Almanac, p. 407.
%--------------------------------------------------------------------------
function c = EarthMoonRotationMatrix( T )

c = MoonRot( T2JD(T), 'true' );

%--------------------------------------------------------------------------
%   References:   Seidelmann, The Explanatory Supplement to the 
%                 Astronomical Almanac, p. 407.
%--------------------------------------------------------------------------
function c = MarsMoonRotationMatrix( T, t, moon )

c = eye(3);

m = (   [   169.51 192.93 53.47]...
      + ([-0.4357640 1128.40967 -0.0181510] + [0 0.6644 0]*t)*t)*pi/180;
      
sM = sin( m );
cM = cos( m );

switch moon
  case 'phobos'
    rA  = 317.68 - 0.108*T + 1.79*sM(1);
    dec =  52.9  - 0.061*T - 1.08*cM(1);
    W   = 35.06 + 1128.8445850*t + 0.6644e-9*t^2 - 1.42*sM(1) - 0.78*sM(2);
    
  case 'deimos'
    rA  = 316.65 - 0.108*T + 3.98*sM(1);
    dec =  53.52 - 0.061*T - 1.78*cM(1);
    W   = 79.41 + 285.1618970*t + 0.390e-10*t^2 - 2.58*sM(1) - 0.19*sM(2);
  
  otherwise
    rA  = 0;
    dec = 0;
    W   = 0;
end

c = MECIToPlanet( rA, dec, W );


%--------------------------------------------------------------------------
%   References:   Seidelmann, The Explanatory Supplement to the 
%                 Astronomical Almanac, p. 409.
%--------------------------------------------------------------------------
function c = JupiterMoonRotationMatrix( T, t, moon )

c = eye(3);

j = (   [   73.32    198.54   283.9  355.8 119.9  229.8    352.25   113.35]...
      + [91473.9   44243.8   4850.7 1191.3 262.1   64.3   2382.6   6070.0]*T)*Constant('deg to rad');
      
sJ  = sin( j   );
cJ  = cos( j   );
s2J = sin( 2*j );
c2J = cos( 2*j );

switch moon
  case 'metis'
    rA  = 268.05 - 0.009*T;
    dec =  64.49 + 0.003*T;
    W   = 302.24 + 1221.2489660*t;
    
  case 'adrastea'
    rA  = 268.05 - 0.009*T;
    dec =  64.49 + 0.003*T;
    W   =   5.75 + 1206.9950400*t;
    
  case 'amalthea'
    rA  = 268.05 - 0.009*T      - 0.84*sJ(1) + 0.01*s2J(1);
    dec =  64.49 + 0.003*T      - 0.36*cJ(1);
    W   = 231.67 + 722.631450*t + 0.76*sJ(1) - 0.01*s2J(1);
      
  case 'thebe'
    rA  = 268.05 - 0.009*T       - 2.12*sJ(2) + 0.04*s2J(2);
    dec =  64.49 + 0.003*T       - 0.91*cJ(2) + 0.01*c2J(2);
    W   =   9.91 + 533.7005330*t + 1.91*sJ(2) - 0.05*s2J(2);
    
  case 'io'
    rA  = 268.05 - 0.009*T       + 0.094*sJ(3) + 0.024*sJ(4);
    dec =  64.50 + 0.003*T       - 0.040*cJ(3) + 0.011*cJ(4);
    W   = 200.39 + 203.4889538*t - 0.085*sJ(3) - 0.022*sJ(4);
    
  case 'europa'
    rA  = 268.08 - 0.009*T       + 1.086*sJ(4) + 0.060*sJ(5) + 0.015*sJ(6) + 0.009*sJ(7);
    dec =  64.51 + 0.003*T       + 0.040*cJ(4) + 0.026*cJ(5) + 0.007*cJ(6) + 0.002*cJ(7);
    W   =  35.72 + 101.3747235*t - 0.980*sJ(4) - 0.054*sJ(5) - 0.014*sJ(6) - 0.008*sJ(7);
    
  case 'ganymede'
    rA  = 268.20 - 0.009*T       - 0.037*sJ(4) + 0.431*sJ(5) + 0.091*sJ(6);
    dec =  64.51 + 0.003*T       - 0.016*cJ(4) + 0.186*cJ(5) + 0.039*cJ(6);
    W   =  43.14 + 50.3176081*t  - 0.033*sJ(4) - 0.389*sJ(5) - 0.082*sJ(6);
    
  case 'callisto'
    rA  = 268.72 - 0.009*T       - 0.068*sJ(5) + 0.590*sJ(6) + 0.010*sJ(8);
    dec =  64.51 + 0.003*T       - 0.029*cJ(5) + 0.254*cJ(6) - 0.004*cJ(8);
    W   = 259.67 + 21.5710715*t  + 0.061*sJ(5) - 0.533*sJ(6) - 0.009*sJ(8);
    
  otherwise
    rA  = 0;
    dec = 0;
    W   = 0;
end

c  = MECIToPlanet( rA, dec, W );

%--------------------------------------------------------------------------
%   References:   Seidelmann, The Explanatory Supplement to the 
%                 Astronomical Almanac, p. 411.
%--------------------------------------------------------------------------
function c = SaturnMoonRotationMatrix( T, t, moon )

c = eye(3);

s = (   [  353.2    28.72   177.5   300.0    53.59   143.38    345.20   29.8 216.45]...
      + [75706.7 75706.7 -36505.5 -7225.9 -8968.8 -10553.5   -1016.3   -52.1 506.2]*T)*Constant('deg to rad');
      
sS  = sin( s );
cS  = cos( s );
s2S = 2*sS.*cS;
c2S = cS.^2 - sS.^2;

switch moon
  case 'pan'
    rA  =  40.6  - 0.036*T;
    dec =  83.53 - 0.004*T;
    W   =  48.8 + 626.0440000*t;
    
  case 'atlas'
    rA  =  40.58 - 0.036*T;
    dec =  83.53 - 0.004*T;
    W   = 137.8 + 598.3060000*t;
    
  case 'prometheus'
    rA  =  40.58 - 0.036*T;
    dec =  83.53 - 0.004*T;
    W   = 296.14 + 587.2890000*t;
    
  case 'pandora'
    rA  =  40.58 - 0.036*T;
    dec =  83.53 - 0.004*T;
    W   = 162.92 + 572.7891000*t;
    
  case 'epimetheus'
    rA  =  40.58  - 0.036*T       - 3.153*sS(1) + 0.085*s2S(1);
    dec =  83.53  - 0.004*T       - 0.356*cS(1) + 0.005*c2S(1);
    W   =  293.87 + 518.4907239*t + 3.133*sS(1) - 0.086*s2S(1);
    
  case 'janus'
    rA  =  40.58  - 0.036*T       - 1.623*sS(2) + 0.023*s2S(2);
    dec =  83.53  - 0.004*T       - 0.183*cS(2) + 0.001*c2S(2);
    W   =  58.83 + 518.2359876*t  + 1.613*sS(2) - 0.023*s2S(2);
    
  case 'mimas'
    rA  =  40.66  - 0.036*T       + 13.56*sS(3);
    dec =  83.52  - 0.004*T       - 1.53*cS(3);
    W   =  337.46 + 381.9945550*t - 13.48*sS(3) - 0.023*sS(9);
    
  case 'enceladus'
    rA  =  40.66 - 0.036*T;
    dec =  83.52 - 0.004*T;
    W   =  2.82 + 262.7318966*t;
    
  case 'tethys'
    rA  =  40.66 - 0.036*T + 9.66*sS(4);
    dec =  83.52 - 0.004*T - 1.08*cS(4);
    W   =  10.45 +190.6979085*t - 9.6*sS(4) + 2.23*sS(9);
    
  case 'telesto'
    rA  =  50.5  - 0.036*T;
    dec =  84.06 - 0.004*T;
    W   =  56.88 + 190.6979330*t;
    
  case 'calypso'
    rA  =  40.58  - 0.036*T       + 13.943*sS(5)  - 1.686*s2S(5);
    dec =  83.43  - 0.004*T       - 1.572*cS(5)   + 0.095*c2S(5);
    W   = 149.36 + 190.6742373*t  - 13.849*sS(5)  + 1.685*s2S(5);
    
  case 'dione'
    rA  =  40.66 - 0.036*T;
    dec =  83.52 - 0.004*T;
    W   =  357.00 + 131.5349316*t;
    
  case 'helene'
    rA  =  40.58  - 0.036*T       + 1.662*sS(6)  + 0.024*s2S(6);
    dec =  83.52  - 0.004*T       - 0.187*cS(6)  + 0.095*c2S(6);
    W   = 245.39 + 79.6900478*t   - 1.651*sS(6)  + 0.024*s2S(6);
    
  case 'rhea'
    rA  =  40.38  - 0.036*T      + 3.1*sS(7);
    dec =  83.55  - 0.004*T      - 0.35*cS(7);
    W   =  235.16 + 79.6900478*t - 3.08*sS(7);
    
  case 'titan'
    rA  =  36.41  - 0.036*T      + 2.66*sS(8);
    dec =  83.94  - 0.004*T      - 0.30*cS(8);
    W   =  189.64 + 22.5769768*t - 2.24*sS(8);
    
  case 'iapetus'
    rA  =  318.16  - 3.949*T;
    dec =  75.03   - 1.143*T;
    W   =  350.20 + 4.5379572*t;
    
  case 'phoebe'
    rA  =  355.16;
    dec =  68.7 - 1.143*T;
    W   = 304.70 + 930.8338720*t;
    
  otherwise
    rA  = 0;
    dec = 0;
    W   = 0;
end

c  = MECIToPlanet( rA, dec, W );

%--------------------------------------------------------------------------
%   References:   Seidelmann, The Explanatory Supplement to the 
%                 Astronomical Almanac, p. 412.
%--------------------------------------------------------------------------
function c = UranusMoonRotationMatrix( T, t, moon )

c = eye(3);

u = (   [   115.75   141.69   135.03    61.77   249.32    43.86    77.66   157.36   101.81  138.64   102.23  316.41 304.01 308.71 340.82  259.14]...
      + [ 54991.87 41887.66 29927.35 25733.59 24471.46 22278.41 20289.42 16652.76 12872.63 8061.81 -2024.22 2864.96 -51.94 -93.17 -75.32 -504.81]*T)*Constant('deg to rad');
      
sU = sin( u );
cU = cos( u );
s2U = 2*sU.*cU;
c2U = cU.^2 - sU.^2;

switch moon
  case 'cordella'
    rA  = 257.31 - 0.15*sU(1);
    dec = -15.18 + 0.14*cU(1);
    W   = 127.69 - 1074.5205730*t - 0.04*sU(1);
    
  case 'ophelia'
    rA  = 257.31 - 0.09*sU(2);
    dec = -15.18 + 0.09*cU(2);
    W   = 130.35 - 956.4068150*t - 0.03*sU(2);
    
  case 'bianca'
    rA  = 257.31 - 0.16*sU(3);
    dec = -15.18 + 0.16*cU(3);
    W   = 105.46 - 828.3914760*t - 0.04*sU(3);
    
  case 'cressida'
    rA  = 257.31 - 0.04*sU(4);
    dec = -15.18 + 0.04*cU(1);
    W   = 127.69 - 776.5816320*t - 0.01*sU(4);
    
  case 'desdemona'
    rA  = 257.31 - 0.17*sU(5);
    dec = -15.18 + 0.16*cU(5);
    W   = 127.69 - 760.0531690*t - 0.04*sU(5);
    
  case 'juliet'
    rA  = 257.31 - 0.06*sU(6);
    dec = -15.18 + 0.06*cU(6);
    W   = 127.69 - 730.1253660*t - 0.02*sU(6);
    
  case 'portia'
    rA  = 257.31 - 0.09*sU(7);
    dec = -15.18 + 0.09*cU(7);
    W   = 127.69 - 701.4865870*t - 0.02*sU(7);
    
  case 'rosalind'
    rA  = 257.31 - 0.29*sU(8);
    dec = -15.18 + 0.28*cU(8);
    W   = 127.69 - 644.6311260*t - 0.08*sU(8);
    
  case 'belinda'
    rA  = 257.31 - 0.03*sU(9);
    dec = -15.18 + 0.03*cU(9);
    W   = 127.69 - 577.3628170*t - 0.01*sU(9);
    
  case 'puck'
    rA  = 257.31 - 0.33*sU(10);
    dec = -15.18 + 0.31*cU(10);
    W   = 127.69 - 472.5450690*t - 0.09*sU(10);
    
  case 'miranda'
    rA  = 257.43 + 4.41*sU(11) - 0.04*s2U(11);
    dec = -15.08 + 4.25*cU(11) - 0.02*c2U(11);
    W   =  30.70 - 254.6906892*t - 1.27*sU(12) + 0.15*s2U(12) + 1.15*sU(11) - 0.09*s2U(11);
      
  case 'ariel'
    rA  = 257.43 + 0.29*sU(13);
    dec = -15.10 + 0.28*cU(13);
    W   = 156.22 - 142.8356681*t + 0.05*sU(12) + 0.08*sU(13);
      
  case 'umbriel'
    rA  = 257.43 + 0.21*sU(14);
    dec = -15.10 + 0.20*cU(14);
    W   = 108.05 - 86.8688923*t - 0.09*sU(12) + 0.06*sU(14);
      
  case 'titania'
    rA  = 257.43 + 0.16*sU(15);
    dec = -15.10 + 0.28*cU(15);
    W   =  77.74 - 41.3514316*t + 0.084*sU(15);
      
  case 'oberon'
    rA  = 257.43 + 0.29*sU(16);
    dec = -15.10 + 0.36*cU(16);
    W   =   6.77 - 26.7394932*t + 0.04*sU(16);
      
  otherwise
    rA  = 0;
    dec = 0;
    W   = 0;
end

c  = MECIToPlanet( rA, dec, W );

%--------------------------------------------------------------------------
%   References:   Seidelmann, The Explanatory Supplement to the 
%                 Astronomical Almanac, p. 413.
%--------------------------------------------------------------------------
function c = NeptuneMoonRotationMatrix( T, t, moon )

c = eye(3);

n = (   [ 357.85    323.92    220.51   354.27   75.31    35.36   142.61 177.85]...
      + [  52.316 62606.6   55064.2  46564.5  26109.4 14325.4   2824.6   52.316]*T)*Constant('deg to rad');

n0 = n(1);
n  = n(2:8);
sN0 = sin( n(1) );
cN0 = cos( n(1) );
sN  = sin( n );
cN  = cos( n );

s2N = 2*sN.*cN;
c2N = cN.^2 - sN.^2;

switch moon
  case 'naiad'
    rA  =  299.39 + 0.70*sN0 - 6.49*sN(1) + 0.25*s2N(1);
    dec =   43.35 - 0.51*cN0 - 4.75*cN(1) + 0.09*c2N(1);
    W   =  254.06 + 1222.8441209*t - 0.48*sN0 + 4.40*sN(1) - 0.27*s2N(1);
    
  case 'thalassa'
    rA  =  299.39 + 0.70*sN0 - 0.28*sN(2);
    dec =   43.44 - 0.51*cN0 - 0.21*cN(2);
    W   =  102.06 + 1155.7555612*t - 0.48*sN0 + 0.19*sN(2);
    
  case 'despina'
    rA  =  299.39 + 0.70*sN0 - 0.09*sN(3);
    dec =   43.44 - 0.51*cN0 - 0.07*cN(3);
    W   =  306.51 + 1075.7341562*t - 0.49*sN0 + 0.06*sN(3);
    
  case 'galatea'
    rA  =  299.39 + 0.70*sN0 - 0.27*sN(4);
    dec =   43.43 - 0.51*cN0 - 0.05*cN(4);
    W   =  258.09 + 839.6597686*t - 0.48*sN0 + 0.05*sN(4);
    
  case 'larissa'
    rA  =  299.39 + 0.70*sN0 - 0.27*sN(5);
    dec =   43.40 - 0.51*cN0 - 0.20*cN(5);
    W   =  179.41 + 649.0534470*t - 0.48*sN0 + 0.19*sN(5);
    
  case 'proteus'
    rA  =  299.39 + 0.70*sN0 - 0.05*sN(6);
    dec =   42.90 - 0.51*cN0 - 0.04*cN(6);
    W   =   93.38 + 320.7654228*t - 0.48*sN0 + 0.036*sN(6);
    
  case 'triton'
    s    = zeros(9,1);
    c    = zeros(9,1);
    s(1) = sN(7);
    c(1) = cN(7);
    for j = 2:9
      s(j) = 2*s(j-1)*c(j-1);
      c(j) = c(j-1)^2 - s(j-1)^2;
    end
    qRA  = [-32.35 -6.28 -2.08  0.74 -0.28 -0.11 -0.07 -0.02 -0.01];
    qDec = [22.55  2.10  0.44  0.16  0.05  0.02  0.01];
    qW   = [22.25 6.73 2.05 0.74 0.28 0.11 0.05 0.02 0.01];
    
    rA   = 299.36 +  qRA*s;
    dec  = 41.15 + qDec*c(1:7);
    W    = 296.53 - 61.2572637*t + qW*s;
      
  otherwise
    rA  = 0;
    dec = 0;
    W   = 0;
end

c  = MECIToPlanet( rA, dec, W );

%--------------------------------------------------------------------------
%   References:   Seidelmann, The Explanatory Supplement to the 
%                 AstronomicalAlmanac, p. 413.
%--------------------------------------------------------------------------
function c = PlutoMoonRotationMatrix( T, t )

c = MECIToPlanet( 312.02, 9.09, 56.77 - 56.3623195*t );


%--------------------------------------
% $Date: 2016-05-13 11:31:16 -0400 (Fri, 13 May 2016) $
% $Revision: 42475 $
