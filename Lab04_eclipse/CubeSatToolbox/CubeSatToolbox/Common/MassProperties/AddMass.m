function m = AddMass( mA, mB, u )

%% Add mass properties. 
% mB is optional. 
% mA and/or mB may be arrays of data structures.
%
% Typing AddMass returns the default data structure.
%--------------------------------------------------------------------------
%   Form:
%   m = AddMass( mA, mB, u )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   mA          (:)    Mass data structure
%                      .mass    (1,1) Mass
%                      .cM      (3,1) Center-of-mass
%                      .inertia (3,3) Inertia matrix about CM
%   mB          (:)    Mass data structure
%                      .mass    (1,1) Mass
%                      .cM      (3,1) Center-of-mass
%                      .inertia (3,3) Inertia matrix about CM
%   u           (1,:)  Units
%   
%   -------
%   Outputs
%   -------
%   m           (:)    Mass data structure
%                      .mass    (1,1) Mass
%                      .cM      (3,1) Center-of-mass
%                      .inertia (3,3) Inertia matrix
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1999, 2017 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 5.5.
%   2017.1 - Consolidated two for loops
%--------------------------------------------------------------------------

if( nargin == 0 )
  m = struct( 'mass', 0, 'cM', [0;0;0], 'inertia', zeros(3,3) );
  return;
end

if( nargin < 2 )
  mB = AddMass;
end

if( nargin < 3 )
  u = 'm';
end

if( ~isempty(mB) )
  mA = [mA mB];
end

switch u
  case 'in'
    g = 1/3.8609e+02;
  case 'm'
    g = 1;
  case 'ft'
    g = 12/3.8609e+02;
end

m.mass    = mA(1).mass;
m.cM      = mA(1).mass*mA(1).cM;
m.inertia = zeros(3,3);

for k = 2:length(mA)
  m.mass = m.mass + mA(k).mass;
  m.cM = m.cM + mA(k).mass*mA(k).cM;
end

if( m.mass > eps )
  m.cM = m.cM/m.mass;
else
  m.cM = [0;0;0];
end

for k = 1:length(mA)
  m.inertia = m.inertia + mA(k).inertia - g*mA(k).mass*SkewSq(mA(k).cM - m.cM);
end


%--------------------------------------
% $Date: 2020-04-22 14:36:52 -0400 (Wed, 22 Apr 2020) $
% $Revision: 51915 $
