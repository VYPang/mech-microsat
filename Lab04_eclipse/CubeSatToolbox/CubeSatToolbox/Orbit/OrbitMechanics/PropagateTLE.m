function [r,v,x] = PropagateTLE( tVec, file, model  )

%% Propagates the NORAD two line elements, ex. SGP, SGP4, SGP8. 
%   SGP4 output is in the TEME frame - true equator, mean equinox.
%   file can be a file name or a string input. The string must have the
%   same format as the file for example:
%
%   s = [sprintf('SGPTest \n'),...
%   sprintf('1 88888U          80275.98708465  .00073094  13844-3  66816-4 0     8\n'),...
%   sprintf('2 88888  72.8435 115.9689 0086731  52.6988  110.5714 16.05824518  105')];
%
%   See also NORAD, LoadNORAD, ConvertNORAD.
%--------------------------------------------------------------------------
%   Form:
%   [r,v,x] = PropagateTLE( tVec, file, model )
%   [r,v,x] = PropagateTLE( tVec, x, model )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   tVec          (1,:)   Time vector (sec)
%   file          (1,:)   File name OR converted data structure
%   model         (1,:)   Model type 'SGP', 'SGP4', 'SDP4', 'SGP8', 'SGD8'
%                           The default model is SGP4.
%
%   -------
%   Outputs
%   -------
%   r      (3,:) or {:}   Position vectors
%   v      (3,:) or {:}   Velocity vectors
%   x             (:)     Structure of NORAD element data
%
%--------------------------------------------------------------------------
%   References:	Hoots, F. R. and R. L. Roehrich, "Spacetrack Report No. 3:
%               Models for Propagation of NORAD Element Sets", Dec. 1980.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1997, 2007 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------

% Less than all arguments
%------------------------
if nargin < 1
  tVec = [];
end

if nargin < 2
  file = [];
end

if( nargin < 3 )
	model = 'SGP4';
end

% Defaults
%---------
if( isempty(tVec) )
  tVec = linspace(0,3600);
end

% Convert time to minutes
%------------------------
secToMin  = 1/60;
tVec      = tVec*secToMin;
nPts      = length(tVec);

