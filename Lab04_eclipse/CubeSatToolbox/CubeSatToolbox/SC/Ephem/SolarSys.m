function [rx0, ry0, rz0, vx, vy, vz] = SolarSys( iv, Wv, wv, av, ev, Lv, name, jdref, T )

%% Computes the position vectors of the planets as a function of time.
%   If no outputs are given will plot the positions of the input planets.
%   If no inputs are given it will compute the vectors for the entire
%   solar system. If T is not input, it will compute a vector of T's
%   long enough to show the complete orbit of the outermost planet.
%   Input data can be obtained from Planets.
%
%   If T is omitted in either form it will generate a T to cover the
%   orbital period of all of the planets. The second form handles the data
%   structure output of Planets which is d.iv, ...
%
%--------------------------------------------------------------------------
%   Form:
%   [rx0, ry0, rz0, vx, vy, vz] = SolarSys( iv, Wv, wv, av, ev, Lv, name, jdref, T )
%   [rx0, ry0, rz0, vx, vy, vz] = SolarSys( d, T )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   iv            (n,2)   Inclination wrt ecliptic plane     (rad)
%   Wv            (n,2)   Longitude of ascending node wrt vernal equinox  (rad)
%   wv            (n,2)   Argument of perhelion      (rad)
%   av            (n,2)   Mean distance (au)
%   ev            (n,2)   Eccentricity
%   Lv            (n,3)   Mean longitude (rad)
%   name          (n,:)   Name of planet
%   jdref         (1,1)   Reference Julian date
%     - OR - 
%   d              (:)    Data structure with above fields
%   T             (1,:)   Julian centuries from J2000.0   (centuries)
%
%   -------
%   Outputs
%   -------
%   rx0           (n,:)   x component,  one row per planet (au)
%   ry0           (n,:)   y component,  one row per planet (au) 
%   rz0           (n,:)   z component,  one row per planet (au) 
%   vx            (n,:)   vx component, one row per planet (km/s) 
%   vy            (n,:)   vy component, one row per planet (km/s) 
%   vz            (n,:)   vz component, one row per planet (km/s)  
% 
%                    n is the number of planets
%
%--------------------------------------------------------------------------
%   See also: Planets, PlanetPosition
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993-2001, 2008, 2016 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since 1.0
%   2008.1: allow input to be a data structure
%   2014.1: add watermark to plot
%   2016.1: preallocate vx, vy, vz
%--------------------------------------------------------------------------

% If T is not specified choose enough points to plot the entire
% orbit trace
%--------------------------------------------------------------
if ( nargin < 9 )
  if ( nargin == 0 )
    [name,av,ev,iv,Wv,wv,Lv,jdref] = Planets('rad',1:9);
  elseif( nargin < 3 )
    if( nargin == 2 )
        T = Wv;
    end

    name  = iv.name;
    av    = iv.a;
    ev    = iv.e;
    Wv    = iv.W;
    wv    = iv.w;
    Lv    = iv.L;
    jdref = iv.jDRef;
    iv    = iv.i;
  end
  
  if( nargin ~= 2 )
    Ttoday  = (Date2JD-jdref)/36525;   
    maxLv   = max(Lv(:,1)); 
    j       = find(Lv(:,1)==0); 
    if ( ~isempty(j) )
        dTmax   = 2*pi/min(Lv(j,3));  
    else
        dTmax   = 1/min(Lv(:,1));   
    end  
    if ( maxLv == 0 )
        npts = ceil(16*max(Lv(j,3))/min(Lv(j,3))); 
    else
        npts = ceil(16*maxLv*dTmax); 
    end 
    T       = linspace(Ttoday,Ttoday+dTmax,npts); 
  else
    npts = length(T);
  end
else
  npts    = length(T); 
end

% Create the vectors

[nr]=size(ev,1); 

rx = zeros(nr,npts);
ry = zeros(nr,npts);
rz = zeros(nr,npts);
vx = zeros(nr,npts);
vy = zeros(nr,npts);
vz = zeros(nr,npts);

twoPi = 2*pi;

for k = 1:npts
  i       = iv(:,1) + iv(:,2)*T(k);
  W       = Wv(:,1) + Wv(:,2)*T(k);
  w       = wv(:,1) + wv(:,2)*T(k);
  a       = av(:,1) + av(:,2)*T(k);
  e       = ev(:,1) + ev(:,2)*T(k); 
  L       = rem(rem(Lv(:,2)+twoPi*Lv(:,1)*T(k),twoPi) + Lv(:,3)*T(k),twoPi);
  wH      = w + W;
  M       = rem( L - wH, twoPi );
  j       = find( M < 0 );
  M(j)    = M(j) + twoPi;
  
  nu      = M2Nu( e, M );
  nuPW    = nu + w;

  cn      = cos(nuPW);  
  sn      = sin(nuPW);  
  ci      = cos(i); 
  si      = sin(i);  
  cW      = cos(W);  
  sW      = sin(W);   

  rmag    = a.*(1 - e.^2)./(1 + e.*cos(nu)); 

  mX      = cn.*cW - sn.*ci.*sW;
  mY      = cn.*sW + sn.*ci.*cW;
  mZ      = sn.*si;

  rx(:,k) = rmag.*mX;
  ry(:,k) = rmag.*mY;
  rz(:,k) = rmag.*mZ;
  
  if( nargout > 3 )
    au      = 149597870;
    muSun   =  1.327124e+11;
    cf      = cos(nu);  
    sf      = sin(nu);  
    cw      = cos(w);  
    sw      = sin(w);  
    muP     =  sqrt(muSun./(au*a.*(1-e).*(1+e)));
    vPX     = -muP.*sf;
    vPY     =  muP.*(e+cf);
 
    cXX     =  cW.*cw - sW.*sw.*ci;
    cXY     = -cW.*sw - sW.*cw.*ci;
    cYX     =  sW.*cw + cW.*sw.*ci;
    cYY     = -sW.*sw + cW.*cw.*ci;
    cZX     =  sw.*si;
    cZY     =  cw.*si;
  
    vx(:,k) = cXX.*vPX + cXY.*vPY;
    vy(:,k) = cYX.*vPX + cYY.*vPY;
    vz(:,k) = cZX.*vPX + cZY.*vPY;
  end
end

% Default output
%---------------
if ( nargout == 0 )
  hF = NewFig('Solar System');
  subplot(211)
  xx = max(max(abs(rx)));
  xy = max(max(abs(ry)));
  xz = max(max(abs(rz)));
  axis ([-xx xx -xy xy]);
  plot(rx',ry',rx(:,1)',ry(:,1)','*r')
  TextS(rx(:,1)',ry(:,1)',name)
  grid
  XLabelS('x')
  YLabelS('y')
  subplot(212)
  axis ([-xx xx -xz xz]);
  plot(rx',rz',rx(:,1)',rz(:,1)','*r')
  grid
  XLabelS('x')
  YLabelS('z')
  Watermark('Spacecraft Control Toolbox',hF);
else
  rx0 = rx;
  ry0 = ry;
  rz0 = rz;
end


%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 14:11:01 -0400 (Thu, 11 May 2017) $
% $Revision: 44563 $
