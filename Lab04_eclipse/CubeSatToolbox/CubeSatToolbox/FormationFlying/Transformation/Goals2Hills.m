function xH = Goals2Hills( varargin )

%%  Compute a Hills state from geometric goals
% Computes the desired relative position and velocity in Hills frame, given the
% formation flying geometric "goals" and the reference orbital elements.
%--------------------------------------------------------------------------
%   Form:
%   xH = Goals2Hills( el0, goals )
%   xH = Goals2Hills( n, theta, goals )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   el0             (1,6)     Reference orbital elements (Alfriend format) [a,th,i,q1,q2,W]
%     -or-
%   n                (1)      Mean orbit rate [rad/sec]
%   theta            (1)      True latitude   [rad]
%
%   goals            (.)      Geometric goals data structure with following fields:
%     - y0          (1,:)        along-track offset                             [km]
%     - aE          (1,:)        semi-major axis of relative ellipse            [km]
%     - beta        (1,:)        angle on ellipse at perigee                   [rad]
%     - zInc        (1,:)        cross-track amplitude due to inclination diff  [km]
%     - zLan        (1,:)        cross-track amplitude due to right ascen diff  [km]
%
%   -------
%   Outputs
%   -------
%   xH              (6,:)     Hills frame position and velocity  
%                                [km; km; km; km/s; km/s; km/s]
%                                [ x;  y;  z;   Vx;   Vy;   Vz]
%
%--------------------------------------------------------------------------
%	  References:     Mueller, J. and M. Brito,"A Distributed Flight Software Design 
%                    for Satellite Formation Flying Control," presented at the AIAA 
%                    Space 2003 Conference, Long Beach, CA, September 2003.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%    Copyright (c) 2002 Princeton Satellite Systems, Inc. 
%    All rights reserved.
%--------------------------------------------------------------------------
%   Since version 7.
%--------------------------------------------------------------------------

% run demo if no inputs provided
if( nargin < 1 )
   xH = RunDemo;
   return;
end

% check inputs
if( nargin == 2 )
   el0   = varargin{1};   
   goals = varargin{2};
   th    = el0(2);
   n     = OrbRate(el0(1));
elseif( nargin == 3 )
   n     = varargin{1};
   th    = varargin{2};
   goals = varargin{3};
else
   error('incorrect number of inputs');
end

nG   = length(goals);
y0   = zeros(1,nG);
aE   = zeros(1,nG);
beta = zeros(1,nG);
zLan = zeros(1,nG);
zInc = zeros(1,nG);

for i=1:nG
   y0(i)   = goals(i).y0;
   aE(i)   = goals(i).aE;
   beta(i) = goals(i).beta;
   zLan(i) = goals(i).zLan;
   zInc(i) = goals(i).zInc;
end

% cosine and sine of the true latitude, theta (th)
%--------------------------------------------
cosTh = cos(th);
sinTh = sin(th);

% Compute the angle on a circle with radius aE
% that has a projected x-component equal to that
% of the relative ellipse:  
%  aE*sin(alpha0) = r*sin(beta0)
%----------------------------------------------
alpha0 = CirclePhase( beta );             % alpha at equator crossing
alpha  = alpha0 + th;                           % alpha at current true latitude

% cosine and sine of alpha
%-------------------------
ca     = cos(alpha);
sa     = sin(alpha);

% in-plane coordinates
%---------------------
x      = -0.5*aE.*ca;
y      = aE.*sa + y0;
xdot   = 0.5*aE.*sa*n;
ydot   = aE.*ca*n;

% out-of-plane coordinates
%-------------------------
z      =   zInc.*sinTh -   zLan.*cosTh;
zdot   = n*zInc.*cosTh + n*zLan.*sinTh;

xH     = [x;y;z;xdot;ydot;zdot];

%-----------------------------------------
% Run built-in demo
%-----------------------------------------
function xH = RunDemo

e   = 1e-4;
w   = 2*pi/3;
el0 = [7000, pi/3, pi/4, e*cos(w), e*sin(w), pi/6];

g.y0   = [-1 0 1];
g.aE   = [.5 .5 .5];
g.beta = [-pi/4 pi/4 3*pi/4];
g.zInc = [0  .25  .5];
g.zLan = [.5 .25   0];

xH = Goals2Hills( el0, g );

%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-09 15:16:37 -0400 (Tue, 09 May 2017) $
% $Revision: 44523 $
