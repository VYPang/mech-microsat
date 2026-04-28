function [p, pD] = PDAL( nMax, mMax, x, xD )

%% Generates Associated Legendre Functions of the first kind and derivatives
%   
% The first index is n and the second is m
% Input is limited to -1?x?1
%
%--------------------------------------------------------------------------
%   Form:
%   [p, pD] = PDAL( nMax, mMax, x, xD )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   nMax               Max value of first index
%   mMax               Max value of second index
%   x                  Argument
%   xD                 Derivative of the argument
%
%   -------
%   Outputs
%   -------
%   p                  associated Legendre functions
%   pD                 derivative of the associated Legendre functions
%
%--------------------------------------------------------------------------
%   References: Spiegel, M.,R., Mathematical Handbook, McGraw-Hill
%                pp 146-150 
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

	
% Error Testing
%---------------
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
p  = zeros(nMax+1,mMax+1);
pD = zeros(nMax+1,mMax+1);
	
% Compute P(0,0) and P(1,0) and their derivatives
%-------------------------------------------------
p(1,1)  = 1;
p(2,1)  = x;
pD(1,1) = 0;
pD(2,1) = xD;

% Compute the remaining terms in the m=0 series
%-----------------------------------------------
for n = 3:nMax+1
  p(n,1)  = ( (2*n-3)*x*p(n-1,1) - (n-2)*p(n-2,1) ) / (n-1);
  pD(n,1) = ( (2*n-3)*(xD*p(n-1,1) + x*pD(n-1,1)) - (n-2)*pD(n-2,1) ) / (n-1);
end
	
% sqrt(1 - x^2) - This form reduces the roundoff error
%-----------------------------------------------------  
one_minus_x2      = (1-x)*(1+x);
	
sqrt_one_minus_x2 = sqrt(one_minus_x2);

% The first value of m is odd
%----------------------------
mOdd = 1;

% Compute the remaining terms in the series P(n,m)
%-------------------------------------------------
for m = 2:mMax+1
	  
  % Compute the value for P(m,m). This procedure reduces 
  % the error for large values of m
  %-----------------------------------------------------
  if ( mOdd == 1 )

     p(m,m) = (2*m-3)*p(m-1,m-1)*sqrt_one_minus_x2;
     if ( m > 2 )
       pD(m,m) = (m-1)*(2*m-3)*pD(m-1,m-1)*sqrt_one_minus_x2/(m-2);
     else
       if( abs(x) < 1 )
           pD(m,m) = - x*xD / sqrt_one_minus_x2;
       else
         pD(m,m) = 0;
       end
     end
     mOdd   = 0;

  else
  
     p(m,m) = (2*m-3)*(2*m-5)*p(m-2,m-2)*one_minus_x2;
     if ( m > 3 )
       pD(m,m) = (m-1)*(m-2)*(2*m-3)*(2*m-5)*pD(m-2,m-2)*one_minus_x2/((m-2)*(m-3));
     else
       pD(m,m) = - 6*x*xD;
     end
     mOdd   = 1;
     
  end
	  
  % Compute all P over the range of n for this value of m
  %-------------------------------------------------------	  
  for n = m:nMax
    p(n+1,m)  = ((2*n-1)*x*p(n,m) - (n+m-2)*p(n-1,m))/(n+1-m);
    pD(n+1,m) = ((2*n-1)*(p(n,m)*xD+x*pD(n,m))-(n+m-2)*pD(n-1,m))/(n+1-m);
  end
	  
end


%--------------------------------------
% $Date: 2019-12-29 16:21:07 -0500 (Sun, 29 Dec 2019) $
% $Revision: 50759 $
