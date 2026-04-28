function d = DiameterAWG( n )

%% Diameter from AWG gauge.
%
%------------------------------------------------------------------------
%   Form:
%       DiameterAWG;
%   d = DiameterAWG( n )
%------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   n          (1,:) AWG gauge 0000 is -3
%
%   -------
%   Outputs
%   -------
%   d          (1,:) Diameter (mm)
%   
%
%------------------------------------------------------------------------
%   Reference:
%   http://en.wikipedia.org/wiki/American_wire_gauge#
%   Table_of_AWG_wire_sizes
%------------------------------------------------------------------------

%------------------------------------------------------------------------
%   Copyright (c) 2010 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%------------------------------------------------------------------------
%   Since version 9.
%------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
    n = linspace(-3,36);
    DiameterAWG(n);
    return;
end


d = 0.127*92.^((36-n)/39);

% Default output
%---------------
if( nargout == 0 )
    Plot2D(n,d,'n','d (mm)', 'Diameter AWG','ylog');
    clear d;
end

%--------------------------------------
% $Date: 2019-12-29 14:52:51 -0500 (Sun, 29 Dec 2019) $
% $Revision: 50754 $

