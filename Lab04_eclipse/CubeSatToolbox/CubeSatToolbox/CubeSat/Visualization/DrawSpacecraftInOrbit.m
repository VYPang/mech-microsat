function out = DrawSpacecraftInOrbit( jD0, orbit, gSC, qEB, planet, cone, gps )

%% Draw the Earth, CubeSat model, orbit, sensor cone(s), and GPS
% constellation. The spacecraft can be left out (empty) to just view the
% cones.
%
%--------------------------------------------------------------------------
%   Form:
%   out = DrawSpacecraftInOrbit( jD0, orbit, gSC, qEB, planet, cone, gps )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   jD0           (1,1)    Julian date epoch.
%   orbit         (1,6)    Orbital elements [a,i,W,w,e,M]
%   gSC           (.)      Data structure array or mat-file that stores it.
%                          Each element of array is a component in the body.
%                          .name    String name of component
%                          .v       Vertices
%                          .f       Faces
%                          .scale   Scale 
%                          .color   Color of each component
%                          .alpha   Transparency (0-1) of each component
%   qEB           (4,1)    ECI to Body quaternion. Uses [1;0;0;0] if not
%                           entered.
%   planet         (:)     Name of planet file to use (e.g. 'Earth')
%   cone           (.)     Cone geometry. Includes:
%                          .fov     Field of view
%                          .pitch   Pitch angle from nadir
%                          .azimuth Azimuth angle from north
%   gps           (1,1)    Flag to include GPS constellation or not.
%
%   -------
%   Outputs
%   -------
%   out            (.)     Data structure with satellite Earth fixed
%                          position, cone
%
%   See also:  PlaybackOrbitSim.m
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright 2009 Princeton Satellite Systems, Inc. All rights reserved.
%--------------------------------------------------------------------------
% Since version 8.
% 2017.1 Remove additional light objects to fix a MATLAB error R2016b, 
% leaving a single light object
% 2017.2 Fix bug in frame of CAD model, transform into EF from ECI
%--------------------------------------------------------------------------

% default inputs
if( nargin<7 )
   gps = 0;
end
if( nargin<6 )
   cone = [];
end
if( nargin<5 || isempty(planet) )
   planet = 'Earth';
end

% built-in demo
if( nargin<1 )
   jD0   = Date2JD+6/24;
   orbit = [7500, 51*pi/180, 0, 0, 0, pi/4+pi*.2];
   qEB = QRand;
   
   planet = 'EarthMR';
   cone  = struct;
   cone.fov     = pi/8;
   cone.pitch   = pi/6;
   cone.azimuth = pi/2;
   DrawSpacecraftInOrbit( jD0, orbit, [], qEB, planet, cone ); 
   
   gSC.name = '2U CubeSat';
   [gSC.v,gSC.f] = CubeSatModel('2u',3);
   gSC.color = [1 0 1];
   gSC.alpha = .8;
   gSC.scale = 1000;
   gps = 0;
   DrawSpacecraftInOrbit( jD0, orbit, gSC, qEB, planet, cone, gps ); 
   return;
end

Re = 6378.14;

% load CAD model if mat-file name is supplied instead of structure
if( ~isstruct(gSC) && exist(gSC,'file') )
   gSC = load(gSC);
end

% colors
coneColor = [1 1 0];
swathColor = [0 1 0];

Map(planet,'3D');
hold on
set(gcf,'color','k','name','Orbit Display')
axis off

cameratoolbar
cameratoolbar('setmode','orbit')

% draw the orbit
sma = orbit(1);
T   = Period(sma);
r   = RVFromKepler(orbit,linspace(0,T,360));
m = ECIToEF( JD2T(jD0) );
for i=1:size(r,2)
  r(:,i) = m*r(:,i);
end
out.handles.orbit = plot3(r(1,:),r(2,:),r(3,:),'r-');

r1 = r(:,1);
out.rSat = r1;

camtarget(r1);

% draw the cone and swath
if( ~isempty(cone) )
   rCone  = r1;
   qPitch = AU2Q( cone.pitch, Unit(Cross(rCone,[0;0;1])) );
   qRoll  = AU2Q( cone.azimuth, Unit(rCone) );
   %cone.axis = QForm(QMult(qPitch,qRoll),Unit(-rCone));
   cone.axis = QForm(QMult(qPitch,qRoll),Unit(-rCone));
   
   lla = ECEFToLLA( rCone, Re );
   d = RapidSwath( lla(1), lla(2), lla(3), cone.fov/2, cone.pitch, cone.azimuth );
   out.swath = d;
   
   len = lla(3) + .5*Re;
   [v, f] = Cone( rCone, cone.axis, cone.fov/2, len, 60 );
   out.handles.cone = patch('vertices',v,'faces',f,'facecolor',coneColor,...
                            'edgecolor','none','facealpha',.5);
   out.handles.swath = plot3(d.r(1,:),d.r(2,:),d.r(3,:),'color',swathColor);
   
