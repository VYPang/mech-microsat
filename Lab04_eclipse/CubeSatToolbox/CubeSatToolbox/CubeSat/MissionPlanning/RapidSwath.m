function d = RapidSwath( lat, lon, h, halfAngleFOV, pitch, azimuth, Rp )

%% Compute the intersection curve between a sensor cone and spherical planet.
%
% If no outputs are given this will generate a 3D plot of the sensor
% field of view. The nadir axis is drawn in green and the sensor
% boresight in yellow. This function has a built-in demo.
%
% Since version 8.
%--------------------------------------------------------------------------
%   Form:
%   d = RapidSwath( lat, lon, h, halfAngleFOV, pitch, azimuth, Rp );
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   lat           (1,1)    Latitude of satellite  (rad)
%   lon           (1,1)    Longitude of satellite (rad)
%   h             (1,1)    Altitude of satellite  (km)
%   halfAngleFOV  (1,1)    Sensor cone half-angle field of view (rad)
%                          Note: 0 <= halfAngleFOV <= PI/2
%   pitch         (1,1)    Pitch angle between boresight axis and nadir axis (rad)
%                          Note: 0 <= pitch <= PI
%   azimuth       (1,1)    Azimuth angle from north (rad)
%   Rp            (1,1)    Planet radius. Optional. Default is Earth radius. (km)
%
%   -------
%   Outputs
%   -------
%   d         (.)  Data structure with fields:
%              .r             Set of 3D position curves for each elevation
%              .lat           Set of latitude vectors for each elevation
%              .lon           Set of longitude vectors for each elevation
%              .intersect     Flag indicating whether the cone intersects 
%                                the planet.  
%              .aboveHorizon   Flag indicating whether any part of the cone 
%                                goes above the horizon.  
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2009 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

% Inputs
%  

verbose = 0;

% demo
if( nargin<1 )
   
   lat            = pi/4;
   lon            = pi/3;
   h              = 2000;
   pitch          = 15*pi/180;
   halfAngleFOV   = 31*pi/180;
	azimuth        = 2*pi/3;

  verbose = 1;
  
end

if( nargin<7 )
   Rp = 6378.14;
end

% check input angles
if( pitch<0 || pitch>pi )
   disp('Pitch angle must be between 0 and PI.')
   d = [];
   return;
elseif( halfAngleFOV<0 || halfAngleFOV>pi/2 )
   disp('Pitch angle must be between 0 and PI/2.')
   d = [];
   return;
end

% rename for clarity
theta = halfAngleFOV;
eta   = pitch;

% repeated terms
cTH  = cos(theta);
sTH  = sin(theta);
sTH2 = sTH^2; 
sE   = sin(eta);
cE   = cos(eta);
R2   = Rp^2;
Rh   = Rp+h;
Rh2  = Rh^2;

% Z is independent variable with limits

% number of points for curve
nP = 100;

horizon = 0;

a = eta+theta;
b = eta-theta;
c = asin(Rp/Rh);

if( b>c )
   % CASE 1: cone does not intersect sphere
   if( verbose ), disp('CASE 1, no intersection!'), end
   d.intersect = 0;
   d.horizon   = 0;
   return
elseif( a>c && b<-c )
   % CASE 2: cone surrounds sphere, no intersection of edges, just horizon
   if( verbose ), disp('CASE 2, cone surrounds sphere, no intersection of edges, just horizon'), end

   angle    = linspace(0,2*pi,nP);
   horizon  = 1;
   Zpp0     = R2 / Rh;
   rad      = sqrt( R2 - Zpp0^2 );
   
   Zpp = Zpp0;
   Xpp = rad*cos(angle);
   Ypp = rad*sin(angle);
   
elseif( a<=c || b>=-c )
   % CASE 3:   cone intersects sphere 
   
   if( eta==0 )
      % CASE 3.a: special case, eta = 0
      if( verbose ), disp('CASE 3.a, intersection, special case, eta = 0'), end
   
      % Xpp and Ypp trace out a circle centered at (0,0)
      
      angle = linspace(0,2*pi,nP);
      Zpp0  = Rh*sTH2 + sqrt(R2-Rh2*sTH2)*cTH;
      rad   = sqrt( R2 - Zpp0^2 );
      
      Zpp = Zpp0;
      Xpp = rad*cos(angle);
      Ypp = rad*sin(angle);
   
   else
      
      % Z min/max for when the cone boundary intersects the sphere
      
      % compute upper Z bound
      sinET = sin(eta-theta);
      cosET = cos(eta-theta);
      
      Z2 = Rh*sinET.^2 + sqrt( R2 - Rh2 * sinET.^2 ).*cosET;
      
      % compute lower Z bound
      sinET = sin(eta+theta);
      cosET = cos(eta+theta);
      if( sinET >= Rp/Rh || cosET <= 0 )
         horizon = 1;
         Z1 = R2 / Rh;
      else
         Z1 = Rh*sinET^2 + sqrt( R2 - Rh2 * sinET^2 )*cosET;
      end
      
      Zpp = linspace(Z1,Z2,nP/2);
      Xpp = (1/sE) * ( (Zpp -Rh)*cE + sqrt(Rh2+R2-2*Rh*Zpp)*cTH );
      Ypp = sqrt( abs( R2 - Xpp.^2 - Zpp.^2) );

      % append other half
      Zpp = [Zpp, fliplr(Zpp)];
      Xpp = [Xpp, fliplr(Xpp)];
      Ypp = [Ypp, -fliplr(Ypp)];
      
      % append horizon segment if one exists
      if( a>c || b<-c )
         % CASE 3.b, intersection, eta NOT zero, with horizon segment
         if( verbose ), disp('CASE 3.b, intersection, eta NOT zero, with horizon segment'), end
         horizon = 1;
         rad = sqrt(R2-Z1^2);
         b = atan(Ypp(1)/Xpp(1));
         angle = linspace(-b,b,nP/2);  % need to compute actual angle range
         Xpph = rad*cos(angle);
         Ypph = rad*sin(angle);
         Zpph = Z1*ones(size(angle));
         
         Zpp = [Zpp, Zpph];
         Xpp = [Xpp, Xpph];
         Ypp = [Ypp, Ypph];
      else
         % CASE 3.c, intersection, eta NOT zero, NO horizon segment
         if( verbose ), disp('CASE 3.c, intersection, eta NOT zero, NO horizon segment'), end
      end
      
   end
   
