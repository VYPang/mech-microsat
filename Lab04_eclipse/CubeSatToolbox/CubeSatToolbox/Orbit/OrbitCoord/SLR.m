function p = SLR( e, a )

%% Computes the semi-latus rectum.
%
%--------------------------------------------------------------------------
%   Form:
%   p = SLR( e, a )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   e                     Eccentricity
%   a                     Semi major axis (or perigee radius for parabola)
%
%   -------
%   Outputs
%   -------
%   p                     Semi-latus rectum
%
%--------------------------------------------------------------------------
%   References:   Bates, R.B. Fundamentals of Astrodynamics, pp. 28,34.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993-1998 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

aV    = DupVect(a',length(e)); 
eV    = 1 - e.^2;
i     = find(e == 1);
eV(i) = 2*ones(size(i));

 
p     = aV.*DupVect(eV,length(a));

if( nargout == 0 && (length(e) > 1 || length(a) > 1) )
  Mesh2( e, a, p, 'Eccentricity' ,'Semi Major Axis', 'Semi-Latus Rectum' ) 
  clear p
end 


%--------------------------------------
% $Date: 2018-10-01 21:00:34 -0400 (Mon, 01 Oct 2018) $
% $Revision: 47223 $
