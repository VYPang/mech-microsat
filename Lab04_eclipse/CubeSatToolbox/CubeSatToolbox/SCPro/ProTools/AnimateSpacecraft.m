function m = AnimateSpacecraft( action, varargin )

%% Animate spacecraft CAD models in a relative frame
% You can add as may spacecraft as you like by adding more g's, r's and 
% q's. The window will be updated for each position/quaternion pair with a pause
% of 0.1 seconds in between.
%
% Type AnimateSpacecraft for a demo.
%--------------------------------------------------------------------------
%   Form:
%      AnimateSpacecraft( 'initialize', g1, g2, r1, q1, r2, q2 )
%  m = AnimateSpacecraft( 'update', t, r1, q1, r2, q2 )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   action  ''    'initialize' or 'update'
%   t       (1,:) Time vector
%   g       (:)   CAD data structures
%   q1      (4,:) Quaternion from ECI to body
%   r1      (3,:) ECI position vectors
%
%   -------
%   Outputs
%   -------
%   m       (1,:) Movie file
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2020 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 2020.1
%--------------------------------------------------------------------------

persistent p

% Demo
if( nargin < 1 )
  Demo
  return
end

switch( lower(action) )
  case 'initialize' 
    
    p.n = length(varargin)/3;
    for k = 1:p.n
      p.g(k) = varargin{k};
    end
    
    z = varargin(p.n+1:end);
    Initialize(z);
    
  case 'update'
    if( nargout == 1 )
      m = Update( varargin );
    else
      Update( varargin );
    end
end

%% AnimateSpacecraft>Initialize
function Initialize( z )

p.fig   = NewFig('Spacecraft Display' );

DrawCADModels( 'initialize', 0, z )

xlabel('x');
ylabel('y');
zlabel('z');
grid on
rotate3d on
axis image

p.ma=uimenu('parent',gcf,'label','Animate');
p.mp=uimenu('parent',p.ma,'label','Replay','Accelerator','A','enable','off');

end

%% AnimateSpacecraft>Update
function m = Update( x )
% x is a cell array of {r1, q1, r2, q2,...}

if isempty(get(p.fig,'userdata'))
  set(p.fig,'userdata', x);
  set(p.mp,'enable','on','callback','x=get(gcf,''userdata''); AnimateSpacecraft( ''update'', x{:} )');
end
  
nA = size(x{2},2);

if( nargout > 0 )
  % Allocate movie frame array
  n = getframe(p.fig);
  m(1:nA) = n;
end

for j = 1:nA
  t = x{1}(j);
  for i = 1:length(x)-1
    z{i} = x{i+1}(:,j);
  end
  DrawCADModels( 'update', t, z )
  if( nargout > 0 )
    m(j) = getframe(p.fig);
  end
  drawnow;
  pause(0.1)
end
  

end
 
%% AnimateSpacecraft>DrawCADModels
function DrawCADModels( action, t, z )
  
% Display the text
switch action
  case 'initialize'
    p.text = uicontrol('style','text','Position',[10,10,200,20],'fontsize',14);
    set(p.text,'String',sprintf('MET = %6.1f %s',t,'s'))    
    light('position',[10000 10000 10000]);
  otherwise
    [t,~,tU] = TimeLabl(t);
    set(p.text,'String',sprintf('MET = %6.1f %s',t,tU))
end    


rECI = zeros(3,p.n);
q    = zeros(4,p.n);

j    = 1;
for i = 1:p.n
  rECI(:,i) = z{j};
  q(:,i)    = z{j+1};
  j         = j + 2;
end


% Get the ECI rotation and translation matrices
[b, r]      = GetBAndR( p.g );

for i = 2:p.n
  rECI(:,i) = rECI(:,i) - rECI(:,1);
end

rECI(:,1) = [0;0;0];

% Convert to m
rECI = rECI*1000;

% The number of distinct patches
kP = 0;

ambientStrength = 0.3;

