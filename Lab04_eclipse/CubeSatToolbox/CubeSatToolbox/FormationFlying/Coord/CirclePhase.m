function alpha0 = CirclePhase( beta0 )

%% Compute the desired phase on the circle from the desired phase on the ellipse.
%--------------------------------------------------------------------------
%   Form:
%   alpha0 = CirclePhase( beta0 );
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   beta0            (1)      desired phase angle at equator crossing   [rad]
%
%   -------
%   Outputs
%   -------
%   alpha0           (1)     phase angle on circle such that
%                               the y-component of the circle
%                               is equal to that of the ellipse        [rad]
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%	  Copyright 2002 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 7.
%--------------------------------------------------------------------------

% Initial computation of alpha0
%-------------------------------
beta0  = WrapPhase( beta0 );
sb     = sin(beta0);
sb2    = sb.*sb;
sgn    = ones(1,length(beta0));
j      = ( 3*pi/2 > beta0 ) & ( beta0 > pi/2 );
sgn(j) = -1;
alpha0 = sgn.*asin( sb.*power( 4 - 3*sb2,-.5) );

% put the angle into the correct quadrant
%----------------------------------------
q3  = find( beta0 >= -pi & beta0 < -pi/2 );
q2  = find( beta0 > pi/2 & beta0 <= pi   );

alpha0(q3)  = -alpha0(q3)-pi;
alpha0(q2)  =  alpha0(q2)+pi;



%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-09 15:16:37 -0400 (Tue, 09 May 2017) $
% $Revision: 44523 $
