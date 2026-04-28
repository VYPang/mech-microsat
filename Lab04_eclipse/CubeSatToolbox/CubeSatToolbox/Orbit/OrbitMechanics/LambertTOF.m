function [vT, a, p, tol] = LambertTOF( r1, r2, dT, orbitType, mu, tol, maxIter ) %#eml

%% Solves the Lambert time of flight problem using Battin's method.
%
%   Type LambertTOF for a demo
%
%--------------------------------------------------------------------------
%   Form:
%   [vT, a, p, tol] = LambertTOF( r1, r2, dT, orbitType, mu, tol, maxIter )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   r1            (3,1)   Initial position vector
%   r2            (3,1)   Final position vector
%   dT            (1,1)   Time between position 2 and 1 (s)
%   orbitType     (1,:)   'direct' (1) or 'retrograde' (-1)*
%   mu            (1,1)   Gravitational parameter*
%   tol           (1,1)   Desired tolerance [1e-10]*
%   maxIter       (1,1)   Maximum number of iterations [20]*
%                           * optional
%
%   -------
%   Outputs
%   -------
%   vT            (3,2)    Transfer velocity at beginning and end of 
%                          the transfer ellipse
%   a             (1,1)    Semi-major axis of the trajectory
%   p             (1,1)    The parameter for the orbit
%   tol           (1,1)    Achieved tolerance
%
%--------------------------------------------------------------------------
%   Reference:	Battin, R. H. "An Introduction to the Mathematics and Methods
%               of Astrodynamics", AIAA Education Series.
%               Vallado, D. A. Fundamentals of Astrodynamics and Applications.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1997-2003 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin == 0 )
  r1        = [15945.34;0;0];
  r2        = [12214.83899;10249.46731;0];
  mu        = 3.98600436e5;
  dT        = 76*60;
  tol       = [];
  orbitType = [];
  maxIter   = [];
  [vT, a, p, tol] = LambertTOF( r1, r2, dT, orbitType, mu, tol, maxIter );
  disp('Results')
  disp(vT);
  clear vT;
  return;
end

if( nargin < 7 || isempty(maxIter) )
  maxIter = 20;
end

if( nargin < 6 || isempty(tol) )
  tol = 1e-10;
end

if( nargin < 5 || isempty(mu) )
  mu = 3.98600436e5;
end 

if( nargin < 4 || isempty(orbitType) )
  orbitType = 'direct';
end

if ischar(orbitType)
	switch orbitType
      case 'direct'
        tM =  1;
      case 'retrograde'
        tM = -1;
	end
else
  tM = orbitType;
end

% Vector magnitude quantities
%----------------------------
magR1   = sqrt(sum(r1.^2));
magR2   = sqrt(sum(r2.^2));
rXR     = magR1*magR2;
rR      = magR2/magR1;
sqrtRR  = sqrt(rR);
del     = magR2/magR1 - 1; % r2 = r1(1+del)
muInv   = 1/mu;

% Angle between initial and final point
%--------------------------------------
cDNu    = r1'*r2/rXR;
sDNu    = tM*sqrt(abs(1 - cDNu^2));
dNu     = atan2( sDNu, cDNu );
%aA      = tM*sqrt(rXR*(1 + cDNu));

% Make between 0 and 2*pi
%------------------------
if( dNu < 0 )
	dNu = dNu + 2*pi;
end
% UNRESOLVED how to deal with 180 degree separation
% if abs(dNu-pi)<1e-6
%   % Special case of vectors nearly pi apart - this is poorly conditioned
%   disp('Lambert is poorly conditioned')
%   if (dNu-pi)==0
%     dNu = pi-tM*5e-6;
%   else
%     dNu = dNu + sign(dNu-pi)*5e-5;
%   end
%   cDNu = cos(dNu);
%   sDNu = sin(dNu);
% end

c4      = cos(0.25*dNu)^2;
s4      = sin(0.25*dNu)^2;
c2      = cos(0.5 *dNu);
s2      = sin(0.5 *dNu);

% c is the chord connecting vectors r1 and r2
c  = sqrt( magR1^2 + magR2^2 - 2*magR1*magR2*cDNu );
% s is the semi-perimeter of the triangle (r1,r2,c)
s = 0.5*(magR1 + magR2 + c );

% Battin Eq. 7.57 for tan^2(2w)
tan2WSq = 0.25*del^2/(sqrtRR + rR*(2 + sqrtRR));
% mean point radius of parabola connecting r1 and r2 (Battin Eq. 7.102)
rOP     = sqrt(rXR)*(c4 + tan2WSq);

% Battin Eq. 7.101
if( dNu < pi )
	l = (s4 + tan2WSq)/(s4 + tan2WSq + c2);
else
	l = (c4 + tan2WSq - c2)/(c4 + tan2WSq);
end
% Battin Eq. 7.89 part 3
m = mu*dT^2/(8*rOP^3);

% Pick a trial value of x
%------------------------
x        = l;
delta    = 1.5;
iter     = 1;

% Iterate on x and y until convergence
%-------------------------------------
while( (delta > tol) && (iter <= maxIter) )
	z        = Zeta( x );
	% Battin Eq. 7-111 and 7-112 p. 334
	den      = (1 + 2*x + l)*(4*x + z*(3+x));
	h1       = (1 + 3*x + z)*(l + x)^2/den;   % Note: Vallado has errors in his equations
	h2       = m*(x - l + z)/den;             
	y        = CubicRoot(h1,h2);
	xO       = x;
	% Battin Eq. 7.113
	x        = sqrt( (0.5*(1 - l))^2 + m/y^2 ) - 0.5*(1 + l);
	delta    = abs(xO/x - 1);
	iter     = iter+1;
