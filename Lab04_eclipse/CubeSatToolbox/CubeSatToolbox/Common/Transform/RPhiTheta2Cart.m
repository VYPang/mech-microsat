function cRPT2Cart = RPhiTheta2Cart(r)

%% Computes the transformation matrix from an r, phi, theta frame
%   to a standard cartesian frame. In an RPT frame, r is the radial
%   direction, phi is 'east', and theta is in the direction of
%   co-elevation. When theta is zero the r vector is in the xy-plane.
%--------------------------------------------------------------------------
%   Form: 
%   cRPT2Cart = RPhiTheta2Cart(r)
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   position    (3,1)  Position in cartesian coordinates. 
%
%   -------
%   Outputs
%   -------
%   cRPT2Cart   (3,3)  The transformation matrix
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1999 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------

iR        = Unit(r);
iPhi      = Unit(Cross(iR,[0;0;-1]));
iTheta    = Unit(Cross(iPhi,iR));

cRPT2Cart = [iR iPhi iTheta];

%--------------------------------------
% $Date: 2019-12-27 11:31:14 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50720 $
