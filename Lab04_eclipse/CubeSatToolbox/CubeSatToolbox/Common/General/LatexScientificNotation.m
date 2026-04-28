function s = LatexScientificNotation( x, n, m )

%% Converts a number into a string using latex notation.
%
% Type LatexScientificNotation for a demo.
%
%   See also LatexExp.
%
%--------------------------------------------------------------------------
%   Form:
%   s = LatexScientificNotation( x, n, m )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   x        (1,1)  Number
%   n        (1,1)  Number of decimal digits
%   m        (1,1)  Number of significant digits
%
%   -------
%   Outputs
%   -------
%   s        (1,:)  Latex string
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2010, 2012 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 10.
%--------------------------------------------------------------------------

% Demo
%-----
if(nargin < 1)
	disp('Convert 1.314e-10 into latex')
	LatexScientificNotation( 1.314e-10, 2 )
	disp('Convert 1.314e10 into latex')
	LatexScientificNotation( 1.314e10, 2, 1 )
	disp('Convert 2.314e1 into latex')
	LatexScientificNotation( 2.322e1, 2, 2 )
	return;
end

if( nargin < 3 )
    m = 1;
end

if( m < 1 )
    m = 1;
end

f = 10^(m-1);
q = log10(x);
e = floor(q);
q = q - e;
q = f*10^q;
e = e - (m-1);

if( e ~= 0 )
    s = sprintf('%*.*f $\\times 10^{%d}$',n+2,n,q,e);
else
    s = sprintf('%*.*f',n+2,n,x);
end

%--------------------------------------
% $Date: 2019-12-27 14:31:09 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50728 $

