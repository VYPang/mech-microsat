function visible = GroundStationVisibility( rGroundStation, jD, rSC, horizonAngle )

%% Determine ground station visibility for spacecraft position(s).
%   Has a built-in demo.
%--------------------------------------------------------------------------
%   Form:
%   visible = GroundStationVisibility( rGroundStation, jD, rSC, horizonAngle )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   rGroundStation   (3,m)   Earth fixed location of station(s)
%   jD               (1,n)   Julian date
%   rSC              (3,n)   Position(s) of spacecraft, ECI frame
%   horizonAngle     (1,1)   Minimum elevation to ground station (rad)
%
%   -------
%   Outputs
%   -------
%   visible          (n,m)   Matrix of visible flags
%
%--------------------------------------------------------------------------
%   See also SatelliteVisibility, ECIToEF, LatLonAltToEF
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2007 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

% Demo
%-----
if nargin == 0
  [rSC, ~, t]    = RVFromKepler( [9000 pi/4 0 0 0.2 0] );
  jD             = JD2000 + t/86400;
  latitude       = [0 30  -15]*pi/180;  
  longitude      = [0 120 240]*pi/180;
  altitude       = [0.025 0 -0.025];
  rGroundStation = LatLonAltToEF( [latitude;longitude;altitude] );
  horizonAngle   = 5*pi/180;
  if nargout == 0
    GroundStationVisibility( rGroundStation, jD, rSC, horizonAngle );
  else
    visible = GroundStationVisibility( rGroundStation, jD, rSC, horizonAngle );
  end
  return;
end

nGS     = size(rGroundStation,2);
nPts    = size(rSC,2);
visible = zeros(nGS,nPts);

for k = 1:nPts
  mEarth = ECIToEF( JD2T( jD(k) ) )';
  for j = 1:nGS
    % convert ground station positions to ECI
    rGS          = mEarth*rGroundStation(:,j);
    %vGS          = mEarth*Cross([0;0;wEarth],rGroundStation(:,j));
    dotSC        = Dot(-Unit(rGS),Unit(rSC(:,k)-rGS));
    if ( dotSC < cos(pi/2 + horizonAngle) )
      visible(j,k) = 1; 
    end
  end
end


% Plotting
%---------
if( nargout < 1 )
    NewFig('Satellite Visibility')
    [x,y,z] = sphere(24);
    p       = Map;
	hSurf   = surface(6378*x,6378*y,6378*z);
	grid;
    set(hSurf,'CData',double(flipud(p.planetMap)),'FaceColor','texturemap','edgecolor','none')
 	colormap( p.planetColorMap );
	view(3);
	XLabelS('x (km)')
	YLabelS('y (km)')
	ZLabelS('z (km)')
	rotate3d on
    hold on;
    i = 0;
    colors = 'bgrcmy';
    while length(colors)<nGS
      colors = [colors 'bgrcmy']; %#ok<AGROW>
    end
    rSC_EF = zeros(size(rSC));
    for k = 1:nPts
      % Convert rSC to EF
        mEarth = ECIToEF( JD2T( jD(k) ) );
        rSC_EF(:,k) = mEarth*rSC(:,k);
        plot3( rSC_EF(1,:), rSC_EF(2,:), rSC_EF(3,:), 'color', 'k', 'linewidth', 1 );
    end
    for j = 1:nGS
      for k = 1:nPts
        % Convert rSC to EF
        if( (visible(j,k) == 1) && (k ~= nPts) )
          i      = i + 1;
          r(:,i) = rSC_EF(:,k); %#ok<AGROW>
        elseif( (visible(j,k) == 0) || (k == nPts) )
          if( i > 0 ) 
            if( (k == nPts) && (visible(j,k) == 1) )
              i = i + 1;
              r(:,i) = rSC_EF(:,k); %#ok<AGROW>
            end
            plot3( r(1,:), r(2,:) ,r(3,:), 'color', colors(j), 'linewidth', 2 );
            i     = 0;
            clear r;
          end
        end
      end
    % Plot EF location of ground station
    rGS   = rGroundStation(:,j);
    plot3( rGS(1), rGS(2), rGS(3), [colors(j) '*'] );
    end
    Axis3D('Equal')
    axis square
    hold off
    clear visible;
end

%--------------------------------------
% $Date: 2019-09-05 15:59:43 -0400 (Thu, 05 Sep 2019) $
% $Revision: 49721 $
