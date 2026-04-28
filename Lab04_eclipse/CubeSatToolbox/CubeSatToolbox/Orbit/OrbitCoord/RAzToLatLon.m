function [lat,lon] = RAzToLatLon( r, az, lat0, lon0, R )

%% Transform (range,azimuth) to (latitude,longitude) coordinates.
%   Range is measured along the sphere. Azimuth is from north toward East.
%   The latitude and longitude returned are geocentric.
%
%--------------------------------------------------------------------------
%   Form:
%
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   r              (1,:)      Range along sphere
%   az             (1,:)      Azimuth angle
%   lat0           (1,1)      Initial latitude
%   lon0           (1,1)      Initial longitude
%   R              (1,1)      Radius of sphere (default is Earth)
%
%   -------
%   Outputs
%   -------
%   lat            (1,:)      Latitude on sphere
%   lon            (1,:)      Longitude on sphere
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2008 Princeton Satellite Systems, Inc.
%   All rights reserved
%--------------------------------------------------------------------------
%   Since version 8.
%--------------------------------------------------------------------------

% built-in demo
if( nargin < 1 )
   lat0 = pi/3;
   lon0 = pi/3;
   R = 6378.14;
   az = linspace(0,2*pi);
   RAzToLatLon(R,az,lat0,lon0);
   r = linspace(0,2*pi)*R;
   az = pi/4;
   RAzToLatLon(r,az,lat0,lon0);
   az = linspace(pi/4,-7*pi/4);
   RAzToLatLon(r,az,lat0,lon0);
   lat=[]; lon=[];
   return;
end    

% default inputs
if( nargin < 5 )
  R = 6378.14;
  if( nargin<4 )
    lon0 = 0;
    if( nargin<3 )
      lat0 = 0;
      if( nargin<2 )
        az = linspace(0,2*pi);
      end
    end
  end
end

% size check
if( length(az)==1 )
  az = az*ones(size(r));
end

d = r/R;
a = pi/2 - lat0;
cosb = cos(a)*cos(d) + sin(a)*sin(d).*cos(az);
b = acos( cosb );
lat = pi/2-b;

cosdlon = (cos(d)-cos(a)*cosb)./(sin(a)*sin(b));
cosdlon( cosdlon > 1 ) = 1;
cosdlon( cosdlon < -1 ) = -1;

% quadrant checking
dlon = acos( cosdlon );
dlon(d>pi) = 2*pi-dlon(d>pi);
lon = lon0+dlon;

k=find( az<0 & az>-pi ); 
lon(k)=lon0-dlon(k);

k=find( az>pi & az<2*pi ); 
lon(k)=lon0-dlon(k);

% put longitude in [-pi,pi]
lon(lon<-pi)=lon(lon<-pi)+2*pi;
lon(lon>pi)=lon(lon>pi)-2*pi;

% show circle on sphere 
if( nargout < 1 )
   [xs,ys,zs] = sphere(30);
   xs=xs*R; ys=ys*R; zs=zs*R;
   NewFig('RAzToLatLon');
   s=surf(xs,ys,zs);
   set(s,'facealpha',.5)
   set(s,'edgealpha',.5)
   hold on
   axis equal
   x = R*1.001*cos(lat).*cos(lon);
   y = R*1.001*cos(lat).*sin(lon);
   z = R*1.001*sin(lat);
   plot3(x,y,z,'c-o','linewidth',2)
   plot3(R*cos(lat0)*cos(lon0),R*cos(lat0)*sin(lon0),R*sin(lat0),...
     'ks','markersize',14,'linewidth',2)
   set(gca,'fontsize',14)
   xlabel('x'), ylabel('y'), zlabel('z')
   view(130,30)
   rotate3d on
   clear lat lon
end

   

%--------------------------------------
% $Date: 2017-04-20 16:19:57 -0400 (Thu, 20 Apr 2017) $
% $Revision: 44372 $
