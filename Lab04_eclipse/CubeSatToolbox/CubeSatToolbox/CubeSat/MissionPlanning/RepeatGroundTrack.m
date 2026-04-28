function d = RepeatGroundTrack( g, doplot )

%% Design a repeat ground-track orbit.
% Determines the semi-major axis values closest to the desired ratio of
% orbits / days. Utilizes the J2 drift to model the satellite orbit rate.
%--------------------------------------------------------------------------
%  Usage:
%  g = RepeatGroundTrack( 'input' );   
%  d = RepeatGroundTrack( g );   
%  d = RepeatGroundTrack( g, 1 );   % generates a plot
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   g       (.)   Data structure with fields
%                    .P0   Desired number of orbits (integer)
%                    .Q0   Desired number of days over which P0 orbits occur
%                    .inc  Orbit inclination (rad)
%                    .ecc  Orbit eccentricity
%                    .da   Range of semi-major axis values to consider (km)
%                    .PMax Maximum number of orbits to consider
%                    .QMax Maximum number of days to consider
%   doplot  (1)   Flag to create plot. Default 0.
%
%   -------
%   Outputs  
%   -------
%   d       (.)   Data structure with fields
%                    .P    Closest number of orbits to meet ratio (integer)
%                    .Q    Closest number of days to meet ratio (integer)
%                    .a0   Initial semi major axis guess
%                    .a    Closest semi major axis values to meet ratio
%                    .dLon Longitude drift per orbit
%                    .days Number of days per repeat
%                    .anomalisticPeriod   Anomalistic period (sec)
%                    .nodalPeriod         Nodal period (sec)
%
%   doplot (1,1)  Plotting flag. Set to 1 to create a plot.
%
%--------------------------------------------------------------------------
%   Reference: Vallado, "Fundamentals of Astrodynamics and Applications",
%   Second Edition. Sec. 11.4.2, Repeat-Groundtrack orbits.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2009 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 8.
%--------------------------------------------------------------------------

if( nargin < 2 )
   doplot = 0;
end

% demo
if( nargin<1 )
   g = Defaults; 
   d = RepeatGroundTrack( g, 1 );
   return;
end

% return sample input if requested
if( ischar(g) && strcmp(g,'input') )
   d = Defaults; 
   return;
end

if( ~isfield(g,'Qmax') || isempty(g.Qmax) )
   g.Qmax = g.Q0*4;
end
if( ~isfield(g,'Pmax') || isempty(g.Pmax) )
   g.Pmax = g.P0*4;
end
if( ~isfield(g,'da') || isempty(g.da) )
   g.da = 100;
end


% constants
rE = 6378.137;
mu = 398600.436;
J2 = 0.0010826; 

% nominal semi major axis, ignoring J2 effects
a0 = ((g.Q0/g.P0)*sqrt(mu)/(2*pi)*86400)^(2/3);
% allowable range to consider, in 1 km increments
a  = a0-g.da : 1 : a0+g.da;

% J2 effects
n     = sqrt(mu./a)./a;
f     = 3*n*J2*rE*rE./(2*a.^2*(1-g.ecc^2)^2);
c     =  cos(g.inc);
s     =  sin(g.inc);
wDot  = -f*(2.5*s^2 - 2);
WDot  = -f*c;
MDot  = -f*sqrt(1-g.ecc^2)*(1.5*s^2-1);

% satellite orbit rate with J2 perturbation
wS = n + wDot + MDot;

% earth rotation rate with respect to orbit plane that drifts at WDot
wE = 2*pi/86400 + 2*pi/365.25/86400 - WDot;
dLon = 360*wE./wS;

% find integer ratios.
% tol = 1.e-6*norm(X(:),1) is the default.
[num,den]=rat(wS./wE);

P0 = num;
Q0 = den;

  % apply limits on number of days and orbits
kLim = find(P0<=g.Pmax & Q0<=g.Qmax);
P = P0(kLim);
Q = Q0(kLim);

% compute the longitude error at the end of "P" orbits
orbitPeriod = 2*pi./wS;
longErr = rem(P0.*orbitPeriod.*wE * 180/pi,360);
longErr = min(longErr,360-longErr);

% sort the longitude error lowest to highest
[~,ks]=sort(longErr(kLim));

% keep only the unique integer ratios
[~,ku] = unique(P(ks)*100+Q(ks));
k = kLim(ks(ku)); 

d.P = P0(k);
d.Q = Q0(k);
d.a0 = a0;
d.a = a(k);
d.longErr = longErr(k);
d.dLon = dLon(k);
d.days = d.P .* (2*pi./wS(k)) / 86400;
d.anomalisticPeriod = 2*pi./wS(k);
d.nodalPeriod = 2*pi./(wE(k));


% plots
if( nargout==0 || doplot )
   NewFig('Repeat Ground Track')
   [x,j] = sort(d.a);
   plot(x,d.P(j)./d.Q(j),'-*')
   grid on
   hold on
   plot(d.a0,g.P0/g.Q0,'rs')
   text(d.a0,g.P0/g.Q0-.05,sprintf('P=%d, Q=%d',g.P0,g.Q0),'color','r');
   xlabel('Semi Major Axis (km)')
   ylabel('P/Q')
   for i=1:length(x)
      text(x(i),d.P(j(i))/d.Q(j(i))+.05,sprintf('P=%d, Q=%d',d.P(j(i)),d.Q(j(i))));
   end
   title('Ratio of Orbits / Days for Repeat Groundtrack')
end

function d = Defaults

d.P0      = 16;
d.Q0      = 1;
d.inc     = 45*pi/180;
d.ecc     = 0;
d.da      = 250; 


%--------------------------------------
% $Date: 2019-09-07 17:12:12 -0400 (Sat, 07 Sep 2019) $
% $Revision: 49734 $
