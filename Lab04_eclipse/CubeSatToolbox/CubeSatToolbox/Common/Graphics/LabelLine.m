function LabelLine( x, t, n, f )

%% Labels a line.
% x must have at least 2 rows. 
% The format string is any standard matlab format such as 't = %12.4f'
%
%--------------------------------------------------------------------------
%   Form:
%   LabelLine( x, t, n, f )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   x          (2,:)   [x;y]
%   t          (1,:)   Numbers for labels
%   n          (1,1)   Number of labels
%   f          (1,:)   Format string
%
%   -------
%   Outputs
%   -------
%   None
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2009 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 8.
%   2019.1 Added demo.
%--------------------------------------------------------------------------

if( nargin < 1 )
  x = [-1 0 1 2 3;0 0 0 0 0];
  t = [1 2];
  n = 2;
  Plot2D(linspace(-2,4),linspace(-1,1));
  LabelLine( x, t, n )
  return
end

if( nargin < 2 )
    error('PSS:LabelLine','Must have at least 2 arguments.')
end

if( nargin < 3 )
    n = [];
end

if( nargin < 4 )
    f = '%8.4f';
end

if( isempty(n) )
    n = 5;
end

m = length(t);

% Compute the arc length
%-----------------------
s  = Mag(x(:,2:end) - x(:,1:end-1));
tS = sum(s);
dS = tS/n;

% Put labels at equal arclengths
%-------------------------------
text(x(1,1),x(2,1),sprintf(f,t(1,1)) );

zL = 0;
z  = 0;
for k = 1:(m-1)
    z = z + s(k);
    if( z - zL > dS )
        zL = z;
        text( x(1,k), x(2,k), sprintf(f, t(1,k)) );
    end
end

text(x(1,end),x(2,end),sprintf(f,t(1,end)) );

%--------------------------------------
% $Date: 2019-11-05 22:08:40 -0500 (Tue, 05 Nov 2019) $
% $Revision: 50224 $

