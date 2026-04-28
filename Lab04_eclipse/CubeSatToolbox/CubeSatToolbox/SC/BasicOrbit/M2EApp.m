function eccAnom = M2EApp( e, meanAnom )

%% Approximate root to Kepler's Equation for elliptical and hyperbolic orbits.
%
%   Since version 1.
%--------------------------------------------------------------------------
%   Form:
%   eccAnom = M2EApp( e, meanAnom )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   e             (: or 1)  Eccentricity
%   meanAnom      (:)       Mean anomaly
%
%   -------
%   Outputs
%   -------
%   eccAnom       (:)       Eccentric anomaly
%
%--------------------------------------------------------------------------
%   References: Battin, R.H. (1987). An Introduction to the
%               Mathematics and Methods of Astrodynamics, AIAA Press, p. 194.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1994-1998 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

if( nargin < 2 )
  meanAnom = linspace(0,2*pi); 
end

eL = length(e);
mL = length(meanAnom);
if( mL ~= eL && eL == 1 )
  e = DupVect(e,mL)';
end

if any( e < 0 | e == 1 )
  error('PSS:M2EApp:error','The eccentricity must be > 0, and not == 1');

else 

  eccAnomX = zeros(size(meanAnom));
 
  k    = find( meanAnom ~= 0 );
  e    = e(k);
  m    = meanAnom(k);
  i    = find( m > pi ); 
  if( ~isempty(i) )
    m(i) = -m(i);
  end
  
  eA   = zeros(size(m));

  %[kL,kG] = Sep('x<1',e);
  % Replace call to Sep with find calls for speed:
  kL = find(e<1);
  kG = find(e>=1);
  
  if( ~isempty(kL) )     % elliptical case.
    sM      = sin(m(kL)); 
    eA(kL) = m(kL) + e(kL).*sM./(1 - sin(m(kL)+e(kL)) + sM);
  end
  
  if( ~isempty(kG) )     % hyperbolic case.
    sM     = sinh(m(kG)./(e(kG)-1));
    eA(kG) = m(kG).^2 ./ (e(kG).*(e(kG)-1).*sM - m(kG));
  end;
  
  if( ~isempty(i) )
    eA(i) = -eA(i);
  end
  
  eccAnomX(k) = eA;
  
end

if( nargout == 0 && length(meanAnom) > 1 )
  Plot2D(meanAnom,eccAnomX,'Mean Anomaly (rad)','Eccentric Anomaly (rad)','Approximate Mean Anomaly')
else
  eccAnom = eccAnomX;
end


%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 16:08:09 -0400 (Thu, 11 May 2017) $
% $Revision: 44568 $
