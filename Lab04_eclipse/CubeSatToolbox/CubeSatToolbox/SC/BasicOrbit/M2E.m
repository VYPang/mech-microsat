function eccAnom  = M2E( e, meanAnom, tol, nMax )

%% Computes the eccentric anomaly
% from the mean anomaly and the eccentricity.
%
%--------------------------------------------------------------------------
%   Form:
%   eccAnom  = M2E( e, meanAnom, tol, nMax )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   e            (1,:)    Eccentricity
%   meanAnom     (1,:)    Mean anomaly (rad)
%   tol          (1,1)    Tolerance
%   nMax         (1,1)    Maximum number of iterations
%
%   -------
%   Outputs
%   -------
%   eccAnom     (1,:)     Eccentric anomaly (rad)
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993-1998, 2012 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin == 0 )
    disp('Eccentric anomaly for e = 0.8');
    M2E( 0.8 );
    return;
end

if( nargin < 2 )
  if( length(e) == 1 )
    meanAnom = linspace(0,2*pi);
  else
    error('PSS:M2E:error','If e is not a scalar you must enter mean anomaly')
  end
end

eL = length(e);
mL = length(meanAnom);
if( mL ~= eL && eL == 1 )
  e = DupVect(e,mL)';
end

% Parabola
%----------
k = find(e == 1, 1);
if( ~isempty(k) )
  error('PSS:M2E:error','Eccentric anomaly is not defined for parabolas')
end

eccAnom = zeros(size(meanAnom));

% Ellipse
%--------
k = find(e < 1);
if( ~isempty(k) )
  if( nargin < 3 )
    eccAnom(k) = M2EEl(e(k),meanAnom(k));
  elseif( nargin == 3 )
    eccAnom(k) = M2EEl(e(k),meanAnom(k),tol);
  elseif( nargin == 4 )
    eccAnom(k) = M2EEl(e(k),meanAnom(k),tol,nMax);
  end
end

% Hyperbola
%----------
k = find(e > 1);
if( ~isempty(k) )
  if( nargin < 3 )
    eccAnom(k) = M2EHy(e(k),meanAnom(k));
  elseif( nargin == 3 )
    eccAnom(k) = M2EHy(e(k),meanAnom(k),tol);
  elseif( nargin == 4 )
    eccAnom(k) = M2EHy(e(k),meanAnom(k),tol,nMax);
  end
end

if( nargout == 0 && length(meanAnom) > 1 )
  Plot2D(meanAnom,eccAnom,'Mean Anomaly (rad)','Eccentric Anomaly (rad)','M to E');
  clear eccAnom;
end

%--------------------------------------
% $Date: 2020-05-07 15:39:29 -0400 (Thu, 07 May 2020) $
% $Revision: 52167 $
