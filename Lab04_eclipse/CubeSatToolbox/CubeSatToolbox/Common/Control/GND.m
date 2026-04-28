function [g,nu,w] = GND(num,den,w)

%% Compute the frequency response given a numerator/denominator pair.
%
%   y(s) = num(s)*u(s)/den(s)
%
%   G(s) = num(s)/den(s)
%
%   This is a multi-output, single-input system
%
%   Each column will give the value for G(s) for that
%   frequency.
%
%--------------------------------------------------------------------------
%   Form:
%   [g,nu,w] = GND(num,den,w)
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   num                 Transfer function numerator(s)
%   den                 Transfer function denomenator(s)
%   w                   Frequency vector
%
%   -------
%   Outputs
%   -------
%   g                   Frequency response matrix
%   nu                  Number of inputs
%   w                   Frequency vector
%
%--------------------------------------------------------------------------
%   References:	Laub, A., "Efficient Multivariable Frequency Response
%               Computations," IEEE Transactions on Automatic Control,
%               Vol. AC-26, No. 2, April 1981, pp. 407-408.
%               Maciejowski, J. M., Multivariable Feedback Design, 
%               Addison-Wesley, Reading, MA, 1989, pp. 368-370.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

% Check arguments

if ( nargin < 2 )
  error('PSS:minrhs','Insufficient number of arguments')
end

[rn,cn] = size(num);
cd = size(den,2);

% If all of the numerators are proper convert to state-space form

if ( cn <= cd )

  [a,b,c,d] = ND2SS(num,den);
  if ( nargin > 2 )
    [g,nu,w] = GSS(a,b,c,d,1,1:rn,w);
  else
    [g,nu,w] = GSS(a,b,c,d,1,1:rn);
  end

else

  w = WPZ(num,den,50);

  s  = sqrt(-1)*w;
  n  = length(s); 
  sm = ones(1,n);

  for k=2:max(cd,cn),
    sm(k,:)=sm(k-1,:).*s;
  end

  g  = fliplr(num)*sm(1:cn,:)./(fliplr(den)*sm(1:cd,:));

  nu = 1;

end

%--------------------------------------
% $Date: 2017-05-01 20:36:54 -0400 (Mon, 01 May 2017) $
% $Revision: 44445 $
