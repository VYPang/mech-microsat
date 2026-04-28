function bDot = MagneticHysteresis( b, ~, h, hDot, d )

%% Right hand side for a dynamical model of magnetic hysteresis.
%
%   Unlike Flatley we use a tanh function. Tellinen gives the slope
%   fractions for the increasing and decreasing curves.
%
%--------------------------------------------------------------------------
%   Form:
%   bDot = MagneticHysteresis( b, t, h, hDot, d )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   b                  (1,1) Magnetic flux density (T)
%   t                  (1,1) Time - unused
%   h                  (1,1) Magnetic field (A/m)
%   hDot               (1,1) Magnetic field time derivative (A/m/s)
%   d                  (1,1) Data structure
%                            .bS (1,1) Saturation flux density (T)
%                            .hC (1,1) Coercive force (A/m)
%                            .bR (1,1) Remnance (T)
%
%   -------
%   Outputs
%   -------
%   bDot               (1,1) Derivative of the flux density.
%   
%--------------------------------------------------------------------------
%   Reference: Flatley, T. W. and Henretty, D. A., "A Magnetic Hysteresis
%              Model," N95-27081.
%              Kumar R., Mazanek, D. and Heck, M., "Simulation and Shuttle
%              Hitchhiker Validation of Passive Satellite
%              Aerostabilization," Journal of Spacecraft and 
%              Rockets, Vol. 32, No. 5, September-October 1995.
%              J. Tellinen, "A Simple Scalar Model for Magnetic
%              Hysteresis", IEEE Transactions on Magnetics, vol. 24, no. 4,
%              pp.2200-2206, July 1998.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2011, 2014 Princeton Satellite Systems, Inc.
%   All Rights Reserved
%--------------------------------------------------------------------------
%   Since version 10.
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
    
	d.Br    = 0.4;
  d.Bs    = 0.65;
  d.Hc    = 1.2;

  h       = [linspace(-10,10) linspace(10,-10)];
  n       = length(h);
  bP      = zeros(1,n);
  dT      = 1;
	hDot    = 20/(0.5*n*dT);
  hDot    = hDot*[ones(1,n/2) -ones(1,n/2)];
  b       = BFromHHysteresis(h(1),hDot(1),d);

  n       = length(h);

  for k = 1:n
      bP(k) = b;
      b     = RK4( 'MagneticHysteresis', b, dT, 0, h(k), hDot(k), d );
  end

  b    	= BFromHHysteresis(h,hDot,d);

  [t,tL]  = TimeLabl((0:(n-1))*dT);
  Plot2D(t,[b;bP],tL,'B','Hysteresis')
  legend('b(h)','Integrated');
  Plot2D(h,b,'H','B','Hysteresis Loop');
  hold on
  plot(h,bP,'g')
  return;
end

% Model based on the hyperbolic tangent curve
% b = bS*tanh(k*(h-hC)) hDot > 0
%   = bS*tanh(k*(hC+h)) hDot < 0
% d tanh / dh = k*(1 - tanh(u)^2)
%--------------------------------------------

k = atanh(d.Br/d.Bs)/d.Hc;
uL = k*(h + d.Hc);
uR = k*(h - d.Hc);
bL = d.Bs*tanh(uL);
bR = d.Bs*tanh(uR);
if( hDot < 0 )
  u = uL;
  f = (b-bR)/(bL-bR);
else
  u = uR;
  f = (bL-b)/(bL-bR);
end

dBDH = k*d.Bs*sech(u)^2; % (1 - tanh(u)^2);
bDot = f*dBDH*hDot;

if (b>d.Bs)
  bDot = 0;
elseif (b<-d.Bs)
  bDot = 0;
end

%--------------------------------------
% $Date: 2019-11-28 16:42:16 -0500 (Thu, 28 Nov 2019) $
% $Revision: 50446 $


