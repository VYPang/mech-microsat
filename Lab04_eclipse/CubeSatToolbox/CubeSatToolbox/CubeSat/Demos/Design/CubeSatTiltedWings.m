%% Design a 3U CubeSat with Tilted Wings
% Specify data in the solarPanel field for CubeSatModel to define tilted wings.
%
% See also RHSCubeSat, CubeSatModel, DrawCubeSat, DrawCubeSatSolarAreas, 
% VOrbit, StructToText, QZero, Unit

%--------------------------------------------------------------------------
%   Copyright (c) 2017 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

disp('3U CubeSat with Tilted Wings');

%% Specify the solar panel geometry and construct the model
d                       = CubeSatModel( 'struct' );
d.massComponents        = 3;
d.solarPanel.dim        = [100 100 10];	% [side attached to cubesat, side perpendicular, thickness]
d.solarPanel.nPanels    = 2; % Number of panels per wing
d.solarPanel.rPanel     = [50 -50 0 0;0 0 50 -50;-150 -150 -150 -150]; % Location of inner edge of panel
d.solarPanel.sPanel     = [1 -1 0 0;0 0 1 -1;-1 -1 -1 -1];
d.solarPanel.cellNormal = Unit([1 -1 0 0;0 0 1 -1;1 1 1 1]); % Cell normal
d.solarPanel.sigmaCell  = [1;0;0];    % [absorbed; specular; diffuse]
d.solarPanel.sigmaBack  = [0;0;1];    % [absorbed; specular; diffuse]
d.solarPanel.mass       = 0.1;

[v, f, data] = CubeSatModel( '3U', d );
StructToText( data );

%% Visualize the model
DrawCubeSat( v, f, data );
DrawCubeSatSolarAreas( data );

%% Check the RHS output with the model
% Point the solar panels (+z) at the sun for the default epoch
uSun = SunV1(data.jD0);
q0 = U2Q( uSun, [0;0;1] );
x = [7000;0;0;0;VOrbit(7000);0;q0;0;0;0;0];
t = 0;
[~,dist,power] = RHSCubeSat( x, t, data );

StructToText( dist );
fprintf('Max solar power: %g W\n',power);


%--------------------------------------
% $Date: 2017-06-12 15:40:32 -0400 (Mon, 12 Jun 2017) $
% $Revision: 44835 $