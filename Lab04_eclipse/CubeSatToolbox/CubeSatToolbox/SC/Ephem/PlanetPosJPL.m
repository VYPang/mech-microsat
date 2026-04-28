function [r, mu, v] = PlanetPosJPL( action, d, ecl )

%% Get positions for an array of planets using the JPL ephemeris.
% Gives the position vectors, gravitational parameters and velocity
% for the planets. The frame is heliocentric and can be either in the Earth's 
% equatorial plane (default) or the ecliptic plane. 
% Modeled after PlanetPosition.
%
%     0. Sun (at origin)
%     1. Mercury
%     2. Venus
%     3. Earth
%     4. Mars
%     5. Jupiter
%     6. Saturn
%     7. Uranus
%     8. Neptune
%     9. Pluto
%    10. Geocentric Moon
%    11. Earth-Moon Barycenter
%
% This calls the function InterpolateState which returns planet states in the
% Earth equatorial frame and measured from the solar system barycenter.
%
% You must first initialize this function with a set of planet IDs and then
% you can retrieve the states for a specific Julian date.
%--------------------------------------------------------------------------
%   Form:
%                PlanetPosJPL( 'initialize', id )
%   [r, mu, v] = PlanetPosJPL( 'update', jD, ecl )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   action    (1,:)       'initialize' or 'update'
%   id  or jD	(1,n)       Julian date (days) for update or planet ids
%   ecl       (1,1)       Flag for ecliptic plane (1), default is equatorial (0)
%
%   -------
%   Outputs
%   -------
%   r         (3,n)       Planetary position vectors
%   mu        (1,n)       Corresponding gravitational parameters
%   v         (3,n)       Velocity vectors
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2006, 2017 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 7
%   2016.1 - Add booleans for Earth/Moon to reduce duplicate calls when used in
%            a loop.
%   2016.2 - Fix a bug in the booleans when the only planet is the moon.
%   2017.2 - Now uses lnxp1600p2200.405 that is good until February 20, 2201
%--------------------------------------------------------------------------

persistent id
persistent need3
persistent need10
persistent Cecl

if nargin == 0
  
  % Demo
  %-----
  PlanetPosJPL( 'initialize', 1:9 );
  [r, mu, v] = PlanetPosJPL( 'update', Date2JD, 1 );
  clear r
  return;
end
if isempty(Cecl)
  Cecl = CEcl2Eq( 2451545 )';
end

if nargin < 3
  ecl = false;
else
  if length(ecl) ~= 1
    error('PSS:PlanetPosJPL','Ecliptic flag must be a scalar.');
  end
end

switch action
  case 'initialize'
    if ~InterpolateState([])
      InterpolateState([],[],'lnxp1600p2200.405');
    end
    id = d;
    need3 = false;
    need10 = false;
    if any(id==3)
      need3 = true;
      need10 = true;
    end
    if any(id==10) && ~need10
      need10 = true;
      if ~need3
        need3 = true;
      end
    end
    if any(id==11) && ~need3
      need3 = true;
    end
	
  case 'update'
    jD   = d;
    %if( jD > 2458866.5 )
    if( jD > 2525008.5 )
      error( 'Julian date must be less than 2525008.5' );
    end
    nPts = length( id );
    r    = zeros(3,nPts);
    v    = zeros(3,nPts);
    mu   = zeros(1,nPts);
    % Sun from solar system barycenter
    %---------------------------------
    [Xs,muS] = InterpolateState(11,jD);
    if need3
      % Need EM barycenter
      [Xb,muB] = InterpolateState(3,jD);
    end
    if need10
      % geocentric moon
      [Xm,EMRAT] = InterpolateState(10,jD);
    end
    for k = 1:nPts
      if id(k) > 0
        if id(k) == 11 || id(k) == 3
          Xp = Xb;
          mu(k) = muB;
        elseif id(k) == 10
          Xp = Xm;
          mu(k) = EMRAT;
        else
          [Xp,mu(k)] = InterpolateState(id(k),jD);
        end
        if id(k) == 3
          % adjust using moon since 3 gives Earth-Moon barycenter
          %------------------------------------------------------
          %[Xm,EMRAT] = InterpolateState(10,jD);
          Xp = Xp - Xm/(1+EMRAT);
          mu(k) = mu(k)*(1-1/EMRAT);
        end
        if id(k) == 10
          % Need EM barycenter for gravitational parameter
          % Preserve moon state as geocentric
          %[Xx,muB] = InterpolateState(3,jD);
          mu(k) = muB/mu(k);
          r(:,k) = Xp(1:3);
          v(:,k) = Xp(4:6);
        else
          r(:,k) = Xp(1:3)-Xs(1:3);
          v(:,k) = Xp(4:6)-Xs(4:6);
        end          
      else
        r(:,k) = [0;0;0];
        v(:,k) = [0;0;0];
        mu(k) = muS;
      end % if
    end % for
    
    au = 149597870.691;
    mu = mu*au^3/86400^2;
    
    if ecl
      r = Cecl*r;
      v = Cecl*v;
    end
    
  case 'planets'
    r = id;
end
      

%--------------------------------------
% $Date: 2020-07-13 15:07:25 -0400 (Mon, 13 Jul 2020) $
% $Revision: 53041 $
