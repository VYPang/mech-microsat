function rSunECI = SunVectorECI( action, varargin )

%% Finds the sun vector any place in the solar system.
%   Utilizes Planets and SolarSys to look up the planet ephemeris. If the
%   input is a moon, the nearest planetary center is used.
%--------------------------------------------------------------------------
%   Form:
%   SunVectorECI( 'initialize', center )
%   rSunECI = SunVectorECI( 'update', jD, rSc )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   action       (1,:)     'initialize' or 'update'
%
%   'initialize'
%   planetName   (1,:)     Center of spacecraft coordinates
%
%   'update'
%   jD           (1,1)     Julian date
%   rSC          (3,1)     Spacecraft ECI position vector (km)
%
%   -------
%   Outputs
%   -------
%   rSunECI      (3,1)     Sun ECI position vector
%
%--------------------------------------------------------------------------
%   See also: Planets, SolarSys, CEcl2Eq, Moons
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%	Copyright (c) 2004 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------

persistent p

if( nargin < 1 )
  SunVectorECI( 'initialize', 'earth' )
  SunVectorECI( 'update', JD2000, [7000;0;0] )
  SunVectorECI( 'initialize', 'pluto' )
  SunVectorECI( 'update', JD2000, [7000;0;0] )
  return;
end

switch action
  case 'initialize'
    center     = varargin{1};
    p.isPlanet = ~strcmp( center, 'sun' );
    
    if( p.isPlanet )
      planetList = Planets;
      kP = strmatch( lower(center), planetList );
      if( isempty(kP) )
        moonName = center;
        center = Moons( moonName );
      end
    
      [p.planet, p.aP, p.eP, p.iP, p.WP, p.wP, p.LP, p.jDRefP] = Planets( 'rad', center );
      p.aU = Constant('au');
    else
      p.planet = 'sun';
    end

  case 'update'

    jD  = varargin{1};
    rSc = varargin{2};

    c   = CEcl2Eq(jD);
    if( p.isPlanet )
      [rX0, rY0, rZ0] = SolarSys( p.iP, p.WP, p.wP, p.aP, p.eP, p.LP, p.planet, p.jDRefP, JD2T( jD ) );
      rSunEcl         = c'*rSc + [rX0;rY0;rZ0]*p.aU;
      rSunECI         = -c*rSunEcl;
    else
      rSunECI         = c*rSc;
    end

    if( nargout == 0 )
      disp(['Center is ' p.planet])
      disp(rSunECI)
      clear rSunECI
    end
end


%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 14:11:01 -0400 (Thu, 11 May 2017) $
% $Revision: 44563 $