% Loop through the spacecraft
for kSC = 1:p.n  
  
  % Get the data structure
  g = p.g(kSC);
  
  b0 = Q2Mat(q(:,kSC));

  % Draw the spacecraft
  for t = 1:length( g.body ) % Outer loop is bodies
    c    = g.body(t).components;
    rK   = r(kSC,t).r' + rECI(:,kSC)';

    % Each component in the body
    for j = 1:length(c)
      u = c(j);
	    if( ~isempty(g.component(u).v)  && ~g.component(u).inside )
        v   = (b0*b(kSC,t).b*g.component(u).v')' + rK;
        kP  = kP + 1;

        switch  action
          case 'initialize'
            if( ( strcmpi(g.component(u).graphics.edgeColor,'truss') || strcmpi(g.component(u).graphics.edgeColor,'line')) )
              p.h(kP) = patch(  'Vertices', v, 'Faces',     g.component(u).f,...
                                'FaceColor',                g.component(u).graphics.faceColor,...
                                'ambientStrength',          ambientStrength,...
                                'DiffuseStrength',          g.component(u).graphics.diffuseStrength,...
                                'specularStrength',         g.component(u).graphics.specularStrength,...
                                'SpecularExponent',         g.component(u).graphics.specularExponent,...
                                'SpecularColorReflectance', g.component(u).graphics.specularColorReflectance,...
                              	'EdgeColor',  'none',...
                                'FaceLighting', 'gouraud');
            else
              p.h(kP) = patch(  'Vertices', v, 'Faces',     g.component(u).f,...
                                'FaceColor',                g.component(u).graphics.faceColor,...
                               	'ambientStrength',          ambientStrength,...
                                'DiffuseStrength',          g.component(u).graphics.diffuseStrength,...
                                'specularStrength',         g.component(u).graphics.specularStrength,...
                                'SpecularExponent',         g.component(u).graphics.specularExponent,...
                                'SpecularColorReflectance', g.component(u).graphics.specularColorReflectance,...
                                'EdgeColor',  'none',...
                                'FaceLighting', 'gouraud');
            end

          case 'update'
            set( p.h(kP), 'Vertices', v );
        end
      end
    end
  end
end

end

function [b, r] = GetBAndR( g )

% Do for each spacecraft
for kSC = 1:length( g )

  lG = length(g(kSC).body);

  % These are the transformation matrices to the previous body
  for j = 1:lG
    if( isfield( g(kSC).body(j), 'bHinge' ) )
      b(kSC,j).b = BHinge( g(kSC).body(j).bHinge );
    else
      b(kSC,j).b = eye(3);
    end
    b(kSC,j).bInitial = b(kSC,j).b;
  end

  % Compute the transformation matrices from each body to the inertial frame
  for j = 1:lG
    for i = 1:length(g(kSC).body(j).path)
      iBody      = g(kSC).body(j).path(i);
      b(kSC,j).b = b(kSC,iBody).bInitial*b(kSC,j).b;
    end
  end

  % Compute the position vectors back to the inertial frame
  % rHinge is always in the previous body's frame
  for j = 1:lG
    if( ~isempty( g(kSC).body(j).path ) )
      iBody      = g(kSC).body(j).path(1);
      r(kSC,j).r = b(kSC,iBody).b*g(kSC).body(j).rHinge;
      for i = 1:(length(g(kSC).body(j).path)-1)
        iBodyB     = g(kSC).body(j).path(i+1);
        iBodyR     = g(kSC).body(j).path(i);
        r(kSC,j).r = r(kSC,j).r + b(kSC,iBodyB).b*g(kSC).body(iBodyR).rHinge;
      end
    else
      r(kSC,j).r = g(kSC).body(j).rHinge;
    end
  end
end

end

%%AnimateSpacecraft>Demo
function Demo

g1        = load('SimpleSat');
g2        = g1;
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
view(3)
AnimateSpacecraft( 'update', t, r1, q1, r2, q2 );

end

end

%--------------------------------------
% $Date: 2020-06-29 21:50:13 -0400 (Mon, 29 Jun 2020) $
% $Revision: 52921 $
