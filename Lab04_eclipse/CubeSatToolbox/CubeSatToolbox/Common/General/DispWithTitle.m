function DispWithTitle( x, t )

%% Display a variable with a title.
%
% x can be any MATLAB variable. If the title is left out, the variable name
% will be displayed via inputname. The variable is displayed using disp.
%
% Type DispWithTitle for a demo.
%--------------------------------------------------------------------------
%   Forms:
%	  DispWithTitle( x, t )
%	  DispWithTitle( x )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   x   :     Variable
%   t   (1,:) Title
%
%   -------
%   Outputs
%   -------
%   None
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%	 Copyright (c) 2013, 2016 Princeton Satellite Systems, Inc. 
%  All rights reserved.
%--------------------------------------------------------------------------
%  Since 2014.1.
%  2016.1: Add use of inputname for a title when input is only x.
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
    t = 'Random Matrix';
    x = rand(2,2);
    DispWithTitle( x, t );
    DispWithTitle( x );
    return
end

if nargin < 2
  t = inputname(1);
end
if isempty(t)
  t = 'Variable';
end
disp(t);
disp(x);


%--------------------------------------
% $Date: 2019-11-04 13:27:16 -0500 (Mon, 04 Nov 2019) $
% $Revision: 50213 $
