function dEl = OrbElemDiff( el0, el, type )

%% Computes the differences between orbital element vectors.
% This wraps the phase appropriately for all the angular elements.
%--------------------------------------------------------------------------
%   Form:
%   dEl = OrbElemDiff( el0, el, type )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   el0            (1,6) reference orbital elements        
%   el             (1,6) secondary orbital elements       
%   type            (1)  type
%                          1 -- [a,th,i,q1,q2,W]
%                          2 -- [a,i,W,w,e,M]
%
%   -------
%   Outputs
%   -------
%   dEl           (:,6) orbital element differences
%   
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2002 Princeton Satellite Systems, Inc. All rights reserved.
%--------------------------------------------------------------------------
%   Since version 7.
%   2019.1 Added demo and default type (2)
%--------------------------------------------------------------------------

% Demo
if( nargin < 1 )
  OrbElemDiff( [7000 0 0 0 0 0], [7100 0 0 0 0 0] )
  return
end
  
if( nargin < 3 )
  type = 2;
end

switch type
   
case 1
   
   % [a,th,i,q1,q2,W]
   %-----------------
   dEl(:,1) = el(:,1) - el0(1);                 % semi-major axis [km]
   dEl(:,2) = WrapPhase( el(:,2) - el0(2) );  % argument of latitude [rad]
   dEl(:,3) = WrapPhase( el(:,3) - el0(3) );  % inclination [rad]
   dEl(:,4) = el(:,4) - el0(4);                 % q1 = e cos(w)
   dEl(:,5) = el(:,5) - el0(5);                 % q2 = e sin(w)
   dEl(:,6) = WrapPhase( el(:,6) - el0(6) );  % longitude of ascending node [rad]

case 2
   
   % [a,i,W,w,e,M]
   %----------------
   dEl(:,1) = el(:,1) - el0(1);                 % semi-major axis [km]
   dEl(:,2) = WrapPhase( el(:,2) - el0(2) );  % inclination [rad]
   dEl(:,3) = WrapPhase( el(:,3) - el0(3) );  % longitude of ascending node [rad]
   dEl(:,4) = WrapPhase( el(:,4) - el0(4) );  % argument of perigee [rad]
   dEl(:,5) = el(:,5) - el0(5);                 % eccentricity
   dEl(:,6) = WrapPhase( el(:,6) - el0(6) );  % mean anomaly [rad]

end


%--------------------------------------
% $Date: 2019-11-29 23:24:02 -0500 (Fri, 29 Nov 2019) $
% $Revision: 50459 $
