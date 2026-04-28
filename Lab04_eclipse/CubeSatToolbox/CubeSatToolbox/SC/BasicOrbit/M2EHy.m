function eccAnom = M2EHy( e, meanAnom, tol, nMax )

%% Eccentric anomaly for a hyperbola.
%   Computed from the mean anomaly and the eccentricity. 
%   This uses Kepler's method to iterate on the solution
%
%   For a demo plot use  M2EHy( e ).
%
%--------------------------------------------------------------------------
%   Form:
%   eccAnom = M2EHy( e, meanAnom, tol, nMax )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   e             (1,:)  Eccentricity
%   meanAnom      (1,:)  Mean anomaly
%   tol           (1,1)  Tolerance
%   nMax          (1,1)  Maximum number of iterations
%
%   -------
%   Outputs
%   -------
%   eccAnom       (1,:)   Eccentric anomaly
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1994, 2014 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%   2018.1 Changed initial guess so that for large meanAnom the algorithm
%   converges
%   2019.1 Added demo
%--------------------------------------------------------------------------

if( nargin < 1 )
  M2EHy( 1.2 );
  return
end

% If mean anomaly is not input, compute for a range of mean anomalies
if( nargin < 2 )
  meanAnom = linspace(0,2*pi);
end

if( nargin < 3 )
  tol = 1.e-8;
end

% Initial error checks
%---------------------
if( e <= 1 )
  error('PSS:M2EHy:error','The eccentricity must be greater than 1')
end

% First guess
%------------
eccAnom = asinh(meanAnom/e).*ones(1,length(meanAnom));

% Iterate
%--------
delta = tol + 1; 
n     = 0;


while( max(abs(delta)) >= tol )

  delta    = (meanAnom + eccAnom - e.*sinh(eccAnom)) ./ (e.*cosh(eccAnom) - 1);
  eccAnom  = eccAnom + delta;
  n        = n + 1;
  if( nargin == 4 )
    if( n == nMax )
      break
    end
  end
  
end
	
% If no outputs, plot
%--------------------
if( nargout == 0 )
  Plot2D( meanAnom, eccAnom, 'Mean Anomaly (rad)', 'Eccentric Anomaly (rad)', 'Eccentric Anomaly' );
  clear eccAnom
end

%--------------------------------------
% $Date: 2019-11-26 22:18:03 -0500 (Tue, 26 Nov 2019) $
% $Revision: 50410 $
