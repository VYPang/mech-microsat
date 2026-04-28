function m = Q2Mat( q )	
	
%% Converts a quaternion to a transformation matrix.
% Does not check to see that m is orthonormal.
% This routine requires 45 floating point operations.
%--------------------------------------------------------------------------
%   Form:
%   m = Q2Mat( q )	
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   q		(4,1)  Equivalent quaternion
%
%   -------
%   Outputs
%   -------
%   m		(3,3)  Orthonormal transformation matrix
%
%--------------------------------------------------------------------------
%   References: Shepperd, S. W., Quaternion from Rotation Matrix,
%               J. Guidance, Vol. 1, No. 3, May-June, 1978, pp. 223-224.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%		Copyright (c) 1994 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------

m = [q(1)^2+q(2)^2-q(3)^2-q(4)^2,2*(q(2)*q(3)-q(1)*q(4)),     2*(q(2)*q(4)+q(1)*q(3));...
     2*(q(2)*q(3)+q(1)*q(4)),    q(1)^2-q(2)^2+q(3)^2-q(4)^2, 2*(q(3)*q(4)-q(1)*q(2));...
     2*(q(2)*q(4)-q(1)*q(3)),    2*(q(3)*q(4)+q(1)*q(2)),     q(1)^2-q(2)^2-q(3)^2+q(4)^2];


%--------------------------------------
% $Date: 2019-12-07 20:48:04 -0500 (Sat, 07 Dec 2019) $
% $Revision: 50510 $