end


% draw the cad model
if( ~isempty(gSC) )
   
   % auto compute scale if not supplied
   if( ~isfield(gSC,'scale') )
      maxDim = 0;
      for i=1:length(gSC)
         thisMaxDim = max(Mag(gSC(i).v));
         if( thisMaxDim>maxDim )
            maxDim = thisMaxDim;
         end
      end   
      scale = .25*Re/maxDim;
      fprintf('No Scale Provided. Using Scale of %4.4f\n',scale);
   else
      scale = [gSC.scale];
      if( length(unique(scale))>1 )
         warning('Multiple different scales in CAD model array of components. Using first scale value.');
         scale = scale(1);
      end
   end
   
   for i=1:length(gSC)
      
      % scale, rotate, and position the vertices - Earth-Fixed
      nv = size(gSC(i).v,1);
      v = scale*(m*QTForm(qEB,gSC(i).v'))'+DupVect(r1,nv)';
      
      % draw the patch objects
      out.cad(i) = patch(...
         'vertices'     ,v, ...
         'faces',       gSC(i).f, ...
         'edgecolor',   'none', ...
         'facecolor',   gSC(i).color, ...
         'facealpha',   gSC(i).alpha);
   end
   
   % draw local coordinate axes
   vdir = r(:,2)-r1;
   x = Unit(r1);
   z = Unit(Cross(x,vdir));
   y = Unit(Cross(z,x));
   
   dist = Re/10;
   xAxis = [r1 r1+x*dist];
   yAxis = [r1 r1+y*dist];
   zAxis = [r1 r1+z*dist];
   
   out.handles.localFrame(1) = line('xdata',xAxis(1,:),'ydata',xAxis(2,:),'zdata',xAxis(3,:),'color','b','linestyle',':');
   out.handles.localFrame(2) = line('xdata',yAxis(1,:),'ydata',yAxis(2,:),'zdata',yAxis(3,:),'color','g','linestyle',':');
   out.handles.localFrame(3) = line('xdata',zAxis(1,:),'ydata',zAxis(2,:),'zdata',zAxis(3,:),'color','r','linestyle',':');
end


% include gps satellites
if( gps )
   
   s = webread('http://celestrak.com/NORAD/elements/gps-ops.txt');
   rGPS = PropagateTLECommonTime( jD0, 0, s );
   rGPS = cell2mat(rGPS);
   nGPS = size(rGPS,2);
   for i=1:nGPS
      rGPS(:,i) = m*rGPS(:,i);   % rotate to Earth-fixed frame
   end
   
   % lines of sight...
   
   % compute the half-angle field of view to 0 elevation 
   h = Mag(r1) - Re;
   out.horizonAngle = asin(Re/(Re+h));
   
   % compute the angle between nadir and each relative GPS position
   out.gpsAngle = zeros(1,nGPS);
   nadir = -Unit(r1);
   k = 0;
   for i=1:nGPS
      out.gpsAngle(i) = acos( Dot( nadir, Unit(rGPS(:,i)-r1) ) );
      
      % draw line of sight if not obstructed by Earth
      if( out.gpsAngle(i) > out.horizonAngle )
         k=k+1;
         out.handles.gpsLineOfSight(k) = line(...
            [r1(1) rGPS(1,i)],...
            [r1(2) rGPS(2,i)],...
            [r1(3) rGPS(3,i)],...
            'color','c');
         out.handles.gps(i) = plot3(rGPS(1,i),rGPS(2,i),rGPS(3,i),'g.');
      else
         out.handles.gps(i) = plot3(rGPS(1,i),rGPS(2,i),rGPS(3,i),'r.');
      end
         
   end
   
   out.rGPS = rGPS;
   
end

axis tight

% draw terminator line
[termLat,long,sunLatLon] = TerminatorLine( jD0 );
rEFTerm = zeros(3,length(termLat));
for i=1:length(termLat)
   rEFTerm(:,i) = LLAToECEF( [termLat(i)*pi/180;long(i)*pi/180;0.1], Re );
end
out.handles.terminator = plot3(rEFTerm(1,:),rEFTerm(2,:),rEFTerm(3,:),'y:');

out.sunLatLon = sunLatLon;

% sun
uSun = SunV1(jD0);
sunPos = m*uSun*Re;   % rotate to EF and scale size to Re
out.handles.sun = plot3(sunPos(1),sunPos(2),sunPos(3),'y.');

v = [1 1.2];
out.handles.sunLine = plot3(sunPos(1)*v,sunPos(2)*v,sunPos(3)*v,'y','linewidth',2);

out.sunEF = sunPos;

light('position',sunPos)
camzoom(10)

tag = CameraControls(gca);
CameraControls('set forward vector',tag,r(:,2)-r1);

out.tag = tag;

set(gcf,'UserData',out)


%--------------------------------------
% $Date: 2019-12-26 15:18:05 -0500 (Thu, 26 Dec 2019) $
% $Revision: 50705 $