end

U = -Ypp*sin(azimuth) + Xpp*cos(azimuth);
V = Ypp*cos(azimuth) + Xpp*sin(azimuth);
W = Zpp;

Up = U*sin(lat) - W*cos(lat);
Vp = V;
Wp = U*cos(lat) + W*sin(lat);


% general method for r, lat, lon:
% m1 = [cos(azimuth), sin(azimuth), 0; -sin(azimuth), cos(azimuth), 0; 0 0 1];
% m2 = [-sin(lat), 0, cos(lat); 0 1 0; cos(lat), 0, sin(lat)];
% m3 = [cos(lon), -sin(lon), 0; sin(lon), cos(lon), 0; 0 0 1];
% d.r = m3*m2*m1*[Xpp;Ypp;Zpp];
% d.lat = asin(r(3,:)/Rp);
% d.lon = asin(r(2,:)./sqrt(r(1,:).^2+r(2,:).^2));

d.intersect    = 1;
d.aboveHorizon = horizon;
d.r            = [ -Up; Vp; Wp ];
d.lat          = asin( Wp/Rp );
d.lon          = atan2( Vp, -Up );

% rotate around by longitude if its not zero
if( lon~=0 )
   d.lon = d.lon + lon;
   d.r = Rp*[cos(d.lat).*cos(d.lon);...
      cos(d.lat).*sin(d.lon);...
      sin(d.lat)];
end

if( nargout==0 )
   
   % draw the sphere
   Map('EarthMR')
   hold on
   axis equal
   set(gcf,'color','k')
   set(gca,'color','k')
   source = [-1 1 0];
   light('position',source);
   light('position',source);
   light('position',source);
   light('position',source);
%   set(gca,'ambientLightColor',[.5 .5 .5])
   
   % draw the intersection of the cone on the sphere
   plot3(d.r(1,:),d.r(2,:),d.r(3,:),'b','linewidth',3)
   
   % compute the cone geometry
   rCone = Rh*[cos(lat)*cos(lon);cos(lat)*sin(lon);sin(lat)];
   qPitch = AU2Q( eta, Unit(Cross(rCone,[0;0;1])) );
   qRoll  = AU2Q( azimuth, Unit(rCone) );
   uCone  = QForm(QMult(qPitch,qRoll),Unit(-rCone));
   
   if( eta<pi/2 )
      Z3 = Rh*sE.^2 + sqrt( R2 - Rh2 * sE.^2 ).*cE;
      distToSurf = real( sqrt( R2 - Z3^2 + (Rp+h-Z3)^2 ) );
   else
      distToSurf = Rp;
   end
   coneAxis = [rCone, rCone+uCone*distToSurf];
   downAxis = [rCone, rCone-h*Unit(rCone)];
   
   % draw the cone
   c = [1 1 0 .5];
   [v,f] = Cone( rCone, uCone, theta, h*3, 60 );
   patch('vertices',v,'faces',f,'facecolor',c(1:3),'facealpha',c(4),'edgecolor','none');
   plot3(rCone(1),rCone(2),rCone(3),'r.','markersize',16)
   plot3(coneAxis(1,:),coneAxis(2,:),coneAxis(3,:),'y')
   plot3(coneAxis(1,2),coneAxis(2,2),coneAxis(3,2),'y.')
   plot3(downAxis(1,:),downAxis(2,:),downAxis(3,:),'g')
   plot3(downAxis(1,2),downAxis(2,2),downAxis(3,2),'g.')
   axis tight
   
   cameratoolbar('setmode','orbit')
   camtarget(coneAxis(:,2))
   camva(pi/2)
   campos(campos*3)
   cameratoolbar
   camzoom(5)
   
end

%--------------------------------------
% $Date: 2019-11-25 23:27:02 -0500 (Mon, 25 Nov 2019) $
% $Revision: 50395 $

