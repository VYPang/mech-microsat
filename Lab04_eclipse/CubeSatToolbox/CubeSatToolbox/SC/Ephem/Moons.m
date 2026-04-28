function s = Moons( name )
	
%% Lists moons of a planet or planet center about which a moon orbits.
%--------------------------------------------------------------------------
%   Form:
%   moons  = Moons( planetName )
%   center = Moons( moonName )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   name       (1,:)  Name of planet or moon
%
%   -------
%   Outputs
%   -------
%   s       {:} or (1,:)  Cell array of moons or string name of planet center
%
%--------------------------------------------------------------------------
%   References:   Seidelmann, The Explanatory Supplement to the Astronomical
%                 Almanac, University Science Books, 1992, pp.708-709.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1999 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

planet = {'mercury' 'venus' 'earth' 'mars' 'jupiter' 'saturn' 'uranus' 'neptune' 'pluto'};

moon = {'moon' ...
        'phobos'    'deimos' ...
        'io'        'europa'     'ganymede'   'callisto'   'amalthea'  'himalia'  'elara'    'pasiphae' ...
        'sinope'    'lysithea'   'carme'      'ananke'     'leda'      'thebe'    'adrastea' 'metis' ...
        'mimas'     'enceladus'  'tethys'     'dione'      'rhea'      'titan'    'hyperion' ...
        'iapetus'   'phoebe'     'janus'      'epimetheus' 'helene'    'telesto'  'calypso' ...
        'atlas'     'prometheus' 'pandora'    'pan' ...
        'ariel'     'umbriel'    'titania'    'oberon'     'miranda'   'cordelia' 'ophelia' 'bianca'  ...
        'cressida'  'desdemona'  'juliet'     'portia'     'rosalind'  'belinda'  'puck' ...
        'triton'    'nereid'     'naiad'      'thalassa'   'despina'   'galatea'  'larissa' 'proteus' ...
        'charon'};
        
center = {'earth' ...
          'mars'    'mars' ...
          'jupiter' 'jupiter' 'jupiter' 'jupiter' 'jupiter' 'jupiter' 'jupiter' 'jupiter' ...
          'jupiter' 'jupiter' 'jupiter' 'jupiter' 'jupiter' 'jupiter' 'jupiter' 'jupiter' ...
          'saturn'  'saturn'  'saturn'  'saturn'  'saturn'  'saturn'  'saturn'  'saturn'  ...
          'saturn'  'saturn'  'saturn'  'saturn'  'saturn'  'saturn'  'saturn'  'saturn'  ...
          'saturn'  'saturn' ...
          'uranus'  'uranus'  'uranus'  'uranus'  'uranus'  'uranus'  'uranus'  'uranus' ...
          'uranus'  'uranus'  'uranus'  'uranus'  'uranus'  'uranus'  'uranus' ...
          'neptune' 'neptune' 'neptune' 'neptune' 'neptune' 'neptune' 'neptune'  'neptune'...
          'pluto'};  
          
  
if length(name) > 3          
  j = strncmpi( name(1:4), planet, 4 );
elseif length(name) > 2
  j = strncmpi( name(1:3), planet, 3 );
elseif length(name) > 1
  j = strncmpi( name(1:2), planet, 2 );
else
  error('PSS:Moons:error','Invalid name for moon');
end 

if(any(j) )
  % find all moons with matching center
  k = strncmpi( name(1:4), center, 4 );
  s = moon(k);
else
  k = strcmpi( name, moon );
  s = center{k};
end


%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 14:11:01 -0400 (Thu, 11 May 2017) $
% $Revision: 44563 $
