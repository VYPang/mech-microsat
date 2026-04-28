function AxesCart( xMin, yMin, zMin )

%% Draw axes on the current plot with X, Y, Z, text labels.
% The axes are all red.
%--------------------------------------------------------------------------
%   Form:
%   AxesCart( xMin, yMin, zMin )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   xMin    (1,1)     Where you want the x-axis to start
%   yMin    (1,1)     Where you want the y-axis to start
%   zMin    (1,1)     Where you want the z-axis to start
%
%   -------
%   Outputs
%   -------
%   None
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%	  Copyright (c) 1995 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

x = get(gca,'XLim');
y = get(gca,'YLim');
z = get(gca,'ZLim');

x = max(x);
y = max(y);
z = max(z);

if( nargin == 0 )
  xMin = 0;
  yMin = 0;
  zMin = 0;
end

hold on;
plot3([xMin x],[0 0],[0 0],'r');
hold on;
plot3([0 0],[yMin y],[0 0],'r');
hold on;
plot3([0 0],[0 0],[zMin z],'r');
text(1.2*x,0,0,'X');
text(0,1.2*y,0,'Y');
text(0,0,1.2*z,'Z');


%--------------------------------------
% $Date: 2019-12-27 15:51:53 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50729 $
