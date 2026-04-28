function PlaybackOrbitSim( time, object, planet, style )

%% Play back an orbit simulation of multiple objects with sensor cones.
% Utilizes AnimationGUI.
%--------------------------------------------------------------------------
%   Form:
%   PlaybackOrbitSim( time, object, planet, style )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   time   	(1,N) Time vector. For display only. Use any units.
%   object	(:)   Data structure array of simulated objects in orbit
%                 See PackageOrbitDataForPlayback.m. Fields are:
%                 .rEF         (3,N) Earth fixed position (km)
%                 .vEF         (3,N) Earth fixed velocity (km/s)
%                 .lat         (1,N) Latitude (rad)
%                 .lon         (1,N) Longitude (rad)
%                 .h           (1,N) Altitude (km)
%                 .coneFOV     (1,N) Cone field of view (rad)
%                 .conePitch   (1,N) Cone pitch from nadir (rad)
%                 .coneAzimuth	(N,1) Cone azimuth from north (rad)
%                 .coneAxis    (3,N) Cone axis in Earth-fixed frame
%                 .swathX      (N,P) Swath curve, Earth-fixed x-coord.
%                 .swathY      (N,P) Swath curve, Earth-fixed y-coord.
%                 .swathZ      (N,P) Swath curve, Earth-fixed z-coord.
%                 .swathLat    (N,P) Swath curve, latitude
%                 .swathLon    (N,P) Swath curve, longitude
%   planet    (:)	Name of planet file to use (e.g. 'EarthHR')
%   style     (:)	'2D' or '3D'   
%               	 NOTE: '2D' is not yet supported. To be supported
%                   in a future release.
%
%   -------
%   Outputs
%   -------
%   None
%
%   See also:  PackageOrbitDataForPlayback.m
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2009 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%   Since version 8.
%--------------------------------------------------------------------------

% built-in demo with two objects
%-------------------------------
if( nargin<1 )
   
   jD0         = Date2JD;
   sma         = 6800;
   el          = [sma, pi/4, 0, 0, 0, 0];
   T           = Period(sma);
   n           = OrbRate(sma);
   time        = 0:20:T*2;
   [r1,v1]     = RVFromKepler(el,time);
   coneFOV     = pi/4;
   conePitch   = pi/4*cos(n*time).^2;
   coneAzimuth	= 0;
   inputFrame  = 'ECI';
   
   object(1)   = PackageOrbitDataForPlayback( jD0, time, r1, v1, coneFOV, conePitch, coneAzimuth, inputFrame );
   
   el          = [sma, pi/4 + .08, 0, .08, 0, .05];
   [r2,v2]     = RVFromKepler(el,time);
   
   object(2)   = PackageOrbitDataForPlayback( jD0, time, r2, v2, coneFOV*0, conePitch, coneAzimuth, inputFrame );
   
   planet = 'EarthMR';
   style  = '3D';
   
end

nT   = length(time);
nObj = length(object);

% if no names are provided, add indexed names
%--------------------------------------------
if( ~isfield(object,'name') )
   for i=1:nObj
      object(i).name = ['Obj',int2str(i)];
   end
end

% if no colors are provided, create a color spread
if( ~isfield(object,'color') )
   
   colors = ColorSpread(nObj);
   names = cell(1,nObj);
   for i=1:nObj
      object(i).color = colors(i,:);
      names{i} = object(i).name;
   end
   
   % add a legend for reference
   LegendFig(names,colors,'Playback Orbit Sim');
   
end
   
% prepare data for animation GUI
%-------------------------------
scData(length(object)) = struct('t',0,'c',[],'r',[],'axis',[],...
  'coneFOV',0,'curveX',[],'curveY',[],'curveZ',[]);
for i=1:length(object)
   scData(i).t = time;
   scData(i).c = DupVect(object(i).color,nT)';
   switch lower(style)
      case '3d'
         scData(i).r = object(i).rEF;
         scData(i).axis = object(i).coneAxis;
         scData(i).angle = object(i).coneFOV;
         scData(i).curveX = object(i).swathZ;
         scData(i).curveY = object(i).swathY;
         scData(i).curveZ = object(i).swathX;
      case '2d'
         scData(i).r = [object(i).lon; object(i).lat];
         scData(i).curveX = object(i).swathLon;
         scData(i).curveY = object(i).swathLat;
   end
end

options = struct('axisType',planet,'view',style,'docked',0);
AnimationGUI( 'initialize', scData, [], time, options );



%--------------------------------------
% $Date: 2020-07-13 15:08:40 -0400 (Mon, 13 Jul 2020) $
% $Revision: 53044 $
