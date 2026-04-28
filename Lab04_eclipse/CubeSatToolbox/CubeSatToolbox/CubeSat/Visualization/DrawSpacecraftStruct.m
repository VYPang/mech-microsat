function g = DrawSpacecraftStruct()

%% Create the structure needed by DrawSpacecraftInOrbit
% Replace v and f with the vertex/face information for your model.
%--------------------------------------------------------------------------
%   Form:
%   g = DrawSpacecraftStruct()
%--------------------------------------------------------------------------
%   ------
%   Inputs
%   ------
%   None.
%
%   -------
%   Outputs
%   -------
%   g        (.)    Data structure
%                      .name    String name of spacecraft
%                      .v     (n,3)  Vertices  
%                      .f     (n,3)  Faces     
%                      .scale (1,1)  Scale     
%                      .color (1,3)  Color spacecraft
%                      .alpha (1,1)  Transparency (0-1)
%
%--------------------------------------------------------------------------
%  See also: DrawSpacecraftInOrbit
%--------------------------------------------------------------------------

%%
%---------------------------------------------------------------------
%   Copyright (c) 2017 Princeton Satellite Systems, Inc.
%   All rights reserved.
%---------------------------------------------------------------------
%   Since version 2017.1
%---------------------------------------------------------------------

g = struct;
g.name = '2U CubeSat';
[g.v,g.f] = CubeSatModel('2u',3);
g.color = [1 0 1];
g.alpha = .8;
g.scale = 1000;


%--------------------------------------
% $Date: 2018-11-07 14:29:46 -0500 (Wed, 07 Nov 2018) $
% $Revision: 47409 $