% Open the file using the standard dialog box
%--------------------------------------------
if( isempty(file) )
  currentPath = cd;

  [file,path] = uigetfile('*.*','NORAD Datafiles');
  if file == 0
    return
  end

  eval(['cd ''',path,'''']);
end

if isstruct(file)
  % Already loaded
  x = file;
  n = length(x);
else
  % Convert the input data
  %-----------------------
  [x, n] = ConvertNORAD( file );
end

r = {};
v = {};

% Process each set of elements
%-----------------------------
for k = 1:n

  % The propagation models
  %-----------------------
  switch( lower(model) )
    case( 'sgp' )
      rV(k) = SGP ( x(k), tVec, nPts );
	  
    case( 'sgp4' )
      rV(k) = SGP4( x(k), tVec, nPts );
	  
    case( 'sdp4' )
      rV(k) = SGP4( x(k), tVec, nPts, 'deep' );
	  
    case( 'sgp8' )
      rV(k) = SGP8( x(k), tVec, nPts );
	  
    case( 'sdp8' )
      rV(k) = SGP8( x(k), tVec, nPts, 'deep' );
	  
    otherwise
      error('Unidentified model')
		end
	
	% Coordinate frames
	%------------------
	r{k} = rV(k).r*6378.135;
	v{k} = rV(k).v*6378.135*1440.0/86400;
end

if k == 1
  r = r{1};
  v = v{1};
end


function [x, n] = Convert( a )

degToRad = pi/180;
dayToMin = 1440;

% Carriage returns and line feeds
%--------------------------------
kNL = find( a == 10 );
kCR = find( a == 13 );

if( isempty(kNL) )
  kLL = [kCR-1;length(a)];
  kNL = [1; kCR+1];
elseif( isempty(kCR) )
  kLL = [kNL-1;length(a)];
  kNL = [1; kNL+1];
else
  kLL = [min(kNL,kCR)-1;length(a)];
  kNL = [1; max(kNL,kCR)+1];
end

n = length(kNL)/3;
for k = 1:n
  l1 = kNL(3*k-2);
  l2 = kNL(3*k-1);
  l3 = kNL(3*k);
  e1 = kLL(3*k-2);
  e2 = kLL(3*k-1);
  e3 = kLL(3*k);
  x(k).name = char(a(l1:e1)');
  a2        = char(a(l2:e2)');
  a3        = char(a(l3:e3)');
  
  % Line 1
  %-------
  x(k).satelliteNumber  = str2num(a2( 3: 7));
  x(k).launchYear       = str2num(a2(10:11));
  x(k).launchNumber     = str2num(a2(12:14));
  x(k).launchpiece      = str2num(a2(15:17));
  x(k).epochYear        = str2num(a2(19:20));
  x(k).epochJulianDate  = str2num(a2(21:32));
  x(k).ballisticCoeff   = str2num(a2(34:43));  % SDP
  x(k).n0Dot            = str2num(a2(34:43))*2*pi/dayToMin^2;
  x(k).n0DDot           = Str2NumE(a2(45:52))*2*pi/dayToMin^3/1e5;
  x(k).bStar            = Str2NumE(a2(54:61))/1e5;
  x(k).radPressure      = Str2NumE(a2(54:61))/1e5; % SDP
  
  % Line 2
  %-------
	[tok,a3]            =  strtok(a3);
	[tok,a3]            =  strtok(a3);
	[tok,a3]            =  strtok(a3);
  x(k).i0             =  str2num(tok)*degToRad;
	[tok,a3]            =  strtok(a3);
  x(k).f0             =  str2num(tok)*degToRad;
	[tok,a3]            =  strtok(a3);
  x(k).e0             =  str2num(tok)/1e7;
	[tok,a3]            =  strtok(a3);
  x(k).w0             =  str2num(tok)*degToRad;
	[tok,a3]            =  strtok(a3);
  x(k).M0             =  str2num(tok)*degToRad;
	[tok,a3]            =  strtok(a3);
  x(k).n0             =  str2num(tok)*2*pi/dayToMin;
end

%-------------------------------------------------------------------------------
%   Convert input data in the form +NNNNN-N to a double precision number
%-------------------------------------------------------------------------------
%   Form:
%   x = Str2NumE( s )
%-------------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   s		      (1,8)   Data
%
%   -------
%   Outputs
%   -------
%   x         (1,1)   Number
%
%-------------------------------------------------------------------------------
function x = Str2NumE( s )

x  = str2num(s(1:6));
xE = str2num(s(7:8));

x  = x*10^xE;

%-------------------------------------------------------------------------------
%   Convert time from 1950 Jan 0.0 UTC
%-------------------------------------------------------------------------------
%   Form:
%   [theta, dS50] = THETAG( epochYear, epochDay )
%-------------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   epochYear    (1,1)   Last two numbers of the year, i.e. 17, 7
%   epochDay     (1,1)   Number of days into the year
%
%   -------
%   Outputs
%   -------
%   theta        (1,1)   Right ascension of Greenwich at epoch
%   dS50         (1,1)   Days since 1950
%
%-------------------------------------------------------------------------------
function [theta, dS50] = THETAG( epochYear, epochDay )

year = epochYear;
d    = epochDay;

if( year < 10 )
	year = year + 80;
end

if( year < 70 )
	n = floor((year - 72)/4);
else
  n = floor((year - 69)/4);
end

dS50 = 7305 + 365*(year - 70) + n + d;

theta = mod(1.72944494 + 6.3003880987*dS50,2*pi);

if( theta < 0 )
	theta = theta + 2*pi;
end

%-------------------------------------------------------------------------------
%   Arctangent with the result between 0 and 2*pi.
%   z = atan(y/x);
%-------------------------------------------------------------------------------
%   Form:
%   z = ACTan( x, y )
%-------------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   x             (1,1)   x value
%   t             (1,1)   y value
%
%   -------
%   Outputs
%   -------
%   z             (1,1)   Number
%
%-------------------------------------------------------------------------------
function z = ACTan( x, y )

z = atan2( x, y );

kpi   = 3.14159265358979323846;
if z < 0
  z = z + 2*kpi;
end

% This function emulates the numerically inaccurate function used in Norad.f
function y = FMod2Pi( x )
kpi   = 3.14159265358979323846;
%twoPi = 6.2831853; % 2*pi
twoPi = 2*kpi;
k = floor(x/twoPi);
y = x - k*twoPi;
if( y < 0 )
  y = y + twoPi;
end

%-------------------------------------------------------------------------------
%   Propagation models
%-------------------------------------------------------------------------------
%   Form:
%   y = XXX ( x, tVec, nPts )
%-------------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   x             (:,:)   Data structure
%   tVec  		    (1,:)   Time vector (minutes)
%   nPts          (1,1)   Number of points to be computed
%
%   -------
%   Outputs
%   -------
%   y                     Structure for position and velocity vectors
%                         y.v
%                         y.r
%
%-------------------------------------------------------------------------------

%-------------------------------------------------------------------------------
%  SGP
%-------------------------------------------------------------------------------

function y = SGP( x, tVec, nPts )

% Constants
%----------
kE        =    0.743669161e-1;
aE        =    1.0;
j2        =    1.082616e-3;
j3        =   -0.253881e-5;
twoThirds =    2/3;

% Values independent of time since epoch
%---------------------------------------
cI0  = cos(x.i0);
sI0  = sin(x.i0);
e0Sq = x.e0^2;
a1   = (kE/x.n0)^twoThirds;
d1   = 0.75*j2*(aE/a1)^2*(3*cI0^2 - 1)/(1 - e0Sq)^1.5;
a0   = a1*(1 - d1/3 - d1^2 - (134/81)*d1^3);
p0   = a0*(1 - e0Sq);
q0   = a0*(1 - x.e0);
L0   = x.M0 + x.w0 + x.f0;
z    = 3*j2*(aE/p0)^2*x.n0;
dFDT = -z*cI0/2;
dWDT =  z*(5*cI0^2 - 1)/4;
tol  = eps;

y.r  = zeros(3,nPts);
y.v  = zeros(3,nPts);

for k = 1:nPts
	dT = tVec(k);
	a = a0*(x.n0/(x.n0 + (2*x.n0Dot + 3*x.n0DDot*dT)*dT))^twoThirds;
	if( a > q0 )
		e = 1 - q0/a;
	else
		e = 1e-6;
	end
	p     = a*(1 - e^2);
	fS0   = x.f0 + dFDT*dT;
	wS0   = x.w0 + dWDT*dT;
	LS    = L0 + (x.n0 + dWDT + dFDT)*dT + x.n0Dot*dT^2 + x.n0DDot*dT^3;
	z     = 0.5*(j3/j2)*aE*sI0/p;
	aYNSL = e*sin(wS0) - z;
	aXNSL = e*cos(wS0);
	L     = FMod2Pi(LS - 0.5*z*aXNSL*(3 + 5*cI0)/(1 + cI0));
	
	% Solve Kepler's Equation
	%------------------------
	u      = FMod2Pi(L - fS0);
	ePW    = Kepler( u, aYNSL, aXNSL, tol );
	c      = cos(ePW);
	s      = sin(ePW);
	eCosE  = aXNSL*c + aYNSL*s;
	eSinE  = aXNSL*s - aYNSL*c;
	eLSq   = aXNSL^2 + aYNSL^2;
	pL     = a*(1 - eLSq);
	r      = a*(1 - eCosE);
	rDot   = kE*sqrt(a)*eSinE/r;
	rFDot  = kE*sqrt(pL)/r;
	z      = eSinE/(1 + sqrt(1-eLSq));
	sinU   = (a/r)*(s - aYNSL - aXNSL*z);
	cosU   = (a/r)*(c - aXNSL + aYNSL*z);
	u      = atan2(sinU,cosU);
	cos2U  = 2*cosU^2 - 1;
	sin2U  = 2*sinU*cosU;
	z      = j2*(aE/pL)^2;
	rK     = r    + 0.25 *z*pL*sI0^2*cos2U;
	uK     = u    - 0.125*z*(7*cI0^2 - 1)*sin2U;
	fK     = fS0  + 0.75 *z*cI0*sin2U;
	iK     = x.i0 + 0.75 *z*sI0*cI0*cos2U;
	[y.r(:,k),y.v(:,k)] = RV( fK, iK, uK, rK, rDot, rFDot );
end

%-------------------------------------------------------------------------------
%  SGP4
%-------------------------------------------------------------------------------
function [y,d] = SGP4( x, tVec, nPts, useDeep )

d = DefaultSatRec;
d.satnum = x.satelliteNumber;
d.epochyr = x.epochYear;
d.inclo = x.i0;
d.nodeo = x.f0;
d.ecco = x.e0;
d.argpo = x.w0;
d.mo = x.M0;
d.bstar = x.bStar;
d.jdsatepoch = x.julianDate;
d.epochdays = x.epochDay;
d.ndot = x.n0Dot;
d.nddot = x.n0DDot;

% Constants
%----------
true      =    1;
false     =    0;
kE        =    0.743669161e-1;
aE        =    1.0;
rE        = 6378.135;
j2        =    1.082616e-3;
j3        =   -0.253881e-5;
j4        =   -1.65597e-6;
a30       =   -j3*aE^3;
s         = 1.01222928;
q0MS4     = 1.88027916e-9;

if( nargin > 3 || (2*pi/x.n0 >= 225.0) )
  useDeep = true;
else
  useDeep = false;
end

% Values independent of time since epoch
%---------------------------------------
cI0     = cos(x.i0);
sI0     = sin(x.i0);
e0      = x.e0;
e0Sq    = x.e0^2;
a1      = (kE/x.n0)^(2/3);
k2      = 0.5*j2*aE^2;
k4      = -(3/8)*j4*aE^4;
beta0   = sqrt(1 - e0Sq);
beta0Sq = beta0^2;
z       = (3*cI0^2 - 1)/beta0^3;
d1      = 1.5*(k2/a1^2)*z;
a0      = a1*(1 - d1/3 - d1^2 - (134/81)*d1^3);
d0      = 1.5*(k2/a0^2)*z;
% un-kozai the mean motion
n0PP    = x.n0/(1 + d0);
a0PP    =   a0/(1 - d0);

d.no = n0PP;

if( a0PP*(1-e0)/aE < (220/rE + aE) )
  lowAltitude = true;
  d.isimp = 1;
else
  lowAltitude = false;
end

% Adjust s and q0MS4 if s is adjusted
%------------------------------------
rP = (a0PP*(1 - x.e0) - aE)*rE;
if( (rP > 98) & (rP < 156) )
  sStar = (rP - 78)/rE + aE;
	q0MS4 = (q0MS4^0.25 + s - sStar)^4;
	s     = sStar;
elseif( rP < 98 )
	sStar = 20/rE + aE;
	q0MS4 = (q0MS4^0.25 + s - sStar)^4;
	s     = sStar;
end

theta   = cI0; % For consistency with the documentation
theta2  = theta^2;
zeta    = 1/(a0PP - s);
eta     = a0PP*e0*zeta;
etaSq   = eta^2;
fEta    = abs(1 - etaSq);
z       = q0MS4*zeta^4/fEta^3.5; % coefl
en      = e0*eta;

c2 = z*n0PP*(   a0PP*(1 + 1.5*etaSq + en*(4 + etaSq))...
              + 0.75*k2*(zeta/fEta)*(3*theta2 - 1)*(8 + 3*etaSq*(8 + etaSq)));
c1 = x.bStar*c2;
c3 = q0MS4*zeta^5*a30*n0PP*aE*sI0/(k2*e0);
c4 = 2*n0PP*z*a0PP*beta0Sq*( (2*eta*(1 + en) + (e0 + eta^3)/2) - (2*k2*zeta/(a0PP*fEta))...
                              *( 3*(1 - 3*theta2)*(1 + 1.5*etaSq - en*(2 + 0.5*etaSq))...
													     + 0.75*(1 - theta2)*(2*etaSq - en*(1 + etaSq))*cos(2*x.w0)));

IL2 = 1.5*c1;

d.eta = eta;
d.cc1 = c1;
d.cc4 = c4;
d.t2cof = IL2;
d.x1mth2 = 1 - theta2;
d.x7thm1 = (7*theta2 - 1);
d.omgcof = x.bStar*c3*cos(x.w0);
d.con41 = -(1-5*theta2) - theta2 - theta2;

if( lowAltitude == false )
  c5  = 2*z*a0PP*beta0Sq*(1 + 2.75*eta*(eta + e0) + e0*eta^3);
  d2  =     4*a0PP*zeta                    *c1^2;
  d3  = (4/3)*a0PP*zeta^2*( 17*a0PP +    s)*c1^3;
  d4  = (2/3)*a0PP*zeta^3*(221*a0PP + 31*s)*c1^4;
							
  IL3 = d2 + 2*c1^2;
  IL4 = 0.25*(3*d3 + 12*c1*d2 + 10*c1^3);
  IL5 = 0.20*(3*d4 + 12*c1*d3 + 6*d2^2 + 30*c1^2*d2 + 15*c1^4);
  
  d.cc5 = c5;
  d.d2 = d2;
  d.d3 = d3;
  d.d4 = d4;
  d.t3cof = IL3;
  d.t4cof = IL4;
  d.t5cof = IL5;
end

% Constant quantities
%--------------------
a2B4   = a0PP^2*beta0^4;
a4B8   = a2B4^2;

m1 = n0PP*(1 + 3*k2  *(3*theta2 - 1)                 *beta0/( 2*a2B4)...       
             + 3*k2^2*(13 + theta2*(137*theta2 - 78))*beta0/(16*a4B8)...
					);
							
w1 = n0PP*(    3*k2^2*( 7 + theta2*(395*theta2 - 114))/(16*a4B8)...      
             + 5*k4  *( 3 + theta2*( 49*theta2 -  36))/( 4*a4B8)...
						 - 3*k2  *( 1 - 5*theta2)                 /( 2*a2B4)...
					);
							
f1 = n0PP*(   3*k2^2*theta*(4 - 19*theta2)/(2*a4B8)...      
            + 5*k4  *theta*(3 -  7*theta2)/(2*a4B8)...
						- 3*k2  *theta                /(  a2B4)...
					);
			        
if( useDeep == true )
	[cLSP, cSec] = DeepInit( e0Sq, sI0, cI0, beta0, a0PP, theta2, sin(x.w0), cos(x.w0),...      
                           beta0^2, m1, w1, f1, n0PP, x.julianDate,...
										       x.e0, x.i0, x.M0, x.f0, x.w0 );
  d.gsto = cSec.THGR; 
  d.ee2 = cLSP.EE2;
  d.e3 = cLSP.E3;
  d.se2 = cLSP.SE2;
  d.se3 = cLSP.SE3;
  d.sgh2 = cLSP.SGH2;
  d.sgh3 = cLSP.SGH3;
  d.sgh4 = cLSP.SGH4;
  d.sh2 = cLSP.SH2;
  d.sh3 = cLSP.SH3;
  d.si2 = cLSP.SI2;
  d.si3 = cLSP.SI3;
  d.sl2 = cLSP.SL2;
  d.sl3 = cLSP.SL3;
  d.sl4 = cLSP.SL4;
  d.xgh2 = cLSP.XGH2;
  d.xgh3 = cLSP.XGH3;
  d.xgh4 = cLSP.XGH4;
  d.xh2 = cLSP.XH2;
  d.xh3 = cLSP.XH3;
  d.xi2 = cLSP.XI2;
  d.xi3 = cLSP.XI3;
  d.xl2 = cLSP.XL2;
  d.xl3 = cLSP.XL3;
  d.xl4 = cLSP.XL4;
  d.zmol = cLSP.ZMOL;
  d.zmos = cLSP.ZMOS;
  d.dedt = cSec.SSE;
  d.didt = cSec.SSI;
  d.dmdt = cSec.SSL;
  d.dnodt = cSec.SSH;
  d.domdt = cSec.SSG;
end

cM0  = cos(x.M0);
sM0  = sin(x.M0);
sIP  = sI0;

d.mdot = m1;        
d.nodedot = f1;
d.argpdot = w1;
d.sinmao = sM0;
d.delmo  = (1 + eta*cM0)^3;
d.xmcof = -(2/3)*q0MS4*x.bStar*zeta^4*(aE/(e0*eta));
d.nodecf = n0PP*IL2;
if (abs(cI0+1)>1.5e-12)
  d.xlcof = -0.25*j3/j2*sI0*(3 + 5*cI0)/(1 + cI0);
else
  d.xlcof = -0.25*j3/j2*sI0*(3 + 5*cI0)/(1 + cos(pi-1e-9));
end
d0 = d;
clear d;

tol  = eps;

% pre-allocate
y.r  = zeros(3,nPts);
y.v  = zeros(3,nPts);
d(nPts) = d0;

%------------------------------
%  Propagate
%------------------------------
for k = 1:nPts
	dT  = tVec(k);
	mDF = x.M0 + m1*dT;
	wDF = x.w0 + w1*dT;
	fDF = x.f0 + f1*dT;

	f    = fDF - 10.5*n0PP*k2*theta*c1*dT^2/(a0PP^2*beta0Sq);
  tmpa = 1 - c1*dT;
  tmpe = x.bStar*c4*dT;
  tmpl = IL2*dT^2;
  
  d(k) = d0;
  d(k).t = dT;
  d(k).error = 0;
  
	if( useDeep == false )
    % Secular gravity and atmospheric drag
    %-------------------------------------
	  if( lowAltitude == false )
		  dW = d(k).omgcof*dT; % delomg
		  dM = -(2/3)*q0MS4*x.bStar*zeta^4*(aE/(e0*eta))*((1 + eta*cos(mDF))^3 - d(k).delmo); % delm
	    a  = a0PP*(tmpa - d2*dT^2 - d3*dT^3 - d4*dT^4)^2;
	    mP = mDF + dW + dM;
	    w  = wDF - dW - dM;
	    e  = e0 - (tmpe + x.bStar*c5*(sin(mP) - sM0));
	    IL = mP + w + f + n0PP*(IL2 + IL3*dT + IL4*dT^2 + IL5*dT^3)*dT^2;
	  else
	    mP = mDF;
	    w  = wDF;
 	    a  = a0PP*tmpa^2;
	    e  = e0 - tmpe;
 	    IL = mP + w + f + n0PP*tmpl;
    end
		inc = x.i0;
  else
		% Deep space secular terms (dspace)
		%----------------------------------
		[mDS, wDS, fDS, eDS, inc, n0PPDS] = DeepSec( mDF, wDF, f, n0PP, dT, cSec );
	
    if n0PPDS <= 0
      % ST3r
      d(k).error = 2;
    end
    
		a  = (kE/n0PPDS)^(2/3)*tmpa^2;
		e  = eDS - x.bStar*c4*dT;
		
		mDS = mDS + n0PP*tmpl;
		
    if ( e>=1 || e<-0.001 || a<0.95)
      % ST3 revisited
      d(k).error = 1;
    end
    if e < 0.0
      % ST3 revisited
      disp('eccentricity corrected from negative')
      e = 1e-6;
    end

    % Deep space lunar-solar perturbation terms (dpper)
		%--------------------------------------------------
		[e, inc, w, f, mDS] = DeepLSP( e, inc, wDS, fDS, mDS, dT, cLSP );
    
    if (inc < 0)
      % ST3 revisited
      inc = -inc;
      f = f + pi;
      w = w - pi;
      disp('angular quantities changed sign');
    end
    if ( e < 0 || e > 1 )
      % ST3 revisited
      d(k).error = 3;
    end
		
  	IL = mDS + w + f;
    
    % update terms depending on inclination
    sinip = sin(inc);
    theta = cos(inc);
    theta2 = theta^2;
    d(k).aycof = -0.5*j3/j2*sinip;
    if (abs(cos(inc)+1)>1.5e-12)
      d(k).xlcof = -0.25*j3/j2*sinip*(3 + 5*theta)/(1 + theta);
    else
      d(k).xlcof = -0.25*j3/j2*sinip*(3 + 5*theta)/(1 + cos(pi-1e-9));
    end
    d(k).con41 = 3*theta2 - 1;
    d(k).x1mth2 = 1 - theta2;
    d(k).x7thm1 = 7*theta2 - 1;
    sIP = sinip;
    
  end % updated a, e, w, inc, IL, f
  
	beta = sqrt(1-e^2);
	n    = kE/a^1.5;
	sW   = sin(w);
	cW   = cos(w);
  
  % Long period periodics
  %----------------------
	aXN  = e*cW;
	aYNL = a30*sIP/(4*k2*a*beta^2); % ST3r uses sinip and cosip
	aYN  = e*sW + aYNL;
	ILL  = 0.5*aYNL*aXN*(3 + 5*theta)/(1 + theta);
	ILT  = IL + ILL;
	
	% Solve Kepler's Equation
	%------------------------
	u     = FMod2Pi(ILT - f);
	ePW   = Kepler( u, aYN, aXN, 100*eps );
  % Thanks to Derek Surka for info on new tolerance

	% Short period periodics
	%-----------------------
	cE     = cos(ePW);
	sE     = sin(ePW);
	eCosE  = aXN*cE + aYN*sE;
	eSinE  = aXN*sE - aYN*cE;
	eL2    = aXN^2 + aYN^2;
	fEL    = 1 - eL2;
	pL     = a*fEL;
  if pL < 0.0
    % add from SpaceTrack Report 3
    d(k).error = 4;
  end
	r      = a*(1 - eCosE);
	rDot   = kE*sqrt(a)*eSinE/r;
	rFDot  = kE*sqrt(pL)/r;
	betaL  = sqrt(fEL);
	z      = eSinE/(1 + betaL);
	cosU   = (a/r)*(cE - aXN + aYN*z);
	sinU   = (a/r)*(sE - aYN - aXN*z);
	u      = ACTan(sinU,cosU);
	cos2U  = 2*cosU^2 - 1;
	sin2U  = 2*sinU*cosU;
	
	dR     =  0.5 *(k2/pL)*(1 - theta2)*cos2U;
	dU     = -0.25*(k2/pL^2)*(7*theta2 - 1)*sin2U;
	z      =  1.5*k2*theta/pL^2;
	dF     =  z*sin2U;
	dI     =  z*sIP*cos2U;
	dRDot  = -(k2*n/pL)*(1 - theta2)*sin2U;
	dRFDot =  (k2*n/pL)*((1 - theta2)*cos2U - 1.5*(1 - 3*theta2));
  	
	rK     =  r*(1 - 1.5*k2*betaL*(3*theta2 - 1)/pL^2) + dR; % mrt
	uK     =  u + dU;
	fK     =  f + dF;
	iK     =  inc + dI;
	rDotK  =  rDot  + dRDot; % mvt
	rFDotK =  rFDot + dRFDot; % rvdot

  % Position and velocity
  %----------------------
	[y.r(:,k),y.v(:,k)] = RV( fK, iK, uK, rK, rDotK, rFDotK );
  
  if rK < 1.0
    % decay condition
    d(k).error = 6;
  end
end

%-------------------------------------------------------------------------------
%  SGP8
%-------------------------------------------------------------------------------
function y = SGP8( x, tVec, nPts, useDeep )

% Constants
%----------
true      =    1;
false     =    0;
kE        =    0.743669161e-1;
aE        =    1.0;
rE        = 6378.135;
j2        =    1.082616e-3;
j3        =   -0.253881e-5;
j4        =   -1.65597e-6;
a30       =   -j3*aE^3;
s         = 1.01222928;
q0MS4     = 1.88027916e-9;
twoThird  = .66666667;

if( nargin < 4 )
  useDeep = false;
else
  useDeep = true;
end

% Values independent of time since epoch
%---------------------------------------
sI02    = sin(x.i0/2);
cI02    = cos(x.i0/2);
cI0     = 2*cI02^2 - 1;
sI0     = 2*sI02*cI02;
cosW    = cos(x.w0);
sinW    = sin(x.w0);
sin2W   = 2*cosW*sinW;
cos2W   = 2*cosW^2 - 1;
theta   = cI0;
theta2  = theta^2;
e0      = x.e0;
e0Sq    = x.e0^2;
a1      = (kE/x.n0)^0.666667;
k2      = 0.5*j2*aE^2;
k4      = -(3/8)*j4*aE^4;
a30K    = a30/k2;
z       = (3*theta2 - 1)/(1 - e0Sq)^1.5;
d1      = 1.5*(k2/a1^2)*z;
a0      = a1*(1 - d1/3 - d1^2 - (134/81)*d1^3);
d0      = 1.5*(k2/a0^2)*z;
n0PP    = x.n0/(1 + d0);
a0PP    =   a0/(1 - d0);

rho0    = 0.15696615;
b       = 2*x.bStar/rho0;

beta2   = 1 - e0Sq;
beta    = sqrt(beta2);
beta4   = beta2^2;
theta4  = theta2^2;
a2B4    = a0PP^2*beta4;
z       = n0PP*k2/a2B4;
mDot1   = 1.5*z*(3*theta2 - 1)*beta;
wDot1   = 1.5*z*(5*theta2 - 1);
fDot1   = -3.0*z*theta;
z       = n0PP*k2^2;
a4B8    = a2B4^2;
lDot    = n0PP  + mDot1 + 0.1875*z*beta*(13 - 78*theta2 + 137*theta4)/a4B8;
wDot    =         wDot1 + (0.1875*z*( 7 - 114*theta2 + 395*theta4) + 1.25*n0PP*k4*(3 - 36*theta2 + 49*theta4))/a4B8;
fDot    =         fDot1 + (1.5*z*(4 - 19*theta2) + 2.5*n0PP*k4*(3 - 7*theta2))*theta/a4B8;

zeta    = 1/(a0PP*beta2 - s);
eta     = e0*s*zeta;
eta2    = eta^2;
eta3    = eta^3;
eta4    = eta^4;
psi     = sqrt(1 - eta2);
alpha2  = 1 + e0Sq;
alpha   = sqrt(alpha2);
e2      = e0^2;
en      = e0*eta;
en2     = en^2;
psiM2   = abs(1/(1-eta2));
d5      = zeta*psiM2;
p0      = a0PP*beta2;
d1      = d5/(a0PP*beta2);
d2      = 12 + eta2*(36 + 4.5*eta2);
d3      = eta2*(15 + 2.5*eta2);
d4      = eta*(5 +  3.75*eta2);
b1      = -k2*(1 - 3*theta2);
b2      = -k2*(1 -   theta2);
b3      = a30K*sI0;
c0      = 0.5*b*rho0*q0MS4*n0PP*a0PP*zeta^4/(alpha*psi^7);
c1      = 1.5*n0PP*alpha2^2*c0;
c2      = d1*d3*b2;
c3      = d4*d5*b3;
c4      = d1*d3*b2;
c5      = d5*d4*b3;
n0Dot   = c1*((2 + eta2*(3 + 34*e2) + 5*en*(4 + eta2) + 8.5*e2) + d1*d2*b1 + c4*cos2W + c5*sinW);
nDot    = n0Dot;
nDotN   = nDot/n0PP;

if( useDeep == false )

  if( nDotN > 2.16e-3 )
    d6      = 30*eta + 22.5*eta3;
    d7      =  5*eta + 12.5*eta3;
    d8      = 1 + (27/4)*eta2 + eta4;

    % p. 34
    %------
    c8             = d1*d7*b2;
    c9             = d5*d8*b3;
    e0Dot          = -c0*(eta*(4 + eta2 + e2*(15.5 + 7*eta2)) + e*(5 + 15*eta2) + d1*d6*b1 + c8*cos2W + c9*sinW);
    eeDot          = e0*e0Dot;
    alphaDotOAlpha = eeDot/alpha2;
    c6             = n0Dot/(3*n0PP);
    zetaDotOZeta   = 2*a0PP*zeta*(c6*beta2 + eeDot);
    etaDot         = (e0Dot + e0*zetaDotOZeta)*s*zeta;
    psiDotOPsi     = -eta*etaDot/psi^2;
    c0DotOC0       = c6 + 4*zetaDotOZeta - alphaDotOAlpha - 7*psiDotOPsi;
    c1DotOC1       = n0Dot/n0PP + 4*alphaDotOAlpha + c0DotOC0;
    d9             =  6*eta + 20*e0 + 15*e0*eta2 + 68*e2*eta;
    d10            = 20*eta + 5*eta3 + 17*e0 + 68*e0*eta2;
    d11            = 72*eta + 18*eta3;
    d12            = 30*eta + 10*eta3;
    d13            = 5 + 11.25*eta2;
    d14            = zetaDotOZeta - 2*psiDotOPsi;
    d15            = 2*(c6 + eeDot/beta2);
    d1Dot          = d1*(d14 + d15);
    d2Dot          = etaDot*d11;
	
    % p. 35
    %------
    d3Dot  = etaDot*d12;
    d4Dot  = etaDot*d13;
    d5Dot  = d5*d14;
    c2Dot  = b2*(d1Dot*d3 + d1*d3Dot);
    c3Dot  = b3*(d5Dot*d4 + d5*d4Dot);
    wDot   = -(3/2)*n0PP*k2*(1 - 5*theta2)/(a0PP^2*beta4);
    d16    = d9*etaDot + d10*e0Dot + b1*(d1Dot*d2 + d1*d2Dot) + c2Dot*cos2W ...
           + c3Dot*sinW + wDot*(c2*cosW - 2*c2*sin2W);
    n0DDot = n0Dot*c1DotOC1 + c1*d16;
    eDot   = e0Dot;
    eDot2  = eDot^2;
    e0DDot = eDot*c0DotOC0 - c0*(...
             (4 + 3*eta2 + 30*en + 15.5*e2 + 21*en2)*etaDot + (5 + 15*eta2 + 31*en + 14*en*eta)*eDot...
	  			    + b1*(d1Dot*d6 + d1*etaDot*(30 + 67.5*eta2)) + b2*(d1Dot*d7 + d1*etaDot*(5 + 37.5*eta2))*cosW...
	  				  + b3*(d5Dot*d8 + d5*eta*etaDot*(13.5 + 4*eta2))*sinW + wDot*(c5*cosW - 2*c4*sin2W));

    d17    = n0DDot/n0PP - (n0Dot/n0PP)^2;
    zetaDDOZeta = 2*(zetaDotOZeta - c6)*zetaDotOZeta + 2*a0PP*zeta*(d17*beta2/3 - 2*c6*eeDot + eDot2 + e*e0DDot);

    etaDDot = (e0DDot + 2*eDot*zetaDotOZeta)*s*zeta + eta*zetaDDOZeta;
    d18     = zetaDDOZeta - zetaDotOZeta^2;
    d19     = -psiDotOPsi^2*(1 + 1/eta2) - eta*etaDDot/psi^2;
    d1DDot  = d1Dot*(d14 + d15) + d1*(d18 - 2*d19 + 2*d17/3 + 2*alpha2*eDot2/beta4 + 2*e*e0DDot/beta2);

    % p. 36
    %------
    nDDot   = n0DDot;
    eDDot   = e0DDot;
    etaDot2 = etaDot^2;

    n0DDDot = nDot*(4*d17/3 + 3*(eDot/alpha)^2 + 3*e*eDDot/alpha2 - 6*alphaDotOAlpha^2 + 4*d18 - 7*d19)...
            + nDDot*c1DotOC1 + c1*(d16*c1DotOC1 + d9*etaDDot + d10*eDDot + etaDot2*(6 + 30*en + 68*e2)...
  	  			+ etaDot*eDot*(40 + 30*eta2 + 272*en) + eDot2*(17 + 68*eta2)...
	    			+ b1*(d1DDot*d2 + 2*d1Dot*d2Dot + d1*(etaDDot*d11 + etaDot2*(72 + 54*eta2)))...
  	  			+ b2*(d1DDot*d3 + 2*d1Dot*d3Dot + d1*(etaDDot*d12 + etaDot2*(30 + 30*eta2)))*cos2W...
  	  			+ b3*((d5Dot*d14 + d5*(d18 - 2*d19))*d4 + 2*d4Dot*d5Dot + d5*(etaDDot*d13 + 22.5*eta*etaDot^2))*sinW...
  	  			+ wDot*((7*c6 + 4*e*eDot/beta2)*(c3*cosW - 2*c2*sin2W) + 2*c3*cosW...
  	  			- 4*c2*sin2W - wDot*(c3*sinW + 4*c2*cos2W)));
  end

% Use the deep space modifications
%---------------------------------
else
	[cLSP, cSec] = DeepInit( e0Sq, sI0, cI0, beta, a0PP, theta2, sin(x.w0), cos(x.w0),...      
                           beta2, lDot, wDot, fDot, n0PP, x.julianDate,...
										       x.e0, x.i0, x.M0, x.f0, x.w0 );
end
				
y.r  = zeros(3,nPts);
y.v  = zeros(3,nPts);

for k = 1:nPts
	dT = tVec(k);
	
	if( useDeep == false )
		
	  % p. 37
	  %------
	  M = FMod2Pi( x.M0 + lDot*dT );
	  w = x.w0 + wDot*dT;
	  f = x.f0 + fDot*dT;
	
	  if( nDotN > 2.16e-3 )
		  p     = (2*n0DDot^2 - n0Dot*n0DDDot)/(n0DDot^2 - n0Dot*n0DDDot);
		  gamma = - n0DDDot/(n0DDot*(p-2));
		  z1    = n0Dot*(dT + ((1 - gamma*dT)^(p+1)-1)/(gamma*(p+1)))/(p*gamma);
		  nD    = n0Dot/(p*gamma);
		  q     = 1 - e0DDot/(e0Dot*gamma);
		  eD    = e0Dot/(q*gamma);
		  n     = n0PP + nD*(1 - (1 - gamma*dT)^p);
		  e     = e0   + eD*(1 - (1 - gamma*dT)^q);
	  else
		  eDot  = -twoThird*nDotN*(1 - e0);
		  n     = n0PP + nDot*dT;
		  e     = e0   + eDot*dT;
		  z1    = 0.5*nDot*dT^2;
	  end
	
	  z7 = 7*z1/(3*n0PP);
    M  = FMod2Pi(M + z1 + z7*mDot1);
	  w  = w + z7*wDot1;
	  f  = f + z7*fDot1;
	else

		eDot  = -twoThird*nDotN*(1 - e0);
		z1    = 0.5*n0Dot*dT^2;
		z7    = 3.5*twoThird*z1/n0PP;
		mDF   = x.M0 + lDot*dT;
		wDF   = x.w0 + wDot*dT + z7*wDot1;
		fDF   = x.f0 + fDot*dT + z7*fDot1;
		
	  % Deep space secular terms
		%-------------------------
		[mDS, wDS, fDS, eDS, inc, n0PPDS] = DeepSec( mDF, wDF, fDF, n0PP, dT, cSec );
		
		n  = n0PPDS + n0Dot*dT;
		e  = eDS    +  eDot*dT;
		M  = mDS    + z1 + mDot1*z7;
		
		% Deep space lunar solar perturbation terms
		%------------------------------------------
		[e, inc, w, f, M] = DeepLSP( e, inc, wDS, fDS, M, dT, cLSP );
    
    theta = cos(inc);
    theta2 = theta^2;
    sI0 = sin(inc);

	end
	
	M = FMod2Pi( M );
	E = M + e*sin(M)*(1 + e*cos(M));
  for j = 1:10;
	  E = E + (M + e*sin(E) - E)/(1 - e*cos(E));
  end
	
	% p. 38
	%------
	sinE    = sin(E);
	cosE    = cos(E);
	sinW    = sin(w);
	cosW    = cos(w);
	aXNM    = e*cosW;
	aYNM    = e*sinW;
	a       = (kE/n)^twoThird;
	beta2   = 1 - e^2;
	p       = a*beta2;
	beta4   = beta2^2;
	beta    = sqrt(beta2);
	sinF    = beta*sinE /(1 - e*cosE);
	cosF    = (cosE - e)/(1 - e*cosE);
	fM      = ACTan(sinF,cosF);
	eSinF   = e*sinF;
	eCosF   = e*cosF;
	sinU    = sinF*cosW + cosF*sinW;
	cosU    = cosF*cosW - sinF*sinW;
	sin2U   = 2*sinU*cosU;
	cos2U   = 2*cosU^2 - 1;
	rPP     = p/(1 + eCosF);
	aOR     = a/rPP;
	
	dR      = 0.5*(k2/p)*((1-theta2)*cos2U + 3*(1 - 3*theta2)) - 0.25*a30K*sI0*sinU;
	dRDot   = -n*aOR^2*((k2/p)*(1-theta2)*sin2U + 0.25*a30K*sI0*cosU);
	dI      = theta*(1.5*(k2/p^2)*sI0*cos2U - 0.25*a30K*e*sinW/p);
	
	g1      = 1/p;
	g2      = .5*k2*g1;
	g3      = g1*g2;
 	g5      = 0.25*a30K*g1;
	dRFDot  = -n*aOR^2*dR + n*a*aOR*sI0*dI/theta;
	g10     = fM - M + eSinF;
	qq1     = .5*(1 - 7*theta2)*sin2U - 3*(1 - 5*theta2)*g10;
	qq2     = 2 + eCosF;
	dU      = sI02*(g3*qq1-g5*sI0*cosU*qq2)-.5*g5*theta2*aXNM/cI02;
	
	% p. 39
	%------
  r       = rPP            + dR;
	rDot    = n*a*eSinF/beta + dRDot;
	rFDot   = n*a^2*beta/rPP + dRFDot;
  if( useDeep )
    sI2 = sin( 0.5*inc );
	else
		sI2 = sI02;
	end
	y4      = sI2*sinU + cosU*dU + 0.5*sinU*cI02*dI;
	y5      = sI2*cosU - sinU*dU + 0.5*cosU*cI02*dI;
	lambda  = fM + w + f + g3*(.5*(1+6*theta-7.*theta2)*sin2U - 3*((1 - 5*theta2)+2.*theta)*g10) + g5*sI0*(theta*aXNM/(1.+theta)-(2	+ eCosF)*cosU);
	cL      = cos( lambda );
	sL      = sin( lambda );
	temp1   = 2*(y5*sL - y4*cL);
	temp2   = 2*(y5*cL + y4*sL);
	temp3   = 2*sqrt(1 - y4^2 - y5^2);
	
	u       = [ y4*temp1 + cL;...
	           -y4*temp2 + sL;...
							y4*temp3];
								
	v       = [ y5*temp1 - sL;...
	           -y5*temp2 + cL;...
							y5*temp3];
							
	% p. 40
	%------
	y.r(:,k) = r*u;
	y.v(:,k) = rDot*u + rFDot*v;
end

%-------------------------------------------------------------------------------
%  Orientation vectors
%-------------------------------------------------------------------------------
function [r, v] = RV( fK, iK, uK, rK, rDot, rFDot )
cF     = cos(fK);
sF     = sin(fK);
cI     = cos(iK);
sI     = sin(iK);
M      = [-sF*cI;cF*cI;sI];
N      = [cF;sF;0];
cUK    = cos(uK);
sUK    = sin(uK);
U      = M*sUK + N*cUK;
V      = M*cUK - N*sUK;
r      = rK*U;
v      = rDot*U + rFDot*V;

function ePW = Kepler( u, aYNSL, aXNSL, tol )
% spacetrack revisited tol is 1.e-12
ePW   = u;
delta = 1;
ktr   = 1;
while( abs(delta/ePW) > tol );
	c     = cos(ePW);
	s     = sin(ePW);
	delta = (u - aYNSL*c + aXNSL*s - ePW)/(1 - aYNSL*s - aXNSL*c);
	if( abs(delta) >= 0.95 ) % previously 1
		delta = 0.95*sign(delta);
	end
	ePW   = ePW + delta;
  ktr = ktr + 1;
end

function [c, d] = DeepInit( EQSQ, SINIQ, COSIQ, RTEQSQ, AO, COSQ2, SINOMO, COSOMO,...      
                            BSQ, XLLDOT, OMGDT, XNODOT, XNODP, epoch,...
											      EO, XINCL, XMO, XNODEO, OMEGAO )
%-------------------------------------------------------------------------------
%   Deep space perturbations
%-------------------------------------------------------------------------------
%   Form:
%   c = DeepInit( EQSQ, SINIQ, COSIQ, RTEQSQ, AO, COSQ2, SINOMO, COSOMO,...
%                 BSQ, XLLDOT, OMGDT, XNODOT, XNODP, epoch,...
%									EO, XINCL, XMO, XNODEO, OMEGAO )
%-------------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%
%   -------
%   Outputs
%   -------
%   c             (:,:)   Data structure for lunar solar perturbations
%   d             (:,:)   Data structure for secular terms
%
%-------------------------------------------------------------------------------

% p. 59
%------
ZNS    =  1.19459e-5;
C1SS   =  2.9864797e-6;
ZES    =  0.01675;
ZNL    =  1.5835218e-4;
C1L    =  4.7968065e-7;
ZEL    =  0.05490;
ZCOSIS =  0.91744867;
ZSINIS =  0.39785416;
ZSINGS = -0.98088458;
ZCOSGS =  0.1945905;
ZCOSHS =  1.0;
ZSINHS =  0.0;
Q22    =  1.7891679e-6;
Q31    =  2.1460748e-6;
Q33    =  2.2123015e-7;
ROOT22 =  1.7891679e-6;
ROOT32 =  3.7393792e-7;
ROOT44 =  7.3636953e-9;
ROOT52 =  1.1428639e-7;
ROOT54 =  2.1765803e-9;
THDT   =  4.3752691e-3;

%[THGR, DS50] = THETAG( epoch );
DS50   = epoch - 2433281.5;
THGR   = GMSTime( epoch )*pi/180;
EQ     = EO;
XNQ    = XNODP;
AQNV   = 1/AO;
XQNCL  = XINCL;
XMAO   = XMO;
XPIDOT = OMGDT + XNODOT;
SINQ   = sin(XNODEO);
COSQ   = cos(XNODEO);
OMEGAQ = OMEGAO;
		
% SpaceTrack revisited
irez = 0;
if (XNQ < 0.0052359877 & XNQ > 0.0034906585)
  irez = 1;
end
if (XNQ >= 8.26E-3 & XNQ <= 9.24E-3 & EQ >= 0.5)
  irez = 2;
end

% INITIALIZE LUNAR SOLAR TERMS
%-----------------------------
DAY     = DS50 + 18261.5;
XNODCE  = 4.5236020 - 9.2422029e-4*DAY;

% p. 58
%------
STEM   = sin( XNODCE );
CTEM   = cos( XNODCE );
ZCOSIL = 0.91375164 - 0.03568096*CTEM;
ZSINIL = sqrt(1 - ZCOSIL^2);
ZSINHL = 0.089683511*STEM/ZSINIL;
ZCOSHL = sqrt(1 - ZSINHL^2);
C      = 4.7199672 + 0.22997150*DAY;
GAM    = 5.8351514 + 0.0019443680*DAY;
ZMOL   = FMod2Pi(C - GAM);
ZX     = 0.39785416*STEM/ZSINIL;
ZY     = ZCOSHL*CTEM + 0.91744867*ZSINHL*STEM;
ZX     = ACTan( ZX, ZY );
ZX     = GAM + ZX - XNODCE;
ZCOSGL = cos( ZX );
ZSINGL = sin( ZX );
ZMOS   = 6.2565837 + 0.017201977*DAY;
ZMOS   = FMod2Pi( ZMOS );

% DO SOLAR TERMS
%---------------
SAVTSN = 1e20;
ZCOSG  = ZCOSGS;
ZSING  = ZSINGS;
ZCOSI  = ZCOSIS;
ZSINI  = ZSINIS;
ZCOSH  = COSQ;
ZSINH  = SINQ;
CC     = C1SS;
ZN     = ZNS;
ZE     = ZES;
ZMO    = ZMOS;
XNOI   = 1/XNQ;

for LS = 1:2
	A1  =  ZCOSG*ZCOSH + ZSING*ZCOSI*ZSINH;
  A3  = -ZSING*ZCOSH + ZCOSG*ZCOSI*ZSINH;
  A7  = -ZCOSG*ZSINH + ZSING*ZCOSI*ZCOSH;
  A8  =  ZSING*ZSINI;
  A9  =  ZSING*ZSINH + ZCOSG*ZCOSI*ZCOSH;
  A10 =  ZCOSG*ZSINI;
  A2  =  COSIQ*A7  + SINIQ*A8;
  A4  =  COSIQ*A9  + SINIQ*A10;
  A5  = -SINIQ*A7  + COSIQ*A8;
  A6  = -SINIQ*A9  + COSIQ*A10;
  X1  =  A1*COSOMO + A2*SINOMO;
  X2  =  A3*COSOMO + A4*SINOMO;
  X3  = -A1*SINOMO + A2*COSOMO;

  % p. 60
	%------
  X4  = -A3*SINOMO + A4*COSOMO;
  X5  =  A5*SINOMO;
  X6  =  A6*SINOMO;
  X7  =  A5*COSOMO;
  X8  =  A6*COSOMO;
 
  Z31 =  12*X1^2  - 3*X3^2;
  Z32 =  24*X1*X2 - 6*X3*X4;
  Z33 =  12*X2^2  - 3*X4^2;
  Z1  =   3*(A1^2  + A2^2)  + Z31*EQSQ;
  Z2  =   6*(A1*A3 + A2*A4) + Z32*EQSQ;
  Z3  =   3*(A3^2  + A4^2)  + Z33*EQSQ;
  Z11 =  -6*A1*A5 + EQSQ*(-24*X1*X7 - 6*X3*X5);
  Z12 =  -6*(A1*A6 + A3*A5) + EQSQ *(-24*(X2*X7 + X1*X8) - 6*(X3*X6 + X4*X5));
  Z13 =  -6*A3*A6 + EQSQ *(-24*X2*X8 - 6*X4*X6);
  Z21 =   6*A2*A5 + EQSQ *( 24*X1*X5 - 6*X3*X7);
  Z22 =   6*(A4*A5 + A2*A6) + EQSQ *(24*(X2*X5 + X1*X6) - 6*(X4*X7 + X3*X8));
  Z23 =   6*A4*A6 + EQSQ*(24*X2*X6 - 6*X4*X8);
  Z1  =   2*Z1 + BSQ*Z31;
  Z2  =   2*Z2 + BSQ*Z32;
  Z3  =   2*Z3 + BSQ*Z33;
  S3  =   CC*XNOI;
  S2  = -0.5*S3/RTEQSQ;
  S4  =   S3*RTEQSQ;
  S1  = -15*EQ*S4;
  S5  =  X1*X3 + X2*X4;
  S6  =  X2*X3 + X1*X4;
  S7  =  X2*X4 - X1*X3;
  SE  =  S1*ZN*S5;
  SI  =  S2*ZN*(Z11 + Z13);
  SL  = -ZN*S3*(Z1 + Z3 - 14 - 6*EQSQ);
  SGH =  S4*ZN*(Z31 + Z33 - 6);
			
  if( XQNCL < 5.2359877e-2  || XQNCL > pi - 5.2359877e-2 ) % inclm
	  SH = 0;
  else
    SH = -ZN*S2*(Z21 + Z23);
  end
		
  EE2  =   2*S1*S6;
  E3   =   2*S1*S7;
	XI2  =   2*S2*Z12;
	XI3  =   2*S2*(Z13 - Z11);
	XL2  =  -2*S3*Z2;
	XL3  =  -2*S3*(Z3 - Z1);
	XL4  =  -2*S3*(-21 - 9*EQSQ)*ZE;
	XGH2 =   2*S4*Z32;
	XGH3 =   2*S4*(Z33 - Z31);
	XGH4 = -18*S4*ZE;
	XH2  =  -2*S2*Z22;
	XH3  =  -2*S2*(Z23 - Z21);
		
  % p. 60
	%------
	
	% DO LUNAR TERMS
	%---------------
  if( LS == 1 )
    SSE   = SE;
    SSI   = SI;
    SSL   = SL;
    SSH   = SH/SINIQ;
    SSG   = SGH - COSIQ*SSH;
    SE2   = EE2;
    SI2   = XI2;
    SL2   = XL2;
    SGH2  = XGH2;
    SH2   = XH2;
    SE3   = E3;
    SI3   = XI3;
    SL3   = XL3;
    SGH3  = XGH3;
    SH3   = XH3;
    SL4   = XL4;
    SGH4  = XGH4;
    ZCOSG = ZCOSGL;
    ZSING = ZSINGL;
    ZCOSI = ZCOSIL;
    ZSINI = ZSINIL;
    ZCOSH = ZCOSHL*COSQ + ZSINHL*SINQ;
    ZSINH = SINQ*ZCOSHL - COSQ*ZSINHL;
    ZN    = ZNL;
    CC    = C1L;
    ZE    = ZEL;
    ZMO   = ZMOL;
	end
end
SSE = SSE + SE;
SSI = SSI + SI;
SSL = SSL + SL;
SSG = SSG + SGH - COSIQ/SINIQ*SH;
SSH = SSH + SH/SINIQ;

% GEOPOTENTIAL RESONANCE INITIALIZATION FOR 12&24 HOUR ORBITS
%------------------------------------------------------------
IRESFL = 0;
ISYNFL = 0;
intInit = 0;
if( irez ~= 0 )
		
  if( irez == 2 )		
    % 12 hour orbits
    IRESFL = 1;
    EOC    = EQ*EQSQ;
    G201   = -0.306 - (EQ - 0.64)*0.440;

    % p. 63
    %------
    if( EQ <= 0.65 )
      G211 =     3.616   -   13.247 *EQ +   16.290 *EQSQ;
      G310 =   -19.302   +  117.390 *EQ -  228.419 *EQSQ +    156.591 *EOC;
      G322 =   -18.9068  +  109.7927*EQ -  214.6334*EQSQ +    146.5816*EOC;
      G410 =   -41.122   +  242.694 *EQ -  471.094 *EQSQ +    313.953 *EOC;
      G422 =  -146.407   +  841.880 *EQ - 1629.014 *EQSQ +   1083.435 *EOC;
      G520 =  -532.114   + 3017.977 *EQ - 5740.032 *EQSQ +   3708.276 *EOC;
    else
      G211 =   -72.099   +   331.819*EQ -   508.738*EQSQ +    266.724 *EOC;
      G310 =  -346.844   +  1582.851*EQ -  2415.925*EQSQ +   1246.113 *EOC;
      G322 =  -342.585   +  1554.908*EQ -  2366.899*EQSQ +   1215.972 *EOC;
      G410 = -1052.797   +  4758.686*EQ -  7193.992*EQSQ +   3651.957 *EOC;
      G422 = -3581.69    + 16178.11 *EQ - 24462.77 *EQSQ +  12422.52  *EOC;
      if( EQ <= 0.715 )
        G520 =  1464.74  -  4664.75 *EQ +  3763.64 *EQSQ;
      else
        G520 = -5149.66  + 29936.92 *EQ - 54087.36 *EQSQ +  31324.56  *EOC;
      end
    end
		
    if( EQ <= 0.7 )
      G533 =  -919.2277  + 4988.61  *EQ - 9064.77  *EQSQ +   5542.21  *EOC;
      G521 =  -822.71072 + 4568.6173*EQ - 8491.4146*EQSQ +   5337.524 *EOC;
      G532 =  -853.666   + 4690.25  *EQ - 8624.77  *EQSQ +   5341.4   *EOC;
    else
      G533 = -37995.78   + 161616.52*EQ - 229838.2 *EQSQ + 109377.94  *EOC;
      G521 = -51752.104  + 218913.95*EQ - 309468.16*EQSQ + 146349.42  *EOC;
	    G532 = -40023.88   + 170470.89*EQ - 242699.48*EQSQ + 115605.82  *EOC;
    end
		
    SINI2 = SINIQ^2;
    F220  =  0.75*(1 + 2*COSIQ + COSQ2);
    F221  =  1.5*SINI2;
    F321  =  1.875*SINIQ*(1 - 2*COSIQ - 3*COSQ2);
    F322  = -1.875*SINIQ*(1 + 2*COSIQ - 3*COSQ2);
    F441  = 35*SINI2*F220;
    F442  = 39.3750*SINI2^2;
    F522  =  9.84375*SINIQ*(SINI2*  ( 1 - 2*COSIQ - 5*COSQ2) + 0.33333333*(-2 + 4*COSIQ + 6*COSQ2));
    F523  = SINIQ*(4.92187512*SINI2*(-2 - 4*COSIQ+10.*COSQ2) + 6.56250012*( 1 + 2*COSIQ - 3*COSQ2));
    F542  = 29.53125*SINIQ*( 2 - 8*COSIQ + COSQ2*(-12 + 8*COSIQ + 10*COSQ2));
    F543  = 29.53125*SINIQ*(-2 - 8*COSIQ + COSQ2*( 12 + 8*COSIQ - 10*COSQ2));
    XNO2  = XNQ^2;
    AINV2 = AQNV^2;
    TEMP1 = 3.*XNO2*AINV2;
    TEMP  = TEMP1*ROOT22;
    D2201 = TEMP*F220*G201;
    D2211 = TEMP*F221*G211;
    TEMP1 = TEMP1*AQNV;
    TEMP  = TEMP1*ROOT32;
    D3210 = TEMP*F321*G310;

    % p. 63
    %------
    D3222 = TEMP*F322*G322;
    TEMP1 = TEMP1*AQNV;
    TEMP  = 2*TEMP1*ROOT44;
    D4410	= TEMP*F441*G410;
    D4422	= TEMP*F442*G422;
    TEMP1	= TEMP1*AQNV;
    TEMP	= TEMP1*ROOT52;
    D5220	= TEMP*F522*G520;
    D5232	= TEMP*F523*G532;
    TEMP  = 2*TEMP1*ROOT54;
    D5421 = TEMP*F542*G521;
    D5433 = TEMP*F543*G533;
    XLAMO = XMAO   + 2*(XNODEO - THGR);
    BFACT = XLLDOT + 2*(XNODOT - THDT);
    BFACT = BFACT  + SSL + 2*SSH;
    
    DEL1 = 0;
    DEL2 = 0;
    DEL3 = 0;
	else
    D2201 = 0;
    D2211 = 0;
    D3210 = 0;
    D3222 = 0;
    D4410 = 0;
    D4422 = 0;
    D5220 = 0;
    D5232 = 0;
    D5421 = 0;
    D5433 = 0;

    % SYNCHRONOUS RESONANCE TERMS INITIALIZATION
    %-------------------------------------------
    % irez == 1

    IRESFL  = 1;
    ISYNFL  = 1;
    G200    = 1 + EQSQ*(-2.5 + 0.8125 *EQSQ);
    G310    = 1 + 2*EQSQ;
    G300    = 1 + EQSQ*(-6.0 + 6.60937*EQSQ);
    F220    = 0.75*(1 + COSIQ)^2;
    F330    = 1 + COSIQ;
    F311    = 0.9375*SINIQ^2*(1 + 3*COSIQ) - 0.75* F330;
    F330    = 1.875*F330^3;
    DEL1    = 3*XNQ^2*AQNV^2;
    DEL2    = 2*DEL1*F220*G200*Q22;
    DEL3    = 3*DEL1*F330*G300*Q33*AQNV;
    DEL1    = DEL1*F311*G310*Q31*AQNV;
    XLAMO   = XMAO + XNODEO + OMEGAO - THGR;
    BFACT   = XLLDOT + XPIDOT - THDT;
    BFACT   = BFACT + SSL + SSG + SSH;
  end
  intInit = 1;
end

% Place variables in the output data structure
c.SAVTSN = SAVTSN;
c.ZMOS   = ZMOS;
c.ZNS    = ZNS;
c.ZES    = ZES;
c.SE2    = SE2;
c.SE3    = SE3;
c.SI2    = SI2;
c.SI3    = SI3;
c.SL2    = SL2;
c.SL3    = SL3;
c.SL4    = SL4;
c.SGH2   = SGH2;
c.SGH3   = SGH3;
c.SGH4   = SGH4;
c.SH2    = SH2;
c.SH3    = SH3;
c.ZMOL   = ZMOL;
c.ZNL    = ZNL;
c.ZEL    = ZEL;
c.EE2    = EE2;
c.E3     = E3;
c.XI2    = XI2;
c.XI3    = XI3;
c.XL2    = XL2;
c.XL3    = XL3;
c.XL4    = XL4;
c.XGH2   = XGH2;
c.XGH3   = XGH3;
c.XGH4   = XGH4;
c.XH2    = XH2;
c.XH3    = XH3;
c.XQNCL  = XQNCL;
c.SINIQ  = SINIQ;
c.COSIQ  = COSIQ;

d.irez   = irez;
d.THGR   = THGR;
d.EO     = EO;
d.XINCL  = XINCL;
d.SSL    = SSL;
d.SSG    = SSG;
d.SSH    = SSH;
d.SSE    = SSE;
d.SSI    = SSI;
d.IRESFL = IRESFL;
d.ISYNFL = ISYNFL;
d.XNQ    = XNQ;

if( intInit == 1 )
  XFACT    = BFACT - XNQ;
 
  % INITIALIZE INTEGRATOR
  %----------------------
  XLI      =  XLAMO;
  XNI      =  XNQ;
  d.XFACT  = XFACT;  % sgp4fix
  d.XLAMO  = XLAMO;
  d.D2201  = D2201;
  d.D2211  = D2211;
  d.D3210  = D3210;
  d.D3222  = D3222;
  d.D4410  = D4410;
  d.D4422  = D4422;
  d.D5220  = D5220;
  d.D5232  = D5232;
  d.D5421  = D5421;
  d.D5433  = D5433;
  d.D2201  = D2201;
  d.D2211  = D2211; 
  d.D3210  = D3210;
  d.D3222  = D3222;
  d.D5220  = D5220;
  d.D5232  = D5232;
  d.D4410  = D4410;
  d.D4422  = D4422;
  d.D5421  = D5421;
  d.D5433  = D5433;
  d.DEL1   = DEL1;
  d.DEL2   = DEL2;
  d.DEL3   = DEL3;
  d.OMGDT  = OMGDT;
  d.OMEGAQ = OMEGAQ;	
end

function [EM, XINC, OMGASM, XNODES, XLL] = DeepLSP( EM, XINC, OMGASM, XNODES, XLL, T, c)
%-------------------------------------------------------------------------------
%   Deep space perturbations
%-------------------------------------------------------------------------------
%   Form:
%   [EM, XINC, OMGASM, XNODES, XLL] = DeepLSP( EM, XINC, OMGASM, XNODES, XLL, T, c)
%-------------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   c             (:,:)   Data structure of initialization variables
%                         c.SAVTSN
%                         c.ZMOS
%                         c.ZNS
%                         c.ZES
%                         c.SE2
%                         c.SE3
%                         c.SI2
%                         c.SI3
%                         c.SL2
%                         c.SL3
%                         c.SL4
%                         c.SGH2
%                         c.SGH3
%                         c.SGH4
%                         c.SH2
%                         c.SH3
%                         c.ZMOL
%                         c.ZNL
%                         c.ZEL
%                         c.EE2
%                         c.E3
%                         c.XI2
%                         c.XI3
%                         c.XL2
%                         c.XL3
%                         c.XL4
%                         c.XGH2
%                         c.XGH3
%                         c.XGH4
%                         c.XH2
%                         c.XH3
%                         c.XQNCL
%                         c.SINIQ
%                         c.COSIQ
%
%   -------
%   Outputs
%   -------
%   EM       Eccentricity
%   XINC     Inclination
%   OMGASM   Right ascension of ascending node
%   XNODES   Argument of perigee
%   XLL      Mean anomaly
%
%-------------------------------------------------------------------------------

% p. 66
%------
SINIS = sin(XINC);
COSIS = cos(XINC);

PGH    =  0;
PH     =  0;
if( T == 0 ) % Note: this line doesn't match Revisited
  ZM     =  c.ZMOS;
else
	ZM     =  c.ZMOS + c.ZNS*T;
end
ZF     =  ZM + 2*c.ZES*sin(ZM);
SINZF  =  sin(ZF);
F2     =  0.5*SINZF^2 - 0.25;
F3     = -0.5*SINZF*cos(ZF);
SES    =  c.SE2 *F2 + c.SE3 *F3;
SIS    =  c.SI2 *F2 + c.SI3 *F3;
SLS    =  c.SL2 *F2 + c.SL3 *F3 + c.SL4 *SINZF;
SGHS   =  c.SGH2*F2 + c.SGH3*F3 + c.SGH4*SINZF;
SHS    =  c.SH2 *F2 + c.SH3 *F3;
ZM     =  c.ZMOL + c.ZNL*T;
ZF     =  ZM + 2*c.ZEL*sin(ZM);
SINZF  =  sin(ZF);
F2     =  0.5*SINZF^2 - 0.25;
F3     = -0.5*SINZF*cos(ZF);
SEL    =  c.EE2 *F2 + c.E3  *F3;
SIL    =  c.XI2 *F2 + c.XI3 *F3;
SLL    =  c.XL2 *F2 + c.XL3 *F3 +  c.XL4*SINZF;
SGHL   =  c.XGH2*F2 + c.XGH3*F3 + c.XGH4*SINZF;
SHL    =  c.XH2 *F2 + c.XH3 *F3;
PE     =  SES + SEL;
PINC   =  SIS + SIL;
PL     =  SLS + SLL;
PGH    =  SGHS + SGHL;
PH     =  SHS  + SHL;
XINC   =  XINC + PINC;
EM     =  EM   + PE;
	
%	APPLY PERIODICS DIRECTLY
%------------------------- 
% SpaceTrack Report 3 used original inclination
% if( c.XQNCL >= 0.2 )
% sgp4fix: GSFC used perturbed inclination
sinip = sin(XINC); 
cosip = cos(XINC); 
if( XINC >= 0.2 )
  PH     = PH/sinip;
  PGH    = PGH    - cosip*PH;
  OMGASM = OMGASM + PGH;
  XNODES = XNODES + PH;
  XLL    = XLL    + PL;
else
 
  % APPLY PERIODICS WITH LYDDANE MODIFICATION
  %------------------------------------------ 
  SINOK = sin(XNODES);

  % p. 68
  %------
  COSOK  =  cos(XNODES);
  ALFDP  =  sinip*SINOK; % Note: change from SINIS to sinip
  BETDP  =  sinip*COSOK; % Note: change from SINIS to sinip
  DALF   =  PH*COSOK + PINC*cosip*SINOK;
  DBET   = -PH*SINOK + PINC*cosip*COSOK;
  ALFDP  =  ALFDP + DALF;
  BETDP  =  BETDP + DBET;
  XLS    =  XLL + OMGASM + cosip*XNODES;
  DLS    =  PL + PGH - PINC*XNODES*sinip;
  XLS    =  XLS + DLS;
  XNODE0 = XNODES;
  XNODES =  ACTan( ALFDP, BETDP );
  % sgp4fix for quadrant shift
  if (abs(XNODE0 - XNODES) > pi)
    if (XNODES < XNODE0)
      XNODES = XNODES + 2*pi;
    else
      XNODES = XNODES - 2*pi;
    end
  end
  XLL    =  XLL + PL;
  OMGASM =  XLS - XLL - cosip*XNODES;
end

function [XLL, OMGASM, XNODES, EM, XINC, XN] = DeepSec( XLL, OMGASM, XNODES, XN, T, c )
%-------------------------------------------------------------------------------
%   Deep space perturbations * dspace
%-------------------------------------------------------------------------------
%   Form:
%   [XLL, OMGASM, XNODES, EM, XINC, XN] = DeepSec( XLL, OMGASM, XNODES, XN, T, c )
%-------------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   c             (:,:)   Data structure of initialization variables
%
%   -------
%   Outputs
%   -------
%   x             (:,:)   Data structure
%
%-------------------------------------------------------------------------------
		
FASX2   = 0.13130908;
FASX4   = 2.8843198;
FASX6   = 0.37448087;
STEPP   =  720;
STEPN   = -720;
STEP2   =  259200;
G22    =  5.7686396;
G32    =  0.95240898;
G44    =  1.8014998;
G52    =  1.0508330;
G54    =  4.4108898;
THDT   =  4.3752691e-3;

% Dep space resonance effects
XLL    = XLL      + c.SSL*T;
OMGASM = OMGASM   + c.SSG*T;
XNODES = XNODES   + c.SSH*T;
EM     = c.EO     + c.SSE*T;
XINC   = c.XINCL  + c.SSI*T;

% sgp4fix
% if( XINC < 0 )
%   XINC   = -XINC;
%   XNODES =  XNODES + pi;
%   OMGASM =  OMGASM - pi;
% end

if( c.IRESFL == 0)
  return;
end
	
integrate = 1;
ATIME     = 0;
	
while( 1 )
		
  % EPOCH RESTART
  %--------------
  if( ( ATIME == 0 ) | ( T >= 0 & ATIME <  0 ) | ( T < 0 & ATIME >= 0 ) )
    if( T < 0 )
      DELT = STEPN;
    else
      DELT = STEPP;
    end
    XNI       = c.XNQ;
    XLI       = c.XLAMO;
    integrate = 1;
  else
    if( abs(T) >= abs(ATIME))
      if( T > 0 )
        DELT = STEPP;
      else
        DELT = STEPN;
      end
    else
      if( T >= 0 )
        DELT = STEPN;
      else
        DELT = STEPP;
		  end
		end
  end
			
  if( abs(T - ATIME) <  STEPP )
    integrate = 0;
    FT        = T - ATIME;
  end

  % DERIVATIVE TERMS CALCULATED
  %----------------------------
  if( c.ISYNFL ~= 0 )
    % near-synchronous resonance terms
    XNDOT = c.DEL1*sin(XLI-FASX2) +   c.DEL2*sin(2*(XLI-FASX4)) +   c.DEL3*sin(3*(XLI-FASX6));
    XNDDT = c.DEL1*cos(XLI-FASX2) + 2*c.DEL2*cos(2*(XLI-FASX4)) + 3*c.DEL3*cos(3*(XLI-FASX6));
  else
    % near half-day resonance terms
    XOMI = c.OMEGAQ + c.OMGDT*ATIME;
			
    % p. 65
    %------
    X2OMI = XOMI + XOMI;
    X2LI  = XLI + XLI;
		
    XNDOT = c.D2201*sin( X2OMI+XLI   - G22)...
		 	    + c.D2211*sin( XLI         - G22)...
		 	    + c.D3210*sin( XOMI +XLI   - G32)...
		 	    + c.D3222*sin(-XOMI +XLI   - G32)...
		 	    + c.D4410*sin( X2OMI+X2LI  - G44)...
		 	    + c.D4422*sin( X2LI        - G44)...
		 	    + c.D5220*sin( XOMI + XLI  - G52)...
		 	    + c.D5232*sin(-XOMI + XLI  - G52)...
		 	    + c.D5421*sin( XOMI + X2LI - G54)...
		 	    + c.D5433*sin(-XOMI + X2LI - G54);
					
		XNDDT	= c.D2201*cos( X2OMI+ XLI - G22)...
		 	    + c.D2211*cos( XLI        - G22)... 
		 	    + c.D3210*cos( XOMI + XLI - G32)...
		 	    + c.D3222*cos(-XOMI + XLI - G32)...
		 	    + c.D5220*cos( XOMI + XLI - G52)...
		 	    + c.D5232*cos(-XOMI + XLI - G52)...
		 	    + 2*(c.D4410*cos(X2OMI + X2LI - G44)...
		 	    + c.D4422*cos( X2LI        - G44)...
		 	    + c.D5421*cos( XOMI + X2LI - G54)...
		 	    + c.D5433*cos(-XOMI + X2LI - G54));
  end

  XLDOT = XNI + c.XFACT;
  XNDDT = XNDDT*XLDOT;
	
  if( integrate == 1 )
    XLI   = XLI + XLDOT*DELT + XNDOT*STEP2;
	  XNI   = XNI + XNDOT*DELT + XNDDT*STEP2;
    ATIME = ATIME + DELT;
  else
    XL   =  XLI + (XLDOT + 0.5*XNDOT*FT)*FT;
    XN   =  XNI + (XNDOT + 0.5*XNDDT*FT)*FT;
    TEMP = -XNODES + c.THGR + T*THDT;
    XLL  =  XL - OMGASM+TEMP;
    if( c.ISYNFL == 0 )
      % half-day resonance
	    XLL = XL + 2*TEMP;
    end
    return
  end
end % integrate


%-------------------------------------------------------------------------------
%  Updated Greenwich time function
%-------------------------------------------------------------------------------
function theta = GST( jD )

% Julian centuries
T = ( jD - 2451545 )/36525;
theta =  -6.2e-6*T^3 + 0.093104*T^2 + (876600.0*3600 + 8640184.812866)*T + 67310.54841;
             
gmst = GMSTime( jD );

theta = mod( theta*pi/180/240, 2*pi );
if theta < 0
  theta = theta + 2*pi;
end

%-------------------------------------------------------------------------------
%  Duplicate satrec from Vallado's 2005 code
%-------------------------------------------------------------------------------
function d = DefaultSatRec

% Initialize d
%-------------
d.satnum = 0;
d.epochyr = 0;
d.epochtynumrev = 0;
d.init = '';
d.method = '';
d.isimp = 0;
d.aycof = 0;
d.con41 = 0;
d.cc1 = 0;
d.cc4 = 0;
d.cc5 = 0;
d.d2 = 0;
d.d3 = 0;
d.d4 = 0;
d.delmo = 0;
d.eta = 0;
d.argpdot = 0;
d.omgcof = 0;
d.sinmao = 0;
d.t = 0;
d.t2cof = 0;
d.t3cof = 0;
d.t4cof = 0;
d.t5cof = 0;
d.x1mth2 = 0;
d.x7thm1 = 0; 
d.mdot = 0;
d.nodedot = 0;
d.xlcof = 0;
d.xmcof = 0;
d.nodecf = 0;
d.irez = 0;
d.d2201 = 0;
d.d2211 = 0;
d.d3210 = 0;
d.d3222 = 0;
d.d4410 = 0;
d.d4422 = 0;
d.d5220 = 0;
d.d5232 = 0;
d.d5421 = 0;
d.d5433 = 0;
d.dedt = 0;
d.del1 = 0;
d.del2 = 0;
d.del3 = 0;
d.didt = 0;
d.dmdt = 0;
d.dnodt = 0;
d.domdt = 0;
d.e3 = 0;
d.ee2 = 0;
d.peo = 0;
d.pgho = 0;
d.pho = 0;
d.pinco = 0;
d.plo = 0;
d.se2 = 0;
d.se3 = 0;
d.sgh2 = 0;
d.sgh3 = 0;
d.sgh4 = 0;
d.sh2 = 0;
d.sh3 = 0;
d.si2 = 0;
d.si3 = 0;
d.sl2 = 0;
d.sl3 = 0;
d.sl4 = 0;
d.gsto = 0;
d.xfact = 0;
d.xgh2 = 0;
d.xgh3 = 0;
d.xgh4 = 0;
d.xh2 = 0;
d.xh3 = 0;
d.xi2 = 0;
d.xi3 = 0;
d.xl2 = 0;
d.xl3 = 0;
d.xl4 = 0;
d.xlamo = 0;
d.zmol = 0;
d.zmos = 0;
d.atime = 0;
d.xli = 0;
d.xni = 0;
d.a = 0;
d.altp = 0;
d.alta = 0;
d.epochdays = 0;
d.jdsatepoch = 0;
d.nddot = 0;
d.ndot = 0; 
d.bstar = 0;
d.rcse = 0;
d.inclo = 0;
d.nodeo = 0;
d.ecco = 0;
d.argpo = 0;
d.mo = 0;
d.no = 0;
d.error = 0;


%--------------------------------------
% $Date: 2019-12-07 21:36:24 -0500 (Sat, 07 Dec 2019) $
% $Revision: 10090 $
