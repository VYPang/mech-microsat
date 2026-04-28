function [a, b, c, d, k] = PIDMIMO( inr, zeta, omega, tauInt, omegaR, tSamp, sType )

%% Produces a state space n degree of freedom PID controller.
%
%   The PID controller will be of the form:
%
%   x(k+1) = a x(k) + b u(k)
%   y(k)   = c x(k) + d u(k)
%
%   By designing in the frequency domain and converting to discrete
%   time using a zero-order hold. The inputs are the desired damping
%   ratio and undamped natural frequency of the complex mode of the
%   closed-loop system and the time constant of the integrator.
%
%   This system does not compensate for the phase lag of the zero order
%   hold and is only applicable to systems where the bandwidth is
%   much lower than the half-sampling frequency. The continuous time
%   equivalent for each axis is
%
%               Kr s         u
%   y = Kp u +  ---- u + Ki ---
%              s + wR        s
%
%   The function converts the result to discrete time if tSamp is entered.
%
%   If only one output is requested it will return a data structure with
%   the matrices.
%                   
%--------------------------------------------------------------------------
%   Form:
%   [a, b, c, d, k] = PIDMIMO( inr, zeta, omega, tauInt, omegaR, tSamp, sType )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   inr           (n,n)    Inertia matrix
%   zeta          (n,1)    Vector of damping ratios
%   omega         (n,1)    Vector of undamped natural frequencies
%   tauInt        (n,1)    Vector of integrator time constants
%   omegaR        (n,1)    Vector of derivative term roll-off frequencies
%   tSamp                  Sampling period
%   sType                  State equation type ('Delta' or 'Z' (default))
%
%   -------
%   Outputs
%   -------
%   a             (2n,2n)  Plant matrix
%   b             (2n, n)  Input matrix
%   c             ( n,2n)  Output matrix
%   d             ( n, n)  Feedthrough matrix
%   k                      Gains
%                          .kP Proportional
%                          .kR Rate
%                          .kI Integral
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1994-1995 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

n = length(inr);

if( length(zeta) == 1 && n > 1 )
  zeta = zeta*ones(n,1);
end

if( length(omega) == 1 && n > 1 )
  omega = omega*ones(n,1);
end

if( length(tauInt) == 1 && n > 1 )
  tauInt = tauInt*ones(n,1);
end

% Compute the gains assuming that omegaR is large, 5 to 10 times omega
%---------------------------------------------------------------------
if( nargin == 4 )
  omegaR = 5*omega;
end

if( length(omegaR) == 1 && n > 1 )
  omegaR = omegaR*ones(n,1);
end

% Compute the PID gains
%-----------------------
omegaI  = 2*pi*ones(size(tauInt))./tauInt;


c2  = omegaI.*omegaR;
c1  = omegaI+omegaR;
b1  = 2*zeta.*omega;
b2  = omega.^2;
g   = c1+b1;
kI  = c2.*b2./g;
kP  = (c1.*b2 + b1.*c2  - kI)./g;
kR  = (c1.*b1 + c2 + b2 - kP)./g;

k.kP = kP;
k.kR = kR;
k.kI = kI;

% Compute the state space model
%------------------------------
n                   =  length(zeta); 

aX                  =  zeros(2*n,2*n);  
aX(n+1:2*n,n+1:2*n) = -diag(g); 
b(1:n,1:n)          =  eye(n);
b(n+1:2*n,1:n)      =  diag(g);
c(:,1:n)            =  diag(kI);
c(:,n+1:2*n)        = -diag(kR.*g);
d                   =  diag(kP+kR.*g);

c                   = inr*c;
d                   = inr*d;

if( nargout > 0 )
  if( nargin > 5 )
    if( nargin < 7 )
      sType = 'z';
    end
    if( strcmpi(deblank(sType),'z') )
      [a,b] =   C2DZOH(aX,b,tSamp);
    else
      [a,b] = C2DelZOH(aX,b,tSamp);  
    end
  else
    a = aX;
  end
  
  if( nargout == 1 )
      a.a = a;
      a.b = b;
      a.c = c;
      a.d = d;
      a.k = k;
  end
elseif( nargout == 0 )
  wMin = floor(log10(min(omega )));
  wMax =  ceil(log10(min(omegaR)));
  FResp(aX,b,c,d,1:n,1:n,logspace(wMin-2,wMax+1,200));
  set(gcf,'Name','PID Controller')
end 

%--------------------------------------
% $Date: 2017-06-13 17:14:09 -0400 (Tue, 13 Jun 2017) $
% $Revision: 44843 $
