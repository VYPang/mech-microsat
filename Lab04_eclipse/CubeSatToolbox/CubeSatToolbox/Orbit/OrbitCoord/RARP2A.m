function a = RARP2A( rA, rP )

%% Computes the semi major axis from apogee and perigee radii
%--------------------------------------------------------------------------
%   Form:
%   a = RARP2A( rA, rP )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   rA             (1,m)  Apogee radius
%   rP             (1,n)  Perigee radius
%
%   -------
%   Outputs
%   -------
%   a              (m,n)  Semi major Axis
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%	 Copyright 1993-1998 Princeton Satellite Systems, Inc. All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

if( length(rP) > 1 || length(rA) > 1 )
  aX  = 0.5*(DupVect(rA',length(rP)) + DupVect(rP,length(rA)));
else
  aX = 0.5*(rA + rP);
end

if( nargout == 0 && (length(rP) > 1 || length(rA) > 1) )
  Mesh2( rP, rA, aX, 'Perigee' ,'Apogee', 'Semi major Axis' ) 
else
  a = aX;
end 


%--------------------------------------
% $Date: 2017-05-09 11:41:04 -0400 (Tue, 09 May 2017) $
% $Revision: 44510 $
