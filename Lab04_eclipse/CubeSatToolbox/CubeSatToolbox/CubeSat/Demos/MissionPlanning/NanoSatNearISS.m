%% Show ISS and NanoSat models with AnimateSpacecraft
% Loads two mat-files, Nanosat.mat and ISS.mat. Updates the display in a loop
% for one orbit to create an animation.
%
%  ------------------------------------------------------------------------
%  See also: ISSOrbit, RVOrbGen, El2RV, RV2El, QLVLH, AnimateSpacecraft
%  ------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2020 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since 2020.1
%--------------------------------------------------------------------------

g1        = load('Nanosat');
g2        = load('ISS');  
el1       = ISSOrbit;
el2       = el1 + [0 0 0 0 0 0.000001];
[r1,v1,t]	= RVOrbGen(el1);
[r2,v2]   = El2RV(el2);
v2(2)     = v2(2) + 0.000001;
el2       = RV2El(r2,v2);
[r2,v2]   = RVOrbGen(el2,t);
q1        = QLVLH(r1,v1);
q2        = QLVLH(r2,v2);

AnimateSpacecraft( 'initialize', g1, g2, r1(:,1), q1(:,1), r2(:,1), q2(:,1) );
m = AnimateSpacecraft( 'update', t, r1, q1, r2, q2 );


%--------------------------------------
% $Date: 2020-05-26 12:41:40 -0400 (Tue, 26 May 2020) $
% $Revision: 52411 $

