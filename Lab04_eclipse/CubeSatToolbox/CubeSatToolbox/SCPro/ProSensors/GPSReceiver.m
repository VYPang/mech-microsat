function y = GPSReceiver( action, d )

%% GPS receiver model. Models the GPS constellation. 
%   The satellite locations are determined using GPSSatellite.
%   The model can output a set of default data.
%
%   Failure mode is zero output. The regular output is a structure:
%     .rGPS        (3,n)   Position of GPS satellites in view
%     .vGPS        (3,n)   Velocity of satellites
%     .range       (1,n)   Range to the satellites (km)
%     .rangeRate   (1,n)   Range rate (km/s)
%     .iD          (1,n)   ID of satellites in view
%     .nSatellites (1,1)   Number of satellites in view
%
%   See also GPSReceiverNav.
%--------------------------------------------------------------------------
%   Form:
%   y = GPSReceiver( action, d )
%--------------------------------------------------------------------------
%
%   -------
%   Inputs
%   -------
%   action      (1,:)     'initialize', 'update', 'output', 'set failure', or 
%                         'get default datastructure'
%   d           (1,1)     Depends on the action
%
%   -------
%   Outputs
%   -------
%   y           (1,1)     Depends on the action
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2001 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

if( nargin < 1 )
  action = 'initialize';
end

persistent a angle failure

switch action
  case 'initialize'
    if nargin < 2
      a = Default;
    else
      a = d;
    end
    failure   = 0;
    a.power   = 0;
    a.t       = 0;
  
  case 'get power consumption'
    y = a.power;
  
  case {'output', 'get output'}
    y    = a.gPSData;
    
  case 'set failure'
    failure = d;
  
  case 'update'
  
    dT  = (d.jD - a.t)*86400;
    if( dT < a.tSamp )
      return;
    end
    a.t                   = d.jD;
	  [rGPS, vGPS]          = GPSSatellite( d.jD, 'eci' );
	  h                     = IntersectPlanet( d.r, rGPS );
	  j                     = find( h > a.minimumAltitude );
	  n                     = length(j);
	  a.gPSData.rGPS        = rGPS(:,j);
	  a.gPSData.vGPS        = vGPS(:,j);
	  speedOfLight          = 3e5; % km/s
	  if( failure | n == 0 )
      a = Default; 
	  else
      [range, rangeRate]    = RangeMeasurement( d.r, d.v, d.clockError*speedOfLight,...
                                    rGPS(:,j), vGPS(:,j) );
  	  a.gPSData.range       = range' + a.range1Sigma*randn(n,1);
  	  a.gPSData.rangeRate   = rangeRate' + a.rangeRate1Sigma*randn(n,1);
  	  a.gPSData.id          = j';
  	  a.gPSData.nSatellites = n;
	  end
	  
  case 'get default datastructure'
    y = Default;

end

%---------------------------------------------------------------------------
%  Default Data
%---------------------------------------------------------------------------
function d = Default  

d.t                   = 0;
d.tSamp               = 1;     % 1 sec
d.minimumAltitude     = 100;   % km
d.power               = 5;     % W
d.range1Sigma         = 0.001; % km
d.rangeRate1Sigma     = 1e-6;  % km/s
d.gPSData.rGPS        = [0;0;0];
d.gPSData.vGPS        = [0;0;0];
d.gPSData.range       = 0;
d.gPSData.rangeRate   = 0;
d.gPSData.id          = 0;
d.gPSData.nSatellites = 0; 

%---------------------------------------------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-09 12:37:25 -0400 (Tue, 09 May 2017) $
% $Revision: 44511 $
