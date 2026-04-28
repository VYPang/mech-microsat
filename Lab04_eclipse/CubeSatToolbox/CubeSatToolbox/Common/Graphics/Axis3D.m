function Axis3D( s )

%% Adjust 3D axes properties.
% Axis3D is the same as Axis3D('equal')
%--------------------------------------------------------------------------
%   Form:
%   Axis3D( s )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   s                 String 'equal' is the only option available
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

if( nargin == 0 )
  s = 'equal';
end

s = lower(s);

if( strcmp(s,'equal')  )
  x = get(gca,'XLim');
  y = get(gca,'YLim');
  z = get(gca,'ZLim');
  l = [min([x,y,z]) max([x,y,z])];
  set(gca,'XLim',l)
  set(gca,'YLim',l)
  set(gca,'ZLim',l)
else
  e = [s ' not implemented'];
  error(e);
end


%--------------------------------------
% $Date: 2019-12-27 15:51:53 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50729 $
