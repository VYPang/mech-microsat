function f = SolarF( p, rho, normal, source, area )

%%   Compute the solar force on a set of elemental areas.
%
%   Since version 1.
%--------------------------------------------------------------------------
%   Form:
%   f = SolarF( p, rho, normal, source, area )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   p             (1,1) Solar pressure (flux/speed of light)
%   rho           (3,n) Coefficient fraction, may also be (3,1)
%                       [absorbed;specular;diffuse]
%   normal        (3,n) Surface normal vector
%   source        (3,1) Unit vector to source
%   area          (n)   Elemental area
%
%   -------
%   Outputs
%   -------
%   f             (3,n) Solar force
%
%-------------------------------------------------------------------------
%	  Reference:  Hughes, P. C., "Spacecraft Attitude Dynamics"
%             	John Wiley and Sons, 1986, pp. 260-263.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1994 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

% Initialize the force vector
%----------------------------
f = zeros( size( normal ) );

% Cosine of the incidence angle
%------------------------------
cosTheta = source'*normal;   

% Compute vectors for flux to the front 
%--------------------------------------
k        = find( cosTheta >= 0 ); 
lK       = length(k);
if size(rho,2) == 1
  kRho = ones(size(k));
else
  kRho = k;
end

if( lK > 0 )
  rhoAbsp = rho(1,kRho);
  rhoSpec = rho(2,kRho);  
  rhoDiff = rho(3,kRho); 
  rN      = 2*(rhoSpec.*cosTheta(k) + rhoDiff/3 );  
  rS      = rhoAbsp + rhoDiff;
  pV      = -p*cosTheta(k).*area(k);
  f(:,k)  = [pV;pV;pV].*(source*rS + [rN;rN;rN].*normal(:,k));  
end


%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 16:19:59 -0400 (Thu, 11 May 2017) $
% $Revision: 44571 $
