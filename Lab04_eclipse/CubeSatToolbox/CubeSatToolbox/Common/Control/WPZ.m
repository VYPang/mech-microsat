function w = WPZ( a, b, c, d, n, iu, iy )

%% Frequency vector with complex poles and zeros.  
%  	This routine produces a frequency vector that includes all of the
%   complex poles of the system and all complex zeros of each channel.
%   This vector is useful for frequency response calculations.
%
%--------------------------------------------------------------------------
%   Form:
%   w = WPZ( a, b, c, d, n, iu, iy )
%   w = WPZ( num, den, n )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   a                   Plant matrix or numerator polynomials
%   b                   Input matrix or denominator polynomials
%   c                   Measurement matrix
%   d                   Input feedthrough matrix
%   n                   Number of frequency points
%   iu                  Inputs  ( = 0, or leave out for all)
%   iy                  Outputs ( = 0, or leave out for all)
%
%   -------
%   Outputs
%   -------
%   w                   Frequency vector
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%   2017.1 Fixed indexing error in b when iu is not input.
%--------------------------------------------------------------------------

% Check arguments

if ( nargin < 2 )

  error('PSS:minrhs','Insufficient number of arguments')

elseif ( nargin < 4 )

  wp	= roots(b);
  ra  = size(a,1);
  
  for k=1:ra
    wz = [wp;roots(a(k,:))];
  end

  if ( nargin == 2 )
    n = 50;
  else
    n = c;
  end

else 

  if ( SizeABCD(a,b,c,d)==0 )
    return;
  end

  if ( nargin < 5 )
    n = 50;
  end

  if ( nargin < 6 )
    cb=size(b,2);
    iu=1:cb;
  end

  if ( nargin < 7 )
    rc=size(c,1);
    iy=1:rc;
  end
  
  % Add the poles
  %--------------
  wz = eig(a);
  
  % Find the zeros
  %---------------
  for k=1:length(iu)
    for l = 1:length(iy)
      z  = TrnsZero(a,b(:,iu(k)),c(iy(l),:),d(iy(l),iu(k)));    
      wz = [wz;z];
    end
  end
      
end

% Eliminate real roots
%---------------------
i = find( abs(imag(wz)) < eps*abs(real(wz)) );
if ( ~isempty(i) )
  wz(i) = [];
end

% Eliminate frequencies at zero
%------------------------------
i = find( abs(imag(wz)) < eps*norm(imag(wz)) );
if ( ~isempty(i) )
  wz(i) = [];
end

[zeta,~,wrz] = S2Damp(wz);

i      = find( zeta < 0.5 );
if( ~isempty(i) )
  wrz    = wrz(i); 
end

% Generate the frequencies if required by looking at the pole and 
% zero locations for each channel

[logWMin,logWMax] = LogLimit(wrz');     
w                 = WReson(logWMin,logWMax,n,wz);   


%--------------------------------------
% $Date: 2017-07-18 10:36:00 -0400 (Tue, 18 Jul 2017) $
% $Revision: 45084 $
