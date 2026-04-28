function meanAnom = E2M( ecc, eccAnom )

%% Converts eccentric anomaly to mean anomaly.
%
%--------------------------------------------------------------------------
%   Form:
%   meanAnom = E2M( ecc, eccAnom )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   ecc       (1,:) Eccentricity
%   eccAnom   (1,:) Eccentric anomaly
%
%   -------
%   Outputs
%   -------
%   meanAnom  (1,:) Mean anomaly
%
%--------------------------------------------------------------------------
%   References:	Bate, R. R. Fundamentals of Astrodynamics. pp. 185-187.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993-1998 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

if( nargin < 2 )
  if( length(ecc) == 1 )
    eccAnom = linspace(-pi+eps,pi-eps);
  else
    error('PSS:E2M:error','If ecc is not a scalar you must enter eccAnom')
  end  
end

if( length(ecc) == 1 && length(eccAnom)>1 )
  ecc = DupVect(ecc,length(eccAnom))'; 
end  

meanAnomX = zeros(size(eccAnom));

k = find( ecc == 1, 1 );
if( ~isempty(k) )
  error('PSS:E2M:error','Eccentric anomaly is not defined for parabolas')
end

k = find( ecc < 1 );
if( ~isempty(k) )
  meanAnomX(k) = eccAnom(k) - ecc(k).*sin( eccAnom(k) );
end

k = find( ecc > 1 );
if( ~isempty(k) )
  meanAnomX(k) = ecc(k).*sinh( eccAnom(k) ) - eccAnom(k);
end

if( nargout == 0 && length(eccAnom) > 1 )
  Plot2D(eccAnom,meanAnomX,'Eccentric Anomaly','Mean Anomaly')
else
  meanAnom = meanAnomX;
end

%--------------------------------------
% $Date: 2018-12-11 11:01:42 -0500 (Tue, 11 Dec 2018) $
% $Revision: 47589 $
