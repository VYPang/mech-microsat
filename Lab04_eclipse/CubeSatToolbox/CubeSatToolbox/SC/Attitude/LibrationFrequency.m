function omega = LibrationFrequency( inertia, n )

%% Compute the libration frequency from inertia and orbit rate.
%
% Type LibrationFrequency for a demo of a gravity gradient stable 
% spacecraft. 
%
%--------------------------------------------------------------------------
%   Form:
%   omega = LibrationFrequency( inertia, n )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   inertia   (3,3)  Inertia matrix
%   n         (1,1)  Orbit rate
%
%   -------
%   Outputs
%   -------
%   omega     (3,1)  Frequencies
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2002, 2020 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   2020.1 Added missing acceleration rate terms and introduced an a
%   analytical solution.
%--------------------------------------------------------------------------

if( nargin < 1 )
	n       = 2*pi/VOrbit(6978);
  inertia	= diag([60 100 10]);
  LibrationFrequency( inertia, n )
  return
end

N     = [0;-n;0];
D     = [0 0 -n;0 0 0;n 0 0];
G     = 3*n^2*diag([inertia(2,2)-inertia(3,3),inertia(1,1)-inertia(3,3) 0]);
sNI   = Skew(N)*inertia;
sIN   = Skew(inertia*N);
a21   = -inertia\(sNI*D + G - sIN*D);
a22   = -inertia\(inertia*D - sIN + sNI);
a     = [zeros(3,3) eye(3);a21 a22];
e     = eig(a);
s   	= sort(imag(e),'descend');
omega	= s(1:3);


%--------------------------------------
% $Date: 2020-06-05 11:34:19 -0400 (Fri, 05 Jun 2020) $
% $Revision: 52657 $
