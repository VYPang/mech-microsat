function [g, nu, w] = GSS(a,b,c,d,iu,iy,w)

%% Compute the multivariable frequency response of the system.
%   .
%   x = ax + bu
%   y = cx + du
%
%   or
%
%   G(s) = c*inv(sI-a)*b + d
%
%   y(s) = G(s)*u(s)
%
%   For example, for 3 outputs and 2 inputs g is of the form
%
%                   w(1)               w(2)       ...
%   output 1 [ input 1 input 2 | input 1 input 2 |... ]
%   output 2 [ input 1 input 2 | input 1 input 2 |... ]
%   output 3 [ input 1 input 2 | input 1 input 2 |... ]
%
%--------------------------------------------------------------------------
%   Form:
%   [g,nu,w] = GSS(a,b,c,d,iu,iy,w)
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   a                   Plant matrix
%   b                   Input matrix
%   c                   Measurement matrix
%   d                   Input feedthrough matrix
%   iu                  Inputs  ( = 0, or leave out for all)
%   iy                  Outputs ( = 0, or leave out for all)
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
%   References:	  Laub, A., "Efficient Multivariable Frequency Response
%                 Computations," IEEE Transactions on Automatic Control,
%                 Vol. AC-26, No. 2, April 1981, pp. 407-408.
%                 Maciejowski, J. M., Multivariable Feedback Design, 
%                 Addison-Wesley, Reading, MA, 1989, pp. 368-370.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993-2000 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

% Check arguments

if ( nargin < 4 ),
  error('PSS:minrhs','Insufficient number of arguments')
end


if( isempty( a ) )
	switch nargin
    case 4
      [g,nu,w] = EmptyA( d );
    case 5
      [g,nu,w] = EmptyA( d, iu );
    case 6
      [g,nu,w] = EmptyA( d, iu, iy );
    case 7
      [g,nu,w] = EmptyA( d, iu, iy, w );
  end
	return;
end

if ( SizeABCD(a,b,c,d)==0 ),
   return;
end

if( nargin < 5 )
  iu = [];
end

if( nargin < 6 )
  iy = [];
end

if ( isempty(iu) )
  iu = 1:size(b,2);
end
nu = length(iu);

if ( isempty(iy) )
  iy = 1:size(c,1);
end

% Generate the frequencies if required by looking at the pole and 
% zero locations for each channel

if ( nargin < 7 ),
  w = WPZ(a,b,c,d,50,iu,iy);
end


% Find the Hessenberg form of a such that a = t*ah*t' and t'*t = eye(t)
[t,ah] = hess(a); 
bh     = t'*b(:,iu); 
ch     = c(iy,:)*t;  

% g will be a matrix of pxm matrices
% one matrix will be computed for each frequency point
% [ g(w(1)), g(w(2)), g(w(3)), g(w(4)), ..., g(w(n)) ]

rc      = size(ch,1); 
cb      = size(bh,2); 
n       = length(w); 

g       = zeros(rc,n*cb); 

s       = sqrt(-1)*w;  

dI      = ones(1,length(ah)); 
cbm1    = cb-1; 

for i = 1:n 
  k2         = cb*i;
  k1         = k2-cbm1;
  sIah       = diag(s(i)*dI)-ah; 
  if ( cond(sIah) > norm(sIah)/eps ),
    disp(['Warning: sI-a is ill-conditioned at ',num2str(w(i)),' rad/sec']);
  end
  g(:,k1:k2) = ch*(sIah\bh) + d(iy,iu);
end

%--------------------------------------------------------------------------
%    Handles the case when a is empty
%--------------------------------------------------------------------------
function  [g, nu, w] = EmptyA( d, iu, iy, w )

if( nargin < 2 )
  iu = [];
end

if( nargin < 3 )
  iy = [];
end

if ( isempty(iu) )
  iu = 1:size(b,2);
end

nu = length(iu);

if ( isempty(iy) )
  iy = 1:size(d,1);
end

if ( nargin < 4 )
  w = logspace(-2,1);
end

n       = length(w); 
cD      = size(d,2); 
g       = zeros(size(d,1),n*cD); 
cDM1    = cD-1; 

for i = 1:n
  k2         = cD*i;
  k1         = k2 - cDM1;
  g(:,k1:k2) = d(iy,iu);
end

%--------------------------------------
% $Date: 2017-05-01 20:36:54 -0400 (Mon, 01 May 2017) $
% $Revision: 44445 $
