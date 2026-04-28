function eccAnom = M2EEl( ecc, meanAnom, tol, nMax )

%% Eccentric anomaly for an ellipse.
%   Computed from the mean anomaly and the eccentricity. The user can optionally 
%   specify a tolerance and maximum number of iterations.
%
%   For a demo plot call M2EEl( ecc ).
%
%--------------------------------------------------------------------------
%   Form:
%   eccAnom = M2EEl( ecc, meanAnom, tol, nMax )   or
%   eccAnom = M2EEl( ecc, meanAnom, tol )         or
%   eccAnom = M2EEl( ecc, meanAnom)
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   ecc            (1,:) Eccentricity
%   meanAnom       (1,:) Mean anomaly
%   tol            (1,1) Tolerance(optional, default is 1e-8)
%   nMax           (1,1) Maximum number of iterations
%                        (optional, default is no maximum. Can
%                        only be input if tol is also specified.)
%   -------
%   Outputs
%   -------
%   eccAnom        (1,:) Eccentric anomaly
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1994 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

if( nargin < 2 )
  meanAnom = linspace(0,2*pi);
end

if( nargin < 3 )
  tol = 1.e-8;
end

% Ellipse
if any(ecc >= 1)
  error('PSS:M2EEl:error','The eccentricity must be < 1')
end

% First guess
eccAnomX  = M2EApp(ecc,meanAnom);
	
% Iterate
delta = tol + 1; 
n     = 0;
tau   = tol;

while ( max(abs(delta)) > tau )
  dE    	  = (meanAnom - eccAnomX + ecc.*sin(eccAnomX))./ ...
                   (1 - ecc.*cos(eccAnomX));
  eccAnomX    = eccAnomX + dE;
  n           = n + 1;
  delta       = norm(abs(dE),'inf');
  tau         = tol*max(norm(eccAnomX,'inf'),1.0);
  if ( nargin == 4 )
    if ( n == nMax )
      break
    end
  end
end

if( nargout == 0 && length(meanAnom) > 1 )
  Plot2D(meanAnom,eccAnomX,'Mean Anomaly (rad)','Eccentric Anomaly (rad)','Eccentric Anomaly');
else
  eccAnom = eccAnomX;
end


%--------------------------------------
% $Date: 2019-02-12 21:14:29 -0500 (Tue, 12 Feb 2019) $
% $Revision: 48009 $
