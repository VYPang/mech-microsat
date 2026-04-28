function [ power ] = CubeSatPowerAnalysis( d, q, r, jD )

%% CubeSat power analysis from batch orbit data. 
% Simple batch calculation of power. Uses the same ephemeris model as
% RHSCubeSat.
%
% The built-in demo simulates a 1U satellite for one orbit.
%------------------------------------------------------------------------
%   Form:
%   [power] = CubeSatPowerAnalysis( d, q, r, jD )
%   CubeSatPowerAnalysis  % demo
%------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   d        (.)      Data structure from RHSCubeSat or SolarCellPower
%   q       (4,:)     Quaternion, ECI to body
%   v       (3,:)     Velocity vector
%   jD      (1,:)     Julian dates
%
%   -------
%   Outputs
%   -------
%   power   (1,:)     Power produced by the solar cells
%
%------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
  d       = SolarCellPower; % 1U
  el      = [7100 0.1 0 0 0 0];
  [r,v,t] = RVFromKepler( el );
  q       = QLVLH( r, v );
  jD      = Date2JD([2013 4 2 0 0 0]) + t/86400;
  CubeSatPowerAnalysis( d, q, r, jD )
  clear power
  return;
end

if isfield(d,'power')
  d = d.power;
end

% Constants
AU = 149597870;  % km
SOLAR_FLUX = 1367; % W/m2 at 1 AU

% Initialize vectors
n        = length(jD);
power(n) = 0;
nEcl(n)  = 0;

% Sun vector
[uSun, rSun] = SunV1( jD );
flux         = SOLAR_FLUX./(rSun/AU).^2;

% Step through orbit
for k = 1:n
  nEcl(k)  = Eclipse( r(:,k), uSun(:,k)*rSun(k));
  uSunBody = QForm( q(:,k), uSun(:,k) );
  pSun     = nEcl(k)*flux(k)*uSunBody;  
  power(k) = SolarCellPower( d, pSun );
end

if nargout == 0
  time   = (jD - jD(1))*86400;
  [s,sL] = TimeLabl( time );
  h = Plot2D( s, power, sL, 'Power (W)', 'Solar cell power' );
  AddFillToPlots(s,nEcl,h,[1 1 1; 0.9 0.9 0.9],0.5);
end

end

  
%--------------------------------------
% $Date: 2018-11-07 14:29:46 -0500 (Wed, 07 Nov 2018) $
% $Revision: 47409 $
