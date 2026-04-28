function r = LatLonToR( lat, lon, f, a, type )

%% Converts geodetic latitude and longitude to r for an ellipsoidal planet.
% The default for f is the flattening factor for the earth. The default
% for type is geodetic.
%
% Type LatLonToR for a demo.
%
%--------------------------------------------------------------------------
%   Form:
%   r = LatLonToR( lat, lon, f, a, type )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   lat                   (:)    Geodetic latitude (rad)
%   lon                   (:)    Longitude (rad)
%   f                     (1,1)  Flattening factor
%   a                     (1,1)  Equatorial radius
%   type                  (1,:)  'geodetic' or 'geocentric'
%
%   -------
%   Outputs
%   -------
%   r                     (3,:)  Position vectors
%
%--------------------------------------------------------------------------
%   Reference: Escobal, P. R., "Methods of Orbit Determination," Kreiger,
%              1965, pp. 24-28.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1998 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 2.
%--------------------------------------------------------------------------

% Input processing
if( nargin < 1 )
  lat = [];
end

if( nargin < 2 )
  lon = [];
end

if( nargin < 3 )
  f   = [];
end

if( nargin < 4 )
  a   = [];
end

% Defaults
if( nargin < 5 )
  type = 'geodetic';
end

if( isempty(lat) )
  lat = linspace(0,pi/2);
end

if( isempty(lon) )
  lon = zeros(1,length(lat));
end
  
if( isempty(f) )
  f = Constant('earth flattening factor');
end

if( isempty(a) )
  a = Constant('earth radius equator');
end 

% Common calculations
eSq = f*(2 - f);
c   = cos( lat );
s   = sin( lat );

switch type
  case 'geodetic'
    den = sqrt(1 - eSq*s.^2);
    xC  = a*          c./den;
    zC  = a*(1 - eSq)*s./den;
	
  case 'geocentric'
    den = sqrt(1 - eSq*c.^2);
    q   = a*sqrt(1 - eSq);
    xC  = q*c./den;
    zC  = q*s./den;
	
  otherwise
    error('%s is not an option.',type);
	
end

r  = [xC.*cos( lon );xC.*sin( lon );zC];

if( nargout < 1 ) 
  s = ['R from G', type(2:length(type)), ' Latitude and Longitude'];
  Plot2D( r(1,:), r(2:3,:), 'x',['y';'z'],s);
  NewFig(['3D Plot of ',s])
  plot3( r(1,:), r(2,:), r(3,:));
  XLabelS('X')
  YLabelS('Y')
  ZLabelS('Z')
  title('Rotate with the Mouse')
  grid
  Axis3D('Equal')
  axis square
  rotate3d on
  clear r
end

%--------------------------------------
% $Date: 2020-01-08 13:37:12 -0500 (Wed, 08 Jan 2020) $
% $Revision: 50878 $
