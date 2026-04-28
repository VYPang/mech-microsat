function [rho, nHe, nN2, nO2, nO, tZ, eM] = AtmJ70( d )

%% Computes the atmospheric density using Jacchia's 1970 model.
%
% Type AtmJ70 for demo.
%--------------------------------------------------------------------------
%   Form:
%   [rho, nHe, nN2, nO2, nO, tZ, eM] = AtmJ70( d )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   d    (:) Data structure
%            .aP         Geomagnetic index 6.7 hours before the computation
%            .dd         Day number since Jan 1., days
%            .f          Daily 10.7 cm solar flux (e-22 watts/m^2/cycle/sec)
%            .fHat       81-day mean of f (e-22 watts/m^2/cycle/sec)
%            .fHat400    fHat 400 days before computation date
%            .lat        Latitude of computation point + north (deg)
%            .lng        Longitude of computation point + east (deg)
%            .mm         Greenwich mean time from 0000 GMT, minutes
%            .yr         Year
%            .z          Geometric altitude (km)
%
%   or
%            .jD         Julian date
%            .rECI       ECI position vector
%            .aP         Geomagnetic index 6.7 hours before the computation
%            .f          Daily 10.7 cm solar flux (e-22 watts/m^2/cycle/sec)
%            .fHat       81-day mean of f (e-22 watts/m^2/cycle/sec)
%            .fHat400    fHat 400 days before computation date
%
%   -------
%   Outputs
%   -------
%   rho  (:) Density (g/cm^3)
%   nHe  (:) Number density of helium
%   nN2  (:) Number density of nitrogen
%   nO2  (:) Number density of oxygen
%   nO   (:) Number density of monatomic oxygen
%   tZ   (:) Temperature
%   eM   (:) Mean molecular mass
%
%   See also SolarFluxPrediction.
%
%--------------------------------------------------------------------------
%    Reference: Models of the Earth's Atmosphere (90 to 2500 kM) NASA SP-8021.
%               Roberts, C.E. Jr, "An Analytic Model for Upper Atmosphere
%               Densities Based Upon Jacchia's 1970 Models", Celestial Mechanics
%               Vol. 4, 1971, pp. 368-377.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%    Copyright (c) 1999-2000 Princeton Satellite Systems, Inc.
%    All rights reserved.
%--------------------------------------------------------------------------

% Demo
%-----
if nargin == 0
    d.aP       = 400;
    d.dd       = 79;
    d.f        = 230;
    d.fHat     = 230;
    d.fHat400  = 230;
    d.lat      = -30;
    d.lng      = 0;
    d.mm       = 840;
    d.yr       = 1970;
    d.z        = 600;
    
    altLow = 90:2.5:125;
    altHigh = 125:5:800;
    alt = [altLow  altHigh];
    
    nPlot = length(alt);
    
    rhoPlot = zeros(1,nPlot);
    nHePlot = zeros(1,nPlot);
    nN2Plot = zeros(1,nPlot);
    nO2Plot = zeros(1,nPlot);
    nOPlot  = zeros(1,nPlot);
    tZPlot  = zeros(1,nPlot);
    eMPlot  = zeros(1,nPlot);
    
    for k = 1:length(alt)
        d.z = alt(k);
        [rho, nHe, nN2, nO2, nO, tZ, eM] = AtmJ70( d );
        
        rhoPlot(:,k) = rho;
        nHePlot(:,k) = nHe;
        nN2Plot(:,k) = nN2;
        nO2Plot(:,k) = nO2;
        nOPlot(:,k)  = nO;
        tZPlot(:,k)  = tZ;
        eMPlot(:,k)  = eM;
    end
    
    Plot2D(alt,rhoPlot,'Altitude (km)', 'Density (g/cm^3)','Density','ylog');
    Plot2D(alt,tZPlot,'Altitude (km)', 'Temp (K)','Temperature');
    Plot2D(alt,eMPlot,'Altitude (km)', 'Mean Molecular Mass (g/mole)','Mean Molecular Mass');
    Plot2D(alt,[nHePlot; nN2Plot; nO2Plot; nOPlot], 'Altitude (km)', ['He';'N2';'O2';'O '], 'Number Density (cm^-3)', 'ylog');
    clear rho
    return;
