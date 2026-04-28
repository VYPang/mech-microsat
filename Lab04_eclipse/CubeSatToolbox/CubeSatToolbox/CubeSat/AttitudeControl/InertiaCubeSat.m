function [inertia, mass] = InertiaCubeSat( type, mass )

%% Compute the inertia of a CubeSat. 
% This assumes the mass is uniformly distributed throught the volume. This is a
% good first cut.
%
% Type InertiaCubeSat for a demo. See also CubeSatFaces.
%
% If mass is omitted is selects the maximum mass for your CubeSat size,
% which is 1 kg per U.
%------------------------------------------------------------------------
%   Form:
%   inertia = InertiaCubeSat( type, mass )
%------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   type    (1,2)    '1U' '2U' '3U' or [x y z] with U of each side
%   mass    (1,1)    Mass (kg)
%
%   -------
%   Outputs
%   -------
%   inertia (3,3)    Inertia matrix (kg-m^2)
%   mass    (1,1)    Mass (kg)
%
%------------------------------------------------------------------------

%------------------------------------------------------------------------
%   Copyright (c) 2009 Princeton Satellite Systems, Inc.
%   All rights reserved.
%------------------------------------------------------------------------
% Since version 8.
%------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
    InertiaCubeSat( '3U' );
    return
end

d = 0.1; % Standard length
if ischar(type)
  j      = strfind( lower(type), 'u' );
  z      = str2double( type(1:(j-1)) );
  x      = 1;
  y      = 1;
elseif isnumeric(type)
  if length(type)~=3
    error('Please provide the U along x, y, and z.')
  end
  x = type(1);
  y = type(2);
  z = type(3);
end

if( nargin < 2 )  
  % Default mass is 1 kg per U
  mass = x*y*z;
end

% Calculation
%------------
inertia = Inertias( mass, [x y z]*d,'box', 1 );

% Default output
%---------------
if( nargout < 1 )
    fprintf(1,'CubeSatInertia\n---------------------\n')
    fprintf(1,'Mass = %12.2f kg\n',mass);
    fprintf(1,'Ixx  = %8.2e kg-m^2\n', inertia(1,1) )
    fprintf(1,'Iyy  = %8.2e kg-m^2\n', inertia(2,2) )
    fprintf(1,'Izz  = %8.2e kg-m^2\n', inertia(3,3) )
    fprintf(1,'Ixy  = %8.2e kg-m^2\n', inertia(1,2) )
    fprintf(1,'Ixz  = %8.2e kg-m^2\n', inertia(1,3) )
    fprintf(1,'Iyz  = %8.2e kg-m^2\n', inertia(2,3) )
    clear inertia;
end
    

%--------------------------------------
% $Date: 2019-09-06 11:24:45 -0400 (Fri, 06 Sep 2019) $
% $Revision: 49727 $
