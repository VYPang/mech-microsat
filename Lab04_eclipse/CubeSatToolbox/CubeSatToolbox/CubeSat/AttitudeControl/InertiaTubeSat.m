function inertia = InertiaTubeSat( l, mass )

%% Compute the inertia of a TubeSat. 
% This assumes a cylindrical shape  and the mass is uniformly distributed
% throught the volume. This is a good first cut.
%
% Type InertiaTubeSat for a demo. See also TubeSatFaces.
%------------------------------------------------------------------------
%   Form:
%   inertia = InertiaTubeSat( type, mass )
%------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   l      (1,1)     Either (1,2,3,4) for single, double, triple or quad
%   mass   (1,1)     Mass (kg)
%
%   -------
%   Outputs
%   -------
%   inertia (3,3)     Inertia matrix (kg-m^2)
%
%------------------------------------------------------------------------

%------------------------------------------------------------------------
%   Copyright (c) 2009 Princeton Satellite Systems, Inc.
%   All rights reserved.
%------------------------------------------------------------------------
% Since version 11.
%------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
    InertiaTubeSat(1,0.5);
    return
end

if isnumeric(l)
  if length(l)~=1
    error('Please provide a single factor.')
  end
else
  error('Input must be a scalar factor');
end

L = 0.127*l;   % Standard length
OD = 0.0894*l; % Outer diameter
R = OD/2;

% Calculation
%------------
inertia = Inertias( mass, [R L],'cylinder', 1 );

% Default output
%---------------
if( nargout < 1 )
    fprintf('TubeSatInertia\n---------------------\n')
    fprintf('Mass = %12.2f kg\n',mass);
    fprintf('Ixx  = %8.2e kg-m^2\n', inertia(1,1) )
    fprintf('Iyy  = %8.2e kg-m^2\n', inertia(2,2) )
    fprintf('Izz  = %8.2e kg-m^2\n', inertia(3,3) )
    fprintf('Ixy  = %8.2e kg-m^2\n', inertia(1,2) )
    fprintf('Ixz  = %8.2e kg-m^2\n', inertia(1,3) )
    fprintf('Iyz  = %8.2e kg-m^2\n', inertia(2,3) )
    clear d;
end
    


%--------------------------------------
% $Date: 2020-06-19 15:04:48 -0400 (Fri, 19 Jun 2020) $
% $Revision: 52850 $
