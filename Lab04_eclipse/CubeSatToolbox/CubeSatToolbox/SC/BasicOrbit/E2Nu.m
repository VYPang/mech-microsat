function nu = E2Nu( e, E )

%% Computes the true anomaly from the eccentric or hyperbolic anomaly.
%
%   Since version 1.
%--------------------------------------------------------------------------
%   Form:
%   nu = E2Nu( e, E )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   e             (1,:)   Eccentricity
%   E             (1,:)   Eccentric or Hyperbolic anomaly
%
%   -------
%   Outputs
%   -------
%   nu            (1,:)   True anomaly
%
%--------------------------------------------------------------------------
%   References:   Bate, R. R., Fundamentals of Astrodynamics. pp. 20-40.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993,1996,1998 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------

k = find( e == 1, 1 );
if( ~isempty(k) )
  error('PSS:E2Nu:error','Eccentric anomaly is not defined for parabolas')
end

if( nargin < 2 )
  if( length(e) == 1 )
    E = linspace(0,2*pi);
  else
    error('PSS:E2Nu:error','If e is not a scalar you must enter E')
  end
end

if( length(e) == 1 )
  e = DupVect(e,length(E))';
end

nuX = zeros(size(E));

k = find( e < 1 );
if( ~isempty(k) )
  nuX(k) = 2*atan(sqrt((1+e(k))./(1-e(k))).*tan(0.5*E(k)));
  xLbl = 'Eccentric';
else
  xLbl = [];
end

k = find( e > 1 );
if( ~isempty(k) )
  nuX(k) = 2*atan(sqrt((1+e(k))./(e(k)-1)).*tanh(0.5*E(k)));
  if( isempty(xLbl) )
    xLbl = 'Hyperbolic';
  else
    xLbl = [xLbl '/Hyperbolic'];
  end
end

if( nargout == 0 && length(E) > 1 )
  Plot2D(E,nuX,[xLbl, ' Anomaly'],'True Anomaly')
else
  nu = nuX;
end


%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 16:08:09 -0400 (Thu, 11 May 2017) $
% $Revision: 44568 $
