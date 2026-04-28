function h = LoadEarthMap( name )         

%% Creates a figure with Earth texturemap, political boundaries, and lat/lon.
%   Loads the file EarthMapData.mat
%
%   Since version 10.
%--------------------------------------------------------------------------
%   Form:
%   h = LoadEarthMap( name )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   name       (1,:) Figure title
%
%   -------
%   Outputs
%   -------
%   h           Handle to the figure
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2010 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

% This file contains political lines, latitude and longitude lines, and a
% 360x720 true color Earth image.
%------------------------
load('EarthMapData.mat'); 

if( nargin < 1 )
    name = 'Earth Map';
end

n1 = 61;
n2 = 91;
a1 = linspace(0,180,n1)*pi/180;
a2 = linspace(-180,180,n2)*pi/180;
th = repmat(a1',[1 n2]);
ph = repmat(a2,[n1 1]);
Reg = 6378.14+1;
Re = 6378.14;

h=figure('color','k','renderer','opengl','name',name,'tag','PlotPSS');
axes('parent',h,'visible','off','dataaspectratio',[1 1 1],...
	'cameraviewAngleMode','manual','cameraviewangle',5,...
    'view',[33,26]);
gcol = [.28 .55 .95];
line(political.XData*Reg,political.YData*Reg,political.ZData*Reg,'color',gcol)
hold on
line(latLines.XData*Reg, latLines.YData*Reg, latLines.ZData*Reg, 'color',gcol)
line(longLines.XData*Reg,longLines.YData*Reg,longLines.ZData*Reg,'color',gcol)
surf(Re*sin(th).*cos(ph), Re*sin(th).*sin(ph), Re*cos(th), double(cdata)/255,...
  'facecolor','texturemap','edgecolor','none');

cameratoolbar(h,'setmode','orbit');
Watermark( 'Spacecraft Control Toolbox', h );
set(h,'inverthardcopy','off');


%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-25 13:13:30 -0400 (Thu, 25 May 2017) $
% $Revision: 44688 $


