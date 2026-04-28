function p = PAL( nMax, mMax, x )

%% Generates the Associated Legendre Functions of the first kind
% The first index is n and the second is m
% Input is limited to -1 ¾ x ¾ 1
%                                   m
% The output matrix is P(n,m) ==   P   or P
%                                   n      nm
% P(0,0)
% P(1,0) P(1,1)
% P(2,0) P(2,1) P(2,2)
% P(3,0) P(3,1) P(3,2) P(3,3)
% P(4,0) P(4,1) P(4,2) P(4,3) P(4,4)
%                                    P(nMax,mMax)
%
%--------------------------------------------------------------------------
%   Form:
%   p = PAL ( nMax, mMax, x )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   nMax               Max value of first index
%   mMax               Max value of second index
%   x                  Argument
%
%   -------
%   Outputs
%   -------
%   p                  Associated Legendre functions
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

% Error Testing
%--------------
if ( abs(x) > 1 )
  error('abs(x) > 1')
end

if ( mMax < 0 )
  error('mMax < 0')
end

if ( nMax < mMax )
  error('nMax must be >= mMax')
end

% Clear out the whole matrix
%---------------------------
p = zeros(nMax+1,mMax+1);
	
% Compute P(0,0) and P(1,0)
%--------------------------
p(1,1) = 1;
if( nMax > 0 )
  p(2,1) = x;
end
	
% Compute the remaining terms in the m=0 series
%----------------------------------------------
for n = 3:nMax+1
  p(n,1) = ( (2*n-3)*x*p(n-1,1) - (n-2)*p(n-2,1) ) / (n-1);
end
	
% sqrt(1 - x^2) - This form reduces the roundoff error
%-----------------------------------------------------  
one_minus_x2      = (1-x)*(1+x);
	
sqrt_one_minus_x2 = sqrt(one_minus_x2);

% The first value of m is odd
%-----------------------------
modd = 1;

% Compute the remaining terms in the series P(n,m)
%------------------------------------------------
for m = 2:(mMax+1)
	  
  % Compute the value for P(m,m). This procedure reduces 
  % the error for large values of m
  %-----------------------------------------------------
  if ( modd == 1 )
    p(m,m) = (2*m-3)*p(m-1,m-1)*sqrt_one_minus_x2;
    modd   = 0;
  else
    p(m,m) = (2*m-3)*(2*m-5)*p(m-2,m-2)*one_minus_x2;
    modd   = 1;
  end
	  
% Compute all P over the range of n for this value of m
%------------------------------------------------------	  
  for n = m:nMax
    p(n+1,m) = ((2*n-1)*x*p(n,m) - (n+m-2)*p(n-1,m))/(n+1-m);
  end
	  
end

%--------------------------------------
% $Date: 2019-12-29 16:21:07 -0500 (Sun, 29 Dec 2019) $
% $Revision: 50759 $