end

ang = 23.45;
aV  = 6.02257e23; % Avogadro's number (per mole)

mH  = 1.00797;    % atomic mass of hydrogen
mN2 = 2*14.0067;  % molecular mass of diatomic nitrogen
mO2 = 2*15.9994;  % molecular mass of diatomic oxygen
mO  = 15.9994;    % atomic mass of oxygen
mHe = 4.00260;    % atomic mass of helium

wH  = 1.6731e-24; % hydrogen mass (g/molecule)
wHe = 6.6435e-24; % helium   mass (g/molecule)
wN2 = 4.6496e-23; % nitrogen mass (g/molecule)
wO2 = 5.3104e-23; % diatomic oxygen mass (g/molecule)
wO  = 2.6552e-23; % oxygen   mass (g/molecule)

qN2 = 0.78110;    % low atmosphere volumetric fraction of N2
qAr = 0.00934;    % low atmosphere volumetric fraction of argon
qHe = 1.289e-5;   % low atmosphere volumetric fraction of helium
qO2 = 0.20955;    % low atmosphere volumetric fraction of O2

rho90 = 3.46e-9;  % assumed density at 90km altitude (g/cm^3)
t90   = 183;      % assumed temperature at 90km altitude (deg-K)
m90   = 28.878;   % assumed molecular mass at 90km altitude (unitless)

% NASA Equations
%---------------
if( ~isfield( d, 'jD' ) )
  j      = 2441683 + (d.yr - 1973)*365 + d.dd; % (A-1)
  jStar  = (j - 2415020)/36525; % (A-2)

  gP     = 99.6909833 + (36000.76854 + 0.00038708*jStar).*jStar + 0.25068447*d.mm; % (A-3)

  rAP    = Range( gP + d.lng, 0, 360 ); % (A-4)

  dJ     = j - 2435839;
  lS     = Range((0.017203*dJ + 0.0335*sin( 0.017203*dJ ) - 1.41)*180/pi, -180, 180); % (A-5)

  dS     = ASinD( SinD( lS )*SinD( ang ) ); % (A-6)
  rASArg = TanD( dS )/TanD( ang );

  % Put rAS in the same quadrant as lS
  %-----------------------------------
  rAS    = ASinDSameQuadrant( rASArg, lS );
  rAS    = Range( rAS, 0, 360 );

  hRA    = rAP - rAS; % (A-8) this should be > 0
