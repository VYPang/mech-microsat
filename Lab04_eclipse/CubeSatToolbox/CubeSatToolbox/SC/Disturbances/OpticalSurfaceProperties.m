function p = OpticalSurfaceProperties( s )

%%   Returns optical surface properties for selected materials.
%   s is a cell array of strings. It returns a cell array of data
%   structures. For example
%
%   struct( 'sigmaT', 0, 'sigmaA', 0.00, 'sigmaD', 0.71 , 'sigmaS', 0.29 )
%
%   Available materials are found by typing OpticalSurfaceProperties
%
%   Since version 10.
%--------------------------------------------------------------------------
%   Form:
%   p = OpticalSurfaceProperties( s )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   s                 {:} Cell array of materials
%
%   -------
%   Outputs
%   -------
%   p                 (:) Data structure array
%                         .sigmaT (1,1) Transmitted
%                         .sigmaA (1,1) Absorbed
%                         .sigmaD (1,1) Diffuse reflection
%                         .sigmaS (1,1) Specular reflection
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2010 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

% Return available materials
%----------------------------
if( nargin < 1 )
  types = ListCases(mfilename,true);
  if nargout == 1
    p = types;
    return;
  end
  disp('===== SurfaceProperties Database =====')
  disp('Coefficients are: Absorbed, Diffuse, and Specular.')
  disp('They should sum to one.')
  for k = 1:length(types)
    opt = OpticalSurfaceProperties( types{k} );
    disp(types{k})
    mag = opt.sigmaA+opt.sigmaD+opt.sigmaS+opt.sigmaT;
    disp([opt.sigmaA opt.sigmaD opt.sigmaS mag])
  end
  return;
end

if ischar(s)
  s = {s};
end

optical = GenericProperties('optical');
p(length(s)) = optical;

for k = 1:length(s)
  transmissive = 0;
  switch lower(s{k})
    case 'gold foil'
      absorbed = 0.0;
      diffuse = 0.71;
      specular = 0.29;
    case {'solar panel', 'solar cell'}
      absorbed = 0.75;
      diffuse = 0.08;
      specular = 0.17;
    case 'mirror'
      absorbed = 0.15;
      diffuse = 0.16;
      specular = 0.69;
    case 'aluminum'
      absorbed = 0.27;
      diffuse = 2*0.73/3;
      specular = 0.73/3;
    case 'akm nozzle'
      absorbed =  0.1;
      diffuse = 0.78;
      specular = 0.12;
    case {'white','white paint'}
      absorbed = 0.2;
      diffuse = 0.52;
      specular = 0.28;
    case {'black','black paint'}
      absorbed = 0.2;
      diffuse = 0.52;
      specular = 0.28;
    case {'radiator' 'shunt'}
      absorbed = 0.15;
      diffuse = 0.16;
      specular = 0.69;
    case 'steel'
      absorbed = 0.42;
      diffuse = 2*0.58/3;
      specular = 0.58/3;
    otherwise
      disp([s{k} ' is not available']);
  end
  p(k).sigmaA = absorbed;
  p(k).sigmaT = transmissive;
  p(k).sigmaD = diffuse;
  p(k).sigmaS = specular;
end



%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 16:19:59 -0400 (Thu, 11 May 2017) $
% $Revision: 44571 $
