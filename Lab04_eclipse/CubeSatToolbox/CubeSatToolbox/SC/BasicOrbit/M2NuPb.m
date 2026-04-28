function nu = M2NuPb( meanAnom )

%% Generate the true anomaly from the mean anomaly for a parabola.
%
%   Since version 1.
%--------------------------------------------------------------------------
%   Form:
%   nu = M2NuPb( meanAnom )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   meanAnom       (1,:) Mean anomaly
%
%   -------
%   Outputs
%   -------
%   nu             (1,:) True anomaly for a parabola
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%	   Copyright 1993-1994 Princeton Satellite Systems, Inc.
%     All rights reserved.
%--------------------------------------------------------------------------

if( nargin < 1 )
  meanAnom = linspace(0,2*pi);
end

bo2       = 1.5*meanAnom;
oneThird  = 1/3;
d         = sqrt(1+bo2.^2);
x         = (bo2+d).^oneThird - (abs(bo2-d)).^oneThird;
nu        = 2*atan(x);

if( nargout == 0 & length(meanAnom) > 1 )
  Plot2D(meanAnom,nu,'Mean Anomaly','True Anomaly','True Anomaly for a Parabola');
  clear nu
end

% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 16:08:09 -0400 (Thu, 11 May 2017) $
% $Revision: 44568 $
