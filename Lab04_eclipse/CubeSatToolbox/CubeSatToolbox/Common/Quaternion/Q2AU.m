function [angle, u] = Q2AU( q )

%% Convert a quaternion to an angle and a unit vector. 
% If q = [1;0;0;0] then u is set to [1;0;0].
%
%--------------------------------------------------------------------------
%   Form:
%   [angle, u] = Q2AU( q )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   q       (4,1)   Quaternion
%
%   -------
%   Outputs
%   -------
%   angle   (1,1)   Angle
%   u       (3,1)   Unit vector
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1997 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 2.
%--------------------------------------------------------------------------

% Assume it is a valid quaternion
%--------------------------------
% angle = 2*acos( q(1) );

angle = 2*atan2( -Mag(q(2:4)), q(1) );
if( angle < -pi )
	angle = angle + 2*pi;
elseif( angle > pi )
	angle = angle - 2*pi;
end

if( norm(q(2:4)) < eps )
	u = [1;0;0];
else
	u = Unit( q(2:4) );
end


%--------------------------------------
% $Date: 2019-12-27 11:53:18 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50722 $