end

if( iter>=maxIter )
  warning('LambertTOF:Iterations','LambertTOF: Max Iterations Reached')
end

% Compute the orbital elements from the numeric solution
%-------------------------------------------------------
% Battin Eq. 7.103
a = mu*dT^2/(16*rOP^2*x*y^2);
% Battin Eq. 7.105
p = 4*rOP^2*magR1*magR2*y^2*(1+x)^2*s2^2/(mu*dT^2);
% Battin Eq. 7.106 - not needed
% epsSq = del^2;
% ff    = 4*rR*s2^2;
% e     = sqrt( ( epsSq + ff*((l-x)/(l+x))^2 ) / ( epsSq + ff ) );

% Compute velocities on the orbit at points r1 and r2
%----------------------------------------------------
vT = zeros(3,2);
if 1
    % Radial and tangential velocity in the transfer orbit via Battin
    %----------------------------------------------------------------
    pRoot  = sqrt(p);
    muRoot = sqrt(mu);
    % psi is 1/2*(E2-E1), also called E (6.98)
    cPsi  = (1-x)/(1+x);
    sigma = pRoot*(c2 - cPsi/sqrtRR)/s2;
    % Battin Eq. 7.33 
    vTanA  = pRoot*muRoot/magR1;
    vRadA  = muRoot*sigma/magR1;

    % Velocity vector from Battin Eq. 7.33
    %-------------------------------------
    iH = Cross( r1, r2 );
    if( norm(iH) < tol ) 
    % Orbit normal vector is ambiguous if vectors are nearly aligned
    if( r1(3) == 0 )
      iH = [0;0;1];
    else
      [w,j] = min(r1);
      iH    = zeros(3,1);
      iH(j) = 1;
      iH    = Unit( Cross( r1, iH ) );
    end
    else
      iH = Unit( iH );
    end
    iTrans = tM*iH;

    i1    = Unit(r1);
    i2    = Unit(r2);

    % tangential is along tangent of transfer orbit
    vT(:,1) = vRadA*i1  + vTanA*Unit(Cross( iTrans, i1));

    h = Cross(r1,vT(:,1));
    e = muInv*Cross(vT(:,1),h) - i1;
    vT(:,2) = mu/(h(1)^2+h(2)^2 + h(3)^2)*Cross(h,e+i2);
else
    % Following is from Vallado using f and g functions
    sCA = 0.5*(s - c)/a;
    sA  = 0.5*s/a;
    if( abs(sA) > 1 )
        sA = sign(sA);
    end
    if( abs(sCA) > 1 )
        sCA = sign(sCA);
    end

    if( a > 0 )
        betaE = 2*asin(sqrt(sCA));
        if( dNu > pi )
            betaE = -betaE;
        end
        aMin = 0.5*s;
        tMin = sqrt(aMin^3*muInv)*(pi - betaE + sin(betaE));
        alphaE = 2*asin(sqrt(sA));
        if( dT > tMin )
            alphaE = 2*pi - alphaE;
        end
        dE   = alphaE - betaE;
        f    = 1 - a/magR1*(1-cos(dE));
        g    = dT - sqrt(a^3*muInv)*(dE - sin(dE));
        gDot = 1 - a/magR2*(1 - cos(dE));
    else
        alphaH = 2*asinh(sqrt(-sA ));
        betaH  = 2*asinh(sqrt(-sCA));
        dH     = alphaH - betaH;
        f      = 1 - a/magR1*(1-cosh(dH));
        g      = dT - sqrt(-a^3*muInv)*(sinh(dH) - dH);
        gDot   = 1 - a/magR2*(1 - cosh(dH));
    end

    vT(:,1) = (r2 - f*r1)/g;
    vT(:,2) = (gDot*r2 - r1)/g;
end

tol = delta;

%-------------------------------------------------------------------------------
%   Compute zeta (hypergeometric function) by continued fractions.
%   -1 <= x < inf, Eq. 7.115
%-------------------------------------------------------------------------------
%   Battin, R. H. "An Introduction to the Mathematics and Methods
%   of Astrodynamics", AIAA Education Series. pp 311, 337.
%-------------------------------------------------------------------------------
function z = Zeta( x )

f     = sqrt(1 + x) + 1;
eta   = x/f^2;
k     = 1;
delta = 1;
u     = 1;
sigma = 1;
% Compute up to 30 more terms of continued fraction
while( abs(u) > sigma*1e-8 && k < 30 )
	%gamma = (k+3)^2/((2*k+5)*(2*k+7));
	delta = 1/(1 + (k+3)^2/((2*k+5)*(2*k+7))*eta*delta);
	u     = u*(delta - 1);
	sigma = sigma + u;
	k     = k + 1;
end

z = 8*f/(3 + 1/(5 + eta + (9/7)*eta*sigma));

%--------------------------------------------------------------------------
%  Battin's method of finding largest real root for Eq. 7.114
%  y^3 - y^2 - h1*y^2 - h2 = 0
%--------------------------------------------------------------------------
function y = CubicRoot( h1, h2 )

% Battin Eq. 7.123
B    = 27*0.25*h2/(1+h1)^3;
sq1B = sqrt(1+B);
U    = -0.5*B/(sq1B + 1);

% Battin Eq. 7.125 (continued fraction to 5 terms)
K    = (1/3)/( 1-4/27*U/(1-8/27*U/(1-2/9*U/(1-22/81*U/(1-208/891*U)))) ); 

% Battin Eq. 7.124
y    = (1+h1)/3*(2 + sq1B/(1-2*U*K^2));


%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2020-04-21 09:32:32 -0400 (Tue, 21 Apr 2020) $
% $Revision: 51888 $
