function d = AddThermalConductivity( d, i, j, k )

%% Add a thermally conductive path between cubesat faces
% Ensures that the thermal conductivity matrix, d.k, is consistent.
%
%--------------------------------------------------------------------------
%   Form:
%   d = AddThermalConductivity( d, i, j, k )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   d      (.)     Thermal data structure
%                    .mass       (1,6) or (1,1) face mass or total mass
%                    .uSurface   (3,6) Surface unit vectors
%                    .alpha      (1,6) Absorptivity
%                    .epsilon    (1,6) Emissivity
%                    .area       (1,6) Area
%                    .cP         (1,1) Specific heat
%                    .powerTotal (1,6) or (1,1) Internal power (W)
%                    .k          (6,6) Thermal conductivity (W/deg-K)
%   i      (1,1)    Index of one of the nodes (1-6)
%   j      (1,1)    Index of the other node (1-6)
%   k      (1,1)    The thermal conductivity value (Watts per Kelvins)
%
%   -------
%   Outputs
%   -------
%   d      (.)    Thermal data structure with the adjusted d.k thermal
%                    conductivity matrix
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2019 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since 2019.1
%--------------------------------------------------------------------------

if( nargin < 1 )
  d = struct('k',2*ones(6,6));
  dOut = AddThermalConductivity( d, 1, 2, 1 );
  StructToText(dOut)
  clear d;
  return
end

d.k(i,j) = d.k(i,j) - k;
d.k(j,i) = d.k(j,i) - k;
d.k(i,i) = d.k(i,i) + k;
d.k(j,j) = d.k(j,j) + k;


%--------------------------------------
% $Date: 2020-06-19 15:04:48 -0400 (Fri, 19 Jun 2020) $
% $Revision: 52850 $

