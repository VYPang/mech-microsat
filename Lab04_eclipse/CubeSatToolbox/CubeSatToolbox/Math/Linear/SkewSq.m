function s = SkewSq( v, u )

%% Computes the product of two skew symmetric matrices derive from vectors.
%   If only one matrix is entered it will compute the square.
%
%   Since version 2.
%--------------------------------------------------------------------------
%   Form:
%   s = SkewSq( v, u )
%--------------------------------------------------------------------------
%
%   -----
%   Input
%   -----
%   v               (3,1) Vector
%   u               (3,1) Vector
%
%   ------
%   Output
%   ------
%   s               (3,3) Square of the skew matrix
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1997 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------

if( nargin < 2 )
  vSq = v.^2;

  s(3,3) = - vSq(1) - vSq(2);
  s(2,2) = - vSq(1) - vSq(3);
  s(1,1) = - vSq(2) - vSq(3);

  s(1,2) = v(1)*v(2);
  s(1,3) = v(1)*v(3);
  s(2,3) = v(2)*v(3);
  s(2,1) = s(1,2);
  s(3,1) = s(1,3);
  s(3,2) = s(2,3);
else
	vu = v.*u;

  s(3,3) = - vu(1) - vu(2);
  s(2,2) = - vu(1) - vu(3);
  s(1,1) = - vu(2) - vu(3);

  s(1,2) = v(2)*u(1);
  s(1,3) = v(3)*u(1);
	
  s(2,1) = v(1)*u(2);
  s(2,3) = v(3)*u(2);
	
  s(3,1) = v(1)*u(3);
  s(3,2) = v(2)*u(3);
end


%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 17:07:25 -0400 (Thu, 11 May 2017) $
% $Revision: 44577 $
