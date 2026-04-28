function [meanAnom,eccAnom] = Nu2M( e, nu )

%% Converts true anomaly to mean anomaly.
%
%--------------------------------------------------------------------------
%   Form:
%   [meanAnom,eccAnom] = Nu2M( e, nu )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   e             (1,1)  Eccentricity
%   nu            (1,:)  True anomaly
%
%   -------
%   Outputs
%   -------
%   meanAnom       (1,:)  Mean anomaly
%   eccAnom        (1,:)  Eccentric anomaly
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993-1998 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

if( nargin < 2 )
  if( e ~= 1 )
    if( e < 1 )
      nu = linspace(0,2*pi);
	  else
	    nuMax = acos(-1/e);
	    nu = 0.75*linspace(-nuMax,nuMax);
	  end
  else
	  nu = 0.75*linspace(-pi,pi);
  end
end

if( e ~= 1 )
  eccAnom  = Nu2E( e, nu );
  meanAnom = E2M( e, eccAnom );
else
  eccAnom = 0;
  meanAnom = tan(0.5*nu) + tan(0.5*nu).^3/3;
end

if( nargout == 0 )
  Plot2D(nu,meanAnom,'True Anomaly','Mean Anomaly')
  clear meanAnom
end


%--------------------------------------
% $Date: 2016-07-09 18:51:35 -0400 (Sat, 09 Jul 2016) $
% $Revision: 42793 $
