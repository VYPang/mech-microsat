function [h, w] = ZFresp( num, den, n )

%% Generates the frequency response for a digital filter.
%
%                       -1               -nb
%           b(1) + b(2)z   + Š + b(nb+1)z
%   H(z) = ---------------------------------
%                       -1               -na
%           a(1) + a(2)z   + Š + a(na+1)z
%
%   The routine interprets your input as follows:
%   If only 2 arguments are input it computes the frequency response
%   for 0 to ¼ at 512 points.
%
%   If 3 arguments are entered and the third is a scalar it will
%   interpret n as follows:
%
%     if ( n > 2.25 ),
%       do n point response between 0 and ¼
%       else if ( n < 2.25),
%         if n is an integer do an n point response between 0 and ¼
%       else
%         treat n as a scalar frequency
%       end
%     end
%
%     if 4 arguments are entered it will do an n point response between
%     0 and 2.25.
%
%--------------------------------------------------------------------------
%   Form:
%   [h, w] = ZFresp( num, den, n )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   num                 Numerator polynomial
%   den                 Denominator polynomial
%   n                   Number of points
%
%   -------
%   Outputs
%   -------
%   h                   Complex output vector
%   w                   Frequency points 
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993-1994 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 2.
%--------------------------------------------------------------------------

if( nargin == 2 )
  n      = 512;
  method = 'fft';
else
  if ( length(n) == 1 )
    if ( n > 2*pi || nargin == 4 )
      method = 'fft';
    elseif ( round(n) ~= n )
      method = 'fft';
    end
  else
    method = 'pol';
  end
end

if ( strcmp(method,'fft') )
  if ( nargin == 4 )
    hx = fft(num,n)./fft(den,n);
    w  = linspace(0,2*pi,n);
  else
    hx = fft(num,2*n)./fft(den,2*n);
    hx = hx(1:n);
    w  = linspace(0,pi,n);
  end
else
  z   = exp(sqrt(-1)*n);
  ln  = length(num); 
  ld  = length(den);
  % convert to poly in positive powers of z
  if( ln > ld )
    den = [den zeros(1,ln-ld)];
  else
    num = [num zeros(1,ld-ln)];
  end
  hx  = polyval(num,z)./polyval(den,z); 
  w   = n;
end

if ( nargout == 0 )
  clf;
  subplot(211)
  plot(w,abs(hx));
  grid;
  xlabel('Normalized Frequency')
  ylabel('Magnitude')
  subplot(212)
  plot(w,(180/pi)*angle(hx));
  grid;
  xlabel('Normalized Frequency')
  ylabel('Phase (deg)')
else
  h = hx;
end

%--------------------------------------
% $Date: 2017-05-02 12:34:43 -0400 (Tue, 02 May 2017) $
% $Revision: 44452 $
