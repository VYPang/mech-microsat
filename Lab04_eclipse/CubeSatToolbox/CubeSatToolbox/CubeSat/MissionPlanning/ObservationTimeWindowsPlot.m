function ObservationTimeWindowsPlot( track, obs )


%% Plot ground track and observation windows for a satellite and targets
%--------------------------------------------------------------------------
%   Usage:
%   ObservationTimeWindowsPlot( track, obs )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   track       (.)	Data structure with time, lat and lon vectors.
%   obs         (.)	Data structure array with fields:
%                 	.target:    (2,1)    Lat and lon coordinates of target
%                 	.boundary:  (2,:)    Lat/lon boundary around target
%                 	.nObs:      (1,1)    Number of observations of this target
%                   .window:    (nObs,2) Each row is start/stop time of window    
%                 	.time:      {1,nObs} Each entry is a (1,T) time vector
%                 	.path:      {1,nObs} Each entry is a (2,T) lat/lon vector
%
%   -------
%   Outputs
%   -------
%   none
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2009 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 8.
%   2016.0.1 Fix mat-file used to be EarthMR, the preferred file for CubeSat
%   2019.1 Added a demo
%--------------------------------------------------------------------------

if( nargin < 1 )
  a     = linspace(0,2,20);
  obs   = struct('target',[0.5,1],'boundary',[0 1.5;-1 1],'nObs',0);
  track = struct('lat',zeros(1,20),'lon',a);
  ObservationTimeWindowsPlot( track, obs )
  return
end


% 2D Earth plot
Map('EarthMR','2D');
hold on

lw = 2;

% ground track
LatLonPlot( track.lat,track.lon,180,'r','linewidth',lw);

for i=1:length(obs)
   
   % target location
   plot(obs(i).target(2),obs(i).target(1),'g.','markersize',20)
   
   % target boundary
   LatLonPlot(obs(i).boundary(1,:),obs(i).boundary(2,:),180,...
      'm','linewidth',lw);
   
   % paths through target boundary
   for j=1:obs(i).nObs
      plot(obs(i).path{j}(2,:), obs(i).path{j}(1,:), ...
         'y','linewidth',lw,'markersize',20)
   end
   
end

%--------------------------------------
% $Date: 2019-11-25 23:27:02 -0500 (Mon, 25 Nov 2019) $
% $Revision: 50395 $