else
  d.dd = JD2DN( d.jD );
	
  % Convert the orbital position to altitude and latitude
  %------------------------------------------------------
  [d.lat,d.z] = IJKToLatAlt( d.rECI );
  %d.z = Mag( d.rECI ) - 6378.165;
  %d.lat = ATanD( (1-Constant('earth flattening factor'))*( d.rECI(3)/sqrt( d.rECI(1:2)'*d.rECI(1:2) ) ));
		
  % Sun vector
  %-----------
  uSun = SunV1( d.jD );
	
  % Local hour angle of the sun
  %----------------------------
  hScA  = atan2( d.rECI(2), d.rECI(1) )*180/pi;
  if( hScA < 0 )	 
    hScA = hScA + 360.0; 
  end

  hSA   = atan2( uSun(2), uSun(1) )*180/pi;
  if( hSA < 0 )	
    hSA = hSA + 360; 
  end
  %hRA   = hSA - hScA; % NOTE: order appears wrong
  hRA   = hScA - hSA;
    
  dS    = 90.0 - ACosD( uSun(3) ); % Declination
end
rho = zeros(size(d.z));

% Angle between bulge and computation point
%------------------------------------------
tau    = Range( hRA - 37 + 6*SinD( hRA + 43 ), -180, 180 ); % (A-9)

% Nightime minimum global exospheric temperature (deg-K)
%-------------------------------------------------------
tC     = 383 + 3.32*d.fHat + 1.8*(d.f - d.fHat ); % (A-10)

% Diurnal correction (deg-K)
%---------------------------
eta    = 0.5*abs(d.lat - dS);
theta  = 0.5*abs(d.lat + dS);
r      = -0.19 + 0.25*log10(d.fHat400);

z      = SinD(theta)^2.5;
a      = r.*(( CosD(eta)^2.5 - z )./( 1 + r.*z ));
% in Jacchia's plots ratio tL/tC is always > 1
% plots of this function vs. H don't seem to match references
tL     = tC.*(1 + r.*z).*(1 + a.*CosD(0.5*tau)^3); % (A-11)

% Geomagnetic activity correction (deg-K)
%----------------------------------------
tG     = d.aP + 100*(1 - exp(-0.08*d.aP)); % (A-12)

% Semiannual correction (deg-K)
%------------------------------
z      = d.dd/365.2422;
tau    = z + 0.1145*( (0.5*(1+SinD(360*z+342.3))).^2.16 - 0.5 );
tS     = 2.41 + d.fHat.*(0.349 + 0.206*SinD(360*tau+226.5))*SinD(720*tau+247.6); % (A-13)

% Exospheric temperature (deg-K)
%-------------------------------
tE     = tL + tG + tS; % (A-14)

% Inflection point temperature (deg-K at altitude = 125 km)
%----------------------------------------------------------
tX     = 444.3807 + 0.02385*tE - 392.8292*exp(-0.0021357*tE); % (A-15)

% Temperature at geometric altitude levels (deg-K)
%-------------------------------------------------
dZ      = d.z - 125;

l       = find(dZ <= 0 );
if( ~isempty(l) )   % Altitudes between 90 and 125 km
  tZ(l)	= TempLowAlt( d.z(l), tX, t90 );
end

l       = find(dZ > 0 );
if( ~isempty(l) )
  tZ(l) = TempHighAlt( d.z(l), tX, t90, tE );
end

% For altitude <= 105 km
%-----------------------
l = find(d.z <= 105 );

fBarom = @(x) BaromExp(x,tX, t90);
if( ~isempty(l) )

  % Mean molecular mass (unitless)
  %-------------------------------
  eM(l) = MolMassLowAlt( d.z(l) );

  % Mass density before seasonal-latitudinal correction
  % Integrate barometric equation (A-19) 
  %----------------------------------------------------
  zL       = d.z(l);
  baromInt = zeros(1,length(zL));
  jj       = find( zL ~= 90 );
  if( ~isempty(jj) )
    baromInt(jj) = integral( fBarom, 90, zL(jj) );
  end
  rho(l)   = rho90 * (t90/tZ(l)) * (eM/m90) * exp( baromInt );

  % Seasonal-latitudinal density correction
  %----------------------------------------
  dZ     = d.z(l)-90;
  dDD    = 0.02*dZ*exp(-0.045*dZ)*SinD(360/365.2422*(d.dd(l)+100))*(SinD(d.lat(l))).^2 .* sign(d.lat(l)); % (A-20)
  rho(l) = rho(l)*10^dDD;

  % Number densities
  %-----------------
  par(l) = aV*rho(l)/eM(l);         % total number of particles per cm^3

  nN2(l) = qN2*eM(l).*par(l)/28.96;
  nHe(l) = qHe*eM(l).*par(l)/28.96;
  nAr(l) = qAr*eM(l).*par(l)/28.96;
  nO2(l) = par(l).*(eM(l)*(1+qO2)/28.96-1);
  nO(l)  = 2*par(l).*(1-eM(l)/28.96);

end

% Must calculate parameters at 105 km
%------------------------------------
tZ105  = TempLowAlt( 105, tX, t90 );
eM105  = MolMassLowAlt( 105 );

baromInt = integral( fBarom, 90, 105 );
rho105   = rho90 * (t90/tZ105) * (eM105/m90) * exp( baromInt );

dZ     = 105-90;

dDD105 = 0.02*dZ*exp(-0.045*dZ)*SinD(360/365.2422*(d.dd+100))*(SinD(d.lat)).^2 .* sign(d.lat); % (A-20)
rho105 = rho105*10^dDD105;

par105 = aV*rho105/eM105; % (A-22)

% Molecular number densities at 105 km
%-------------------------------------
fac    = eM105/28.96;
nN2105 = qN2*par105*fac;         % (A-23)
nHe105 = qHe*par105*fac;         % (A-23)
nO2105 = par105*(fac*(1+qO2)-1); % (A-24)
nO105  = 2*par105*(1-fac);       % (A-25)

% For altitude > 105 km
%----------------------
l = find(d.z > 105 );

fDiff = @(x) DiffusionExp(x,tX, t90, tE);
if( ~isempty(l) )

  diffusionInt  = integral( fDiff, 105, d.z(l) );
  tR            = tZ105./tZ(l);

  % N2, O2, O, He number density (cm^-3)
  %-------------------------------------
  nN2   = nN2105 * tR * exp( mN2*diffusionInt ); % (A-28)
  nO2   = nO2105 * tR * exp( mO2*diffusionInt ); % (A-28)
  nO    = nO105  * tR * exp( mO *diffusionInt ); % (A-28)
  nHe   = nHe105 * tR^0.62 * exp( mHe*diffusionInt); % (A28)

  % Hydrogen number density (cm^-3)
  %--------------------------------
  nH    = zeros(1,length(l));
  l2    = find( d.z(l) > 500 );
  if( ~isempty(l2) )
    tZ500         = TempHighAlt( 500, tX, t90, tE );
    lTE           = log10(tE);
    diffusionInt  = integral( fDiff, 500, d.z(l(l2)) );
    nH500         = 10^( 73.13 - ( 39.4 - 5.5*lTE)*lTE );  % (A-26)
    nH(l2)        = nH500 .* ( tZ500./tZ(l(l2)) ) * exp( mH*diffusionInt );  % (A-27)  exponent is so large that get 0
  end

  % Seasonal-latitudinal variation of helium
  %-----------------------------------------
  dHe   = 0.5 + 1.8*( ((23.45-dS(l))/47.5)^2.5 * (SinD(45+d.lat(l)/2))^4 ...
              + ((23.45+dS(l))/47.5)^2.5 * (SinD(45-d.lat(l)/2))^4 );  % (A-29)
  nHe   = nHe*dHe; % (A-30)

  rho(l) = nH*wH + nHe*wHe + nN2*wN2 + nO2*wO2 + nO*wO;  % (A-32)
  nTotal = nH + nHe + nN2 + nO2 + nO;
  eM(l)  = (nH*mH + nHe*mHe + nN2*mN2 + nO2*mO2 + nO*mO)./nTotal;
end

if nargout == 0
  disp('Density (g/cm^3):');
  disp(rho);
  clear rho
end

%--------------------------------------------------------------------------
%   Atmospheric Temperature for Altitudes between 90km and 125km
%   Jacchia Equation A-16
%--------------------------------------------------------------------------
function tZ = TempLowAlt( z, tX, t90 )

t1  = 1.9*(tX-t90)/35;
dZ  = z - 125;

t4  = 3*( tX - t90 - 2*t1*35/3 )/35^4;
t3  = 4*35*t4/3 - t1/(3*35^2);
tZ	= tX + t1*dZ + t3*dZ.^3 + t4*dZ.^4; % (A-16)

%--------------------------------------------------------------------------
%   Mean Molecular Mass for Altitudes Less than 105km
%   Jacchia Equation A-18
%--------------------------------------------------------------------------
function eM = MolMassLowAlt( z )

dZ     = z - 100;
dZSq   = dZ.*dZ;
dZCu   = dZSq.*dZ;
dZ4    = dZCu.*dZ;
dZ5    = dZ4.*dZ;
dZ6    = dZ5.*dZ;

eM  = 28.15204 - 0.085586*dZ + 1.2840e-4*dZSq - 1.0056e-5*dZCu - 1.0210e-5*dZ4 ...
               + 1.5044e-6*dZ5 + 9.9826e-8*dZ6; % (A-18)
		   
%--------------------------------------------------------------------------
%   Atmospheric Temperature for Altitudes greater than 125km
%   Jacchia Equation A-17
%--------------------------------------------------------------------------
function tZ = TempHighAlt( z, tX, t90, tE )

t1 = 1.9*(tX-t90)/35;
dZ = z - 125;

a2 = 2*(tE-tX)/pi;
tZ = tX + a2*atan( (t1.*dZ.*(1+(4.5e-6)*dZ.^2.5))./a2 ); % (A-17)

%--------------------------------------------------------------------------
% Put ASinD(x) in the same quadrant as z
%--------------------------------------------------------------------------
function y = ASinDSameQuadrant( a, z )

y = ASinD(a);

l = find( z > 90 );
if( ~isempty(z) )
  y(l) =  180 - y(l);
end

l = find( z < -90 );
if( ~isempty(z) )
  y(l) = -180 - y(l);
end

%--------------------------------------------------------------------------
% Limit x to the range xMin, xMax
%--------------------------------------------------------------------------
function y = Range( x, xMin, xMax )

md = abs(xMax-xMin);
y  = rem( x, md );
l  = find( y < xMin );
if( ~isempty(l) )
  y(l) = y(l) + md;
end
l  = find( y > xMax );
if( ~isempty(l) )
  y(l) = y(l) - md;
end

%--------------------------------------------------------------------------
% Trigonometric functions
%--------------------------------------------------------------------------
function y = SinD( x )
y = sin( x * pi/180 );

function y = CosD( x )
y = cos( x * pi/180 );

function y = TanD( x )
y = tan( x * pi/180 );

function y = ASinD( x )
y = asin( x )*180/pi;

%function y = ATanD( x )
%y = atan( x )*180/pi;

%--------------------------------------------------------------------------
% ECI position to latitude (deg) and altitude - see EFToLatLonAlt;
% skip longitude calculations for efficiency.
% Ref: Vallado, 2001.
%--------------------------------------------------------------------------
function [lat,z] = IJKToLatAlt( r )

% constants
a = 6.378140000000000e+03; % Constant('equatorial radius earth')
f = 0.00335281317790; % Constant('earth flattening factor')

rD       = Mag( r(1:2,:) );
rK       = r(3,:);
phiGdOld = atan( rK/rD );
phiGd    = phiGdOld;
eSq      = f*(2-f);
deltaPhi = 1e6;
tol      = 1e-6;

if( abs(rD) > 0 )

  while( norm(deltaPhi) > tol )
    s        = sin( phiGd );
    c        = a./sqrt(1-eSq*s.^2); % curvature
    phiGd    = atan( (rK + eSq*c.*s)./rD );
    deltaPhi = phiGd - phiGdOld;
    phiGdOld = phiGd;
  end

  lat = phiGd;
  z   = (rD./cos(phiGd)) - c;
  
else
  lat = sign(rK)*pi/2;
  z   = abs(rK) - a*(1-f);
end

% convert to deg
lat = lat*180/pi;

	

%--------------------------------------
% $Date: 2019-09-09 23:21:42 -0400 (Mon, 09 Sep 2019) $
% $Revision: 49752 $
