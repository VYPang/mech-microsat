function p = Map( planet, mType, ~ )

%% Draws a 2 or 3 dimensional map of a planet. 
% Turns on mouse driven 3D rotation if mType == '3d'. String inputs are
% not case sensitive. planet is the name of a .mat file with the
% variables planetMap and planetColorMap. 
% 
% You generate the planet data structure like this example for a gray scale
% image of Pluto; the replication of the image map is needed because the png is
% gray scale.
%
%   p = imread('pluto.png');
%   p3(:,:,1) = p;
%   p3(:,:,2) = p;
%   p3(:,:,3) = p;
%   planet.planetMap = p3;
%   planet.radius = Constant('equatorial radius pluto');
%   planet.name = 'Pluto';
%
% The planetColorMap is not needed if the planetMap is true color, with
% channels for R, G, B (m x n x 3).
% 
% The radius field may be an array of semimajor axes, (1x3). See Ellipsd.
%--------------------------------------------------------------------------
%   Form:
%   p = Map( planet, mType, noNewFig )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   planet        (1,:)    Any planet mat-file name or the structure
%                            planet.planetMap
%                            planet.planetColorMap
%                            planet.radius
%   mType         (2,:)   '2d' or '3d', default is '3d'
%   noNewFig      (1,1)    If entered, don't create a new figure.
%
%   -------
%   Outputs
%   -------
%   p             (.)      Planet image data structure
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1997, 2016 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 2.
%   2017.1 Added the option for planetMap to be nxmx3.
%          Fixed a bug on returning p when the structure does not have a
%          planetColorMap
%--------------------------------------------------------------------------


% Check input lists
%------------------
if( nargin < 1 )
  planet = 'Earth';
end

if( nargin < 2 )
  mType = '3d';
else
  mType = lower(mType);
end

if( isstruct( planet ) ~= 1 )
  eval(['load ' planet])
end

if( nargout == 0 )
  if( strcmp(mType,'3d') )
    if( nargin < 3 ) 
       NewFig('Globe')
    end
    dPlanet.r = planet.radius;
    if( length( dPlanet.r ) == 1 )
      [x,y,z] = sphere(50);
      x       = x*planet.radius;
      y       = y*planet.radius;
      z       = z*planet.radius;
    else
      [x, y, z] = Ellipsd( dPlanet.r(1), dPlanet.r(2), dPlanet.r(3) );
    end
	  hSurf   = surface(x,y,z);
	  grid on;
    % truecolor or indexed?
    pmd=size(planet.planetMap,3);
    if( pmd==3 )
      % truecolor
      pmap = planet.planetMap;
      for i=1:3
        pmap(:,:,i)=flipud(pmap(:,:,i));
      end
      set(hSurf,'Cdata',pmap,'Facecolor','texturemap');
    else
      set(hSurf,'CData',double(flipud(planet.planetMap)),'FaceColor','texturemap')
      colormap( planet.planetColorMap );
    end
    set(hSurf,'edgecolor', 'none',...
          'EdgeLighting', 'gouraud','FaceLighting', 'gouraud',...
          'specularStrength',0.1,'diffuseStrength',0.9,...
          'SpecularExponent',0.5,'ambientStrength',0.2,...
          'BackFaceLighting','unlit');

    view(3);
    XLabelS('x (km)')
    YLabelS('y (km)')
    ZLabelS('z (km)')
    rotate3d on
    axis image
  else % 2d
    if( nargin < 3 ) 
       NewFig('Map')
    end
    [xdim,ydim]=size(planet.planetMap);
    plot(0,0), hold on
    axis([-180 180 -90 90])
    x=linspace(-180,180,xdim);
    y=linspace(90,-90,ydim);
    pmd=size(planet.planetMap,3);  % 2017.1
    if( pmd==3 )
      image(x,y,planet.planetMap);
    else
      image(x,y,planet.planetMap);
      colormap(planet.planetColorMap)
    end
    axis equal, axis tight
    XLabelS('East Longitude (deg)')
    YLabelS('Latitude (deg)')
  end
else
  p.planetMap      = planet.planetMap;
  if( isfield(planet,'planetColorMap') ) % 2017.1
    p.planetColorMap = planet.planetColorMap;
  end
  p.radius         = planet.radius;
end


%--------------------------------------
% $Date: 2020-07-03 12:39:22 -0400 (Fri, 03 Jul 2020) $
% $Revision: 52976 $
