function power = SolarCellPower( d, pSun )

%% Compute the power for a solar power system.
% Has a built-in demo. Can also return the default data structure.
%
% Type SolarCellPower for a demo.
%
%------------------------------------------------------------------------
%   Form:
%   power = SolarCellPower( d, pSun )
%   d = SolarCellPower
%------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   d       (.)      Data structure
%                    .solarCellEff       (1,1) Efficiency of the cells
%                    .effPowerConversion (1,1) Efficiency of the power
%                                              conversion
%                    .solarCellArea      (1,:) Total cell area (m^2)
%                    .solarCellNormal    (3,:) Unit normal vector to the
%                                              cell face
%   pSun   (3,1)     Solar power flux vector (W)
%
%   -------
%   Outputs
%   -------
%   power  (1,1)     Power (W)
%
%------------------------------------------------------------------------

%------------------------------------------------------------------------
%   Copyright (c) 2009 Princeton Satellite Systems, Inc.
%   All rights reserved.
%------------------------------------------------------------------------
%   Since version 8.
%------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
    d = DefaultStruct;
    if nargout == 1
      power = d;
      return;
    end
    angle = linspace(0,2*pi);
    p     = zeros(1,100);
    for k = 1:length(angle)
      pSun = 1367*[cos(angle(k));sin(angle(k));0];
      p(k) = SolarCellPower( d, pSun );
    end
    Plot2D( angle, p, 'Angle (rad)', 'Power (W)', 'Solar cell power' );
    return
end

f    = d.solarCellNormal'*pSun;

k    = f < 0;
f(k) = 0;

if( length(d.solarCellEff) == 1 )
    solarCellEff = d.solarCellEff*ones(1,length(f));
else
    solarCellEff = d.solarCellEff;
end

power = 0;
for k = 1:length(f)
	power = power + solarCellEff(k)*d.effPowerConversion*d.solarCellArea(k)*f(k);
end
    
% Default data - for a 1U CubeSat
function d = DefaultStruct

d.solarCellEff       = 0.29; % EMCORE ZTJM
d.effPowerConversion = 0.8;
d.solarCellArea      = 0.088*0.088*[1 1];
d.solarCellNormal    = [1 -1;0 0;0 0];


%--------------------------------------
% $Date: 2020-06-26 12:04:29 -0400 (Fri, 26 Jun 2020) $
% $Revision: 52899 $
