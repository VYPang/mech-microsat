function [g, omega] = MoonRot( jD, type )

%% Computes the matrix that transforms from ECI to selenographic axes.
%   mean is the default type.
%
%   Type MoonRot for a demo.
%
%--------------------------------------------------------------------------
%   Form:
%   [g, omega] = MoonRot( jD, type )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   jD      (1,1) Julian Date
%   type    (1,4) 'mean' or 'true'
%
%   -------
%   Outputs
%   -------
%   g       (3,3) ECI To Selenographic
%   omega   (3,1) ECI Polar rotation vector
%
%--------------------------------------------------------------------------
%   References:   Escobal, P. R., Methods of Orbit Determination, Krieger, 
%                 pp. 413-416.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2004, 2015 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

% Demo
if( nargin < 1 )
  jD = 2447282.5;
  MoonRot( jD, 'mean' );
  return;
end

if( nargin < 2 )
  type = 'mean';
end

omegaMoon = 2*pi/(27.321582*86400);

t = (jD - 2415020)/36525.0;

gamma  = 281.2208333  + (     1.7191750   + (0.45277778e-3 + 0.33333333e-5*t)*t)*t;
gammaP = 334.3295556  + (  4069.0340333   - (0.10325e-1     + 0.125e-4*t    )*t)*t;
l      = 279.6966778  + ( 36000.768925    + 0.3025e-3*t)*t;
omega  = 259.1832750  - (  1934.1420083   - (0.20777778e-2 + 0.22222222e-5*t)*t)*t;
eps    =  23.45229444 - (     0.130125e-1 + (0.16388889e-5 - 0.50277778e-6*t)*t)*t;
lun    = 270.4341639  + (481267.8831417   - (0.11333e-3    - 0.1888889e-5 *t)*t)*t;

degToRad = pi/180;
secToRad = degToRad/3600;

i      = 1.535*degToRad;
g      = (l - gamma)*degToRad;
gP     = (lun - gammaP)*degToRad;
omegaP = (gammaP - omega)*degToRad;

sGP    = sin(gP);
gOm    = gP + 2*omegaP;
gPOP   = 2*gP + 2*omegaP;

rho    = -107*cos(gP) + 37*cos(gOm) - 11*cos(gPOP);
sigma  = (-109*sGP + 37*sin(gOm) - 11*sin(gPOP))/sin(i);
tau    = -12*sGP + 69*sin(g) + 18*sin(2*omega);

b      = eps*degToRad;
switch type
  case 'mean'
    a = i;
    c = omega*degToRad;
  case 'true'
    a = i + rho*secToRad;
    c = omega*degToRad + sigma*secToRad;
end

cA = cos(a);
sA = sin(a);
cB = cos(b);
sB = sin(b);
cC = cos(c);
sC = sin(c);

cTheta = cA*cB + sA*sB*cC;
sTheta = sqrt(1 - cTheta^2);
cPhi   = (cA*sB - sA*cB*cC)/sTheta;
sPhi   = -sA*sC/sTheta;
cDel   = (sA*cB - cA*sB*cC)/sTheta;
sDel   = -sB*sC/sTheta;

del  = atan2(sDel,cDel);

switch type
  case 'mean'
    psi = del + lun*degToRad - omega*degToRad;
  case 'true'
    psi = del + (lun*degToRad + tau*secToRad) - (omega*degToRad + sigma*secToRad);
end

cPsi = cos(psi);
sPsi = sin(psi);

g    = [ cPhi*cPsi - cTheta*sPhi*sPsi  sPhi*cPsi + cTheta*cPhi*sPsi sPsi*sTheta;...
        -sPsi*cPhi - cTheta*sPhi*cPsi -sPhi*sPsi + cTheta*cPhi*cPsi sTheta*cPsi;...
         sPhi*sTheta                  -cPhi*sTheta                  cTheta];
       
       
if( nargout > 1 || nargout == 0 )
  omega = omegaMoon*g(3,:)';
end
  
% Print if no outputs are requested
%----------------------------------
if( nargout == 0 )
	fprintf(1,'ECI to %s Selenographic\n',type);
	disp(g)
	fprintf(1,'ECI Rotation Vector [%12.4e;%12.4e%12.4e]\n',omega);

end


%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 14:11:01 -0400 (Thu, 11 May 2017) $
% $Revision: 44563 $


