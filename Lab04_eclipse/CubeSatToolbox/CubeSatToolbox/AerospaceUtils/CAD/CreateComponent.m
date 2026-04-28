function m = CreateComponent( action, type, varargin )

%% Create a CAD component. This function has a built-in demo. 
%
% Available calls which return help information are:
%
% m     = CreateComponent()  Returns a demo component
% types = CreateComponent( 'type' ) Lists all available component types
% param = CreateComponent( 'parameter', type ) Lists all parameters for type
% param = CreateComponent( type ) also lists all parameters
%         CreateComponent( 'inputs' ), additional generic inputs
%         CreateComponent( 'colors' ), creates a GUI with named colors
%
% The call to create a component is:
%
% m = CreateComponent( 'make', type, param1, val1, ..., paramN, valN )
%
% This function creates the data structure for the component using the parameter 
% pairs param1,val1 through paramN,valN. m can be input to BuildCADModel.
% The common parameter structures are:
%    'thermal' 'mass' 'power' 'optical' 'infrared' 'aero' 'rf' 
%     'magnetic' 'propulsion' 'graphics'
%
% Notes:
% - The last action creates a GUI with available named colors.
% - Note that the parameter 'mass' may be a mass structure (mass, cM, inertia).
% - Components are all inside by default (inside=1).
% - The parameter 'n', number of divisions, is optional in many geometric
%   primitives, such as sphere and cylinder.
% - Specifying a named color will override both the graphics and optical
%   properties. If this is not the desired behavior specify an RGB triple
%   instead.
% - Specify a 'generic' component to enter just vertices ('vertex') and faces ('face').
% - Specify an 'empty' component for the default data structure.
%
% See also GenericProperties and DeviceProperties.
%
%--------------------------------------------------------------------------
%   Form:
%   m = CreateComponent( action, type, varargin )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   action        ':'    Action 'type', 'parameters', 'make'
%   type         (1,:)   Type of component
%   varargin     (:,:)   Parameter pairs
%
%   -------
%   Outputs
%   -------
%   m             (.)    Component data structure
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2002-2003, 2016 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   2016-02-24: In Make, improve speed by checking generic types first before
%   getting list of all types from DeviceProperties, since that reads the file
%   line by line and is slow. Add subfunctions DisplayComponent and
%   ListGenerics. Update handling of CubeSat component.
%--------------------------------------------------------------------------

% A demo
%-------
if( nargin < 1 )
    action	= 'make';
    type    = 'box';
    v       = {'x', 1, 'y', 2, 'z' , 3, 'name' , 'Test'};
    m       = CreateComponent( action, type, v{:} );
    DisplayComponent(type,m);
    return
end

switch action
  case {'types','type'}
      
        % Return available component types
        %---------------------------------
        m = GetTypes;
        if( nargout == 0 )
            disp('------------------------------');
            disp('Components');
            disp('------------------------------');
            disp(m');
            clear m;
        end
        return;
	
  case {'parameters', 'parameter'}
      
        % Return the parameters for a given type
        %---------------------------------------
        m = GetParameters( type );
        if( nargout == 0 )
            disp('------------------------------');
            disp(['Parameters for ' type]);
            disp('------------------------------');
            disp(m');
            clear m;
        end
        return;
	
  case 'inputs'
      
        % Return a list of inputs available for components
        %-------------------------------------------------
        [m, desc] = GenericInputs;
        if( nargout == 0 )
            disp('------------------------------');
            disp('Additional generic inputs');
            disp('------------------------------');
            for k = 1:length(m)
                fprintf(1,'%20s\t%s\n',m{k},desc{k});
            end
            clear m;
        end
        return;
    
  case 'make'
      
        % Make a component
        %-----------------
        m = Make( type, varargin{:} );
	
  case 'colors'
      
        % Display the colors available by name
        %-------------------------------------
        DisplayColors;
        return;
	
    otherwise
        type   = action;
        m      = GetParameters( type );
        return;
end

% If the output is not specified it will draw the component
% and print out information about the component
%----------------------------------------------------------
if( nargout == 0 )
  DisplayComponent(type,m)
  clear m
end

%--------------------------------------------------------------------------
%  Display component
%--------------------------------------------------------------------------
function DisplayComponent(type,m)

fprintf(1,'------------------------------\nComponent Data Structure\n------------------------------\n');
disp(m)
fprintf(1,'------------------------------\nParameters\n------------------------------\n');
s = GetParameters(type);
for j = 1:length(s)
  disp(s{j});
end
NewFig(m.name)
patch('vertices',m.v,'faces',m.f,'faceColor',m.graphics.faceColor);
axis equal
XLabelS('x')
YLabelS('y')
ZLabelS('z')
view(3)
grid on
rotate3d on
s = 10*max(Mag(m.v'));
light('position',s*[1 1 1]);

%--------------------------------------------------------------------------
%	 Get types
%--------------------------------------------------------------------------
function m = GetTypes

m = GenericTypes;    
t = DeviceProperties;
m = [m t];

%--------------------------------------------------------------------------
%	 Get types
%--------------------------------------------------------------------------
function m = GenericTypes
m = { 'sphere' 'box' 'cylinder' 'cubesat' 'hollow cylinder' 'hollow box'...
      'hollow sphere' 'antenna' 'ellipsoid' 'surface of revolution' 'triangle'...
      'empty' 'generic'};

%--------------------------------------------------------------------------
%	 Get parameters
%--------------------------------------------------------------------------
function m = GetParameters( type )

zD = [];

% Type-specific properties for defining geometry
%-----------------------------------------------
switch type
  case 'sphere',                    m = {'radius','n'};
  case 'cubesat',                   m = {'nU'};
  case 'box',                       m = {'x' 'y' 'z' 'openFace'};
  case 'cylinder',                  m = {'rUpper' 'rLower' 'h','n'};
  case 'hollow cylinder',           m = {'rUpper' 'rLower' 'h' 'thickness','n'};
  case 'hollow box',                m = {'x' 'y' 'z' 'thickness'};
  case 'hollow sphere',             m = {'radius' 'thickness','n'};
  case 'ellipsoid',                 m = {'abc','thetaUpper','n'};
  case 'surface of revolution',     m = {'a' 'n' 'zUpper' 'zLower'};
  case 'triangle',                  m = {'x' 'y' 'z'};
  case 'antenna',                   m = {'x', 'y', 'd' 'theta' 'boresight' 'xUnitVector' 'nFacets'};
  case 'generic',                   m = {'vertex' 'face' };
  case 'empty',                     m = {};
  otherwise
    % Component-specific properties
    %------------------------------
    [zD,m] = DeviceProperties( type );
end

% Properties common to all components
%------------------------------------
s = ListGenerics;
for k = 1:length(s)
  z = GenericProperties( s{k} );
  f = fieldnames( z );
  for j = 1:length(f)
    m = [m {[s{k} '.' f{j}]}]; %#ok<AGROW>
  end
end

if( isempty(zD) )
  return
end

% Store any device info
%----------------------
f = fieldnames( zD );
for j = 1:length(f)
  m = [m {['deviceInfo.' f{j}]}]; %#ok<AGROW>
end


%--------------------------------------------------------------------------
% List of generic properties groups
%--------------------------------------------------------------------------
function s = ListGenerics

s = {'thermal' 'mass' 'power' 'optical' 'infrared' 'aero' 'rf' 'magnetic'...
     'propulsion' 'graphics'};


%--------------------------------------------------------------------------
% Other generic properties
%--------------------------------------------------------------------------
function [f,desc] = GenericInputs

f    = {'name' 'rB' 'b' 'rA' 'body'...
        'inside' 'dataFileName' 'model' 'manufacturer' };
desc = {...
        'Name of component',...
        'Displacement of component before rotation',...
        'Rotation transformation matrix',...
        'Displacement of component after rotation',...
        'ID of body to which component is attached',...
        'If a body is inside the model it is not used in disturbance calculations',...
        'Data file name, passed to BuildCADModel',...
        'Model string',...
        'name of manufacturer',...
       };
   

%--------------------------------------------------------------------------
%	 Make a component
%--------------------------------------------------------------------------
function m = Make( type, varargin )

m               = struct;
m.name          = 'no name';
m.class         = 'generic';
m.rB            = zeros(3,1);
m.b             = eye(3);
m.rA            = zeros(3,1);
m.body          = 1;
m.inside        = 1;
m.dataFileName  = '';
m.model         = 'N/A';
m.manufacturer  = 'N/A';
m.deviceInfo    = [];
m.v             = [];
m.f             = [];
computeInertia  = true;

% Check to see if the type is supported
%--------------------------------------
t = GenericTypes;    
k = strcmp( type, t );

if( ~any(k) )
  t = DeviceProperties;
  k = strcmp( type, t );
end
if( ~any(k) )
  MessageQueue('add', 'CreateComponent',sprintf('Component type %s is not available',type));
  unknownType = 1;
else
  unknownType = 0;
end

% Class
%------
m.class = MakeClass( type );

% Check to make certain that an even number of properties and values have been entered
%--------------------------------------------------------------------------
nIn = size(varargin,2)/2;

if( floor(nIn) ~= nIn )
  MessageQueue('add', 'CreateComponent',sprintf('You have not entered property/value pairs for %s',type),'error');
  return
end

% Break into parameters and values
%---------------------------------
f = varargin(2*(1:nIn)-1);
v = varargin(2*(1:nIn));

if(length(unique(f))<nIn)
  warning('Repeated parameters supplied to CreateComponent.');
end

% Assign all variable values locally
%-----------------------------------
for k = 1:length(f)
    if( ~strcmp(f{k},'f') && ~strcmp(f{k},'v') )
        eval( [f{k} ' = v{k};' ]);
    end
    
    if( strcmp(f{k},'f') )
        face = v{k};
    end
    
    if( strcmp(f{k},'v') )
        vertex = v{k};
    end
end

% Add in generic properties that all components have
%---------------------------------------------------
fST = ListGenerics;
for k = 1:length(fST)
  thisField = fST{k};
  % Get the default values
  m.(thisField) = GenericProperties( thisField );
  % Check for structure inputs
  i = strcmp( thisField, f );
  if( any(i) )
    if( isstruct( v{i} ) )
      thisValue = v{i};
      fV = fieldnames( thisValue );
      fE = fieldnames(m.(thisField));
      for j = 1:length(fV)
        if any(strcmp(fV{j},fE))
          m.(thisField).(fV{j}) = thisValue.(fV{j});
        end
      end
      v = DeleteCell( v, i );
      f = DeleteCell( f, i );
      if strcmp(thisField,'mass')
        computeInertia = false;
      end
    end
  end
end

i = strcmp( 'inside', f );
if(any(i))
  m.inside = v{i};
  v = DeleteCell( v, i );
  f = DeleteCell( f, i );
end

% Handle inertia and input mass structure
%-------------------------------------------------
i = strcmp( 'inertia', f );
if( any(i) )
  m.mass.inertia = v{i};
  v              = DeleteCell( v, i );
  f              = DeleteCell( f, i );
  computeInertia = false;
end

i = strcmp( 'mass', f );
if( any(i) )
  if( isstruct( v{i} ) )
    m.mass         = v{i};
    computeInertia = false;
  else
	  m.mass.mass = v{i};
  end
  v = DeleteCell( v, i );
  f = DeleteCell( f, i );
end

% Handle power
%-------------
i = strcmp( 'power', f );
if( any(i) )
	if( isstruct( v{i} ) )
      m.power         = v{i};
  else
      m.power.powerOn = v{i};
  end
  v = DeleteCell( v, i );
  f = DeleteCell( f, i );
end

% Get inputs common to all components
%------------------------------------
g = GenericInputs;

for k = 1:length(g)
  i = strcmp( g{k}, f );
  if( any(i) )
    m.(g{k}) =  v{i};
    f = DeleteCell( f, i );
    v = DeleteCell( v, i );
  end
end

% Look for vertices and faces
%----------------------------
i = strcmp( 'vertex', f );
if( any(i) )
  m.v = vertex;
  f   = DeleteCell( f, i );
  v   = DeleteCell( v, i );
end

i = strcmp( 'face', f );
if( any(i) )
  m.f = face;
  f   = DeleteCell( f, i );
  v   = DeleteCell( v, i );
end

i = strcmp( 'v', f );
if( any(i) )
  m.v = vertex;
  f   = DeleteCell( f, i );
  v   = DeleteCell( v, i );
end

i = strcmp( 'f', f );
if( any(i) )
  m.f = face;
  f   = DeleteCell( f, i );
  v   = DeleteCell( v, i );
end

% Model
%------
if( ~isfield(m,'model') )
  m.model = 'generic';
end

% Manufacturer
%-------------
if( ~isfield(m,'manufacturer') )
  m.manufacturer = 'none';
end

% Get device information
%-----------------------
if( unknownType )
  if(   any(strcmp( 'x', f )) ...
      && any(strcmp( 'y', f )) ...
      && any(strcmp( 'z', f )) )
    [v, f]     = RemoveCells( v, f, 'x', 'y', 'z' );
    [m.v, m.f] = Box( x, y, z );
  end
end

% Get default device properties
%------------------------------
if( ~any(strcmp(type,GenericTypes)) )
   [deviceInfo,deviceFields] = DeviceProperties( type );
else
   deviceInfo = [];
   deviceFields = {};
end
   
% Set any device properties specified in property/value list
%-----------------------------------------------------------
m.deviceInfo = deviceInfo;
if( ~isempty(deviceInfo) )
  fN = fieldnames( deviceInfo );
  for k = 1:length(fN)
    i = find(strcmp( fN{k}, f ));
  	if( ~isempty(i) )
      eval(['m.deviceInfo.' fN{k} ' = v{i};']);
      v = DeleteCell( v, i );
      f = DeleteCell( f, i );
  	end
  end
end
    
openFace = '';
 
% Geometry information
%---------------------
switch type
    % Geometric primitives
    %---------------------
    case {'sphere'}
      if( exist('radius','var') )
        [v, f]     = RemoveCells( v, f, 'radius' );
        if( exist('n','var') )
          [m.v, m.f] = GeomPatch( struct('a',radius,'b',radius,'c',radius, 'n', n) ); %#ok<NODEF>
          [v,f]      = RemoveCells( v, f, 'n' );
        else
          [m.v, m.f] = GeomPatch( struct('a',radius,'b',radius,'c',radius) );
        end
        if( computeInertia )
          m.mass.inertia = Inertias( m.mass.mass, radius, 'sphere', 1 );
        end

      end
      
    case {'cubesat'}
        [v, f]     = RemoveCells( v, f, 'nU' );
        [m.v, m.f] = CubeSatModel( nU, 0, 1 );
	
    case {'box'}
      [v, f]     = RemoveCells( v, f, 'x', 'y', 'z', 'openFace' );
      [m.v, m.f] = Box( x, y, z, openFace );
      if( computeInertia )
        m.mass.inertia = Inertias( m.mass.mass, [x y z], 'box', 1 );
      end

    case {'cylinder'}
      % cylinder origin is at the base
      % h is along the z axis of the frustrum
      if ~exist('n','var')
        n = 12; 
      else
        [v,f] = RemoveCells( v, f, 'n' ); 
      end
      [v, f]     = RemoveCells( v, f, 'rUpper', 'rLower', 'h' );
  	  [m.v, m.f] = Frustrum( rUpper, rLower, h, n, 0, 0 );
  	  if( computeInertia )
          m.mass.inertia = Inertias( m.mass.mass, [0.5*(rUpper + rLower) h], 'cylinder', 1 );
      end
      m.mass.cM = [0;0;h/2];

    case 'hollow cylinder'
      if ~exist('n','var')
        n = 12; 
      else
        [v,f] = RemoveCells( v, f, 'n' ); 
      end
      [v, f]     = RemoveCells( v, f, 'rUpper', 'rLower', 'h', 'thickness' );
 	   [m.v, m.f] = Frustrum( rUpper, rLower, h, n, 0, 0 );
  	  if( computeInertia )
          m.mass.inertia = Inertias( m.mass.mass, [0.5*(rUpper + rLower) h thickness], type, 1 );
      end
		
   case 'hollow box'
      [v, f]     = RemoveCells( v, f, 'x', 'y', 'z', 'thickness' );
      [m.v, m.f] = Box( x, y, z );
	    if( computeInertia )
          m.mass.inertia = Inertias( m.mass.mass, [x y z thickness], type, 1 );
      end
	
    case 'hollow sphere'
      [v,f]      = RemoveCells( v, f, 'radius', 'thickness' );
      [m.v, m.f] = GeomPatch( struct('a',radius,'b',radius,'c',radius) );
	    if( computeInertia )
          m.mass.inertia = Inertias( m.mass.mass, [radius thickness], type, 1 );
      end

    case 'triangle'
      [v, f]     = RemoveCells( v, f, 'x', 'y', 'z' );
      [m.v, m.f] = Triangle( x, y, z );
      
    case 'ellipsoid'
      if ~exist('n','var')
        n = 10; 
      else
        [v,f] = RemoveCells( v, f, 'n' ); 
      end
      [v,f]      = RemoveCells( v, f, 'abc', 'thetaUpper' );
      [m.v, m.f] = GeomPatch( struct('a',abc(1),'b',abc(2),'c',abc(3),'thetaUpper',thetaUpper,'n',n) );
	    if( computeInertia )
          m.mass.inertia = Inertias( m.mass.mass, abc, type, 1 );
      end
	
    case 'surface of revolution'
      [v,f]      = RemoveCells( v, f, 'a', 'n', 'zUpper','zLower' );
      [m.v, m.f] = GeomPatch( struct('a',a,'n',n,'zUpper',zUpper,'zLower',zLower) ); %#ok<NODEF>
	      
    case 'antenna'
      [v,f]       = RemoveCells( v, f, 'd', 'x', 'y', 'theta', 'theta','boresight','xUnitVector','nFacets' );
      [m.v, m.f]  = AntennaPatch( x, y, d, theta, boresight, xUnitVector, nFacets );
		
    case 'generic'
      m.v = vertex;
      m.f = face;
	
    case 'empty'
    
    otherwise
      deviceParams = {};
      kMissingFields = [];
      for k = 1:length(deviceFields)
        if exist(deviceFields{k},'var')
          deviceParams{end+1} = eval(deviceFields{k}); %#ok<AGROW>
        else
          kMissingFields(end+1) = k; %#ok<AGROW>
        end
      end
      foundFields = DeleteCell( deviceFields, kMissingFields );
      
      [v,f] = RemoveCells( v, f, foundFields{:} ); 
      m = DeviceProperties( type, m, foundFields, deviceParams, computeInertia );
      
 end

% Check the color
%----------------
i = find(strcmp( 'faceColor', f ));
if( ~isempty(i) )
  m.graphics.faceColor = faceColor;
  f   = DeleteCell( f, i );
  v   = DeleteCell( v, i );
end

% If the face color is a name find the rgb vector
%------------------------------------------------
if( ischar( m.graphics.faceColor ) )
  m = SetColorAndSurfaceProps( m );
end

% See if any remaining values are in the generic structures
%----------------------------------------------------------
jD = [];
for k = 1:length(fST)
  fN = fieldnames( m.(fST{k}) );
  for j = 1:length(f)
    ii = strcmp( f{j}, fN );
    if( any(ii) )
      eval(sprintf('m.%s.%s = v{j};',fST{k},f{j}));
      jD = [jD j]; %#ok<AGROW>
    end
  end
end

v = DeleteCell( v, jD );
f = DeleteCell( f, jD );

for k = 1:length(fST)
    j = find(strcmp(fST{k},f));
    if( ~isempty(j) )
        v = DeleteCell( v, j );
        f = DeleteCell( f, j );
    end
end

j = strcmp( 'deviceInfo', f );
if( any(j) )
  v = DeleteCell( v, j );
  f = DeleteCell( f, j );
end

j = strcmp( 'class', f );
if( any(j) )
  v = DeleteCell( v, j ); %#ok<NASGU>
  f = DeleteCell( f, j );
end

% Add the number of vertexes per face
%------------------------------------
m.nV        = 3*ones(size(m.f,1),1);

% These will be computed in BuildCADModel
%----------------------------------------
m.a         = [];
m.n         = [];
m.r         = [];
m.radius	  = [];

% Generate warnings for unused/unrecognized fields.
%--------------------------------------------------
if ~isempty(f)
  fprintf(1,'CreateComponent: %s: \n\tThe following fields were not recognized as device properties, but have been added to your component.\n\t',m.name);
  fprintf(1,'To make a device property recognized, add it to the list in the "%s" case of DeviceProperties.m.\n\t',type);  disp(f);
end

%--------------------------------------------------------------------------
%	 Delete blanks and make lower case
%--------------------------------------------------------------------------
function s = MakeClass( s )

s    = lower(s);
k    = strfind(s,' ');
s(k) = '_';

%--------------------------------------------------------------------------
%   Use a predefined color.
%--------------------------------------------------------------------------
function  m = SetColorAndSurfaceProps( m )

% MATLAB                     "shiny"   "metal"     "dull"
% - SpecularColorReflectance:   1        0.5         1
% - SpecularExponent:          20        25         10
% - SpecularStrength:         0.9        1           0
% - DiffuseStrength:          0.6       0.3         0.8
% - AmbientStrength:          0.3       0.3         0.3

switch lower(deblank(m.graphics.faceColor) )
  case 'solar cell'
    m.graphics.faceColor                 = [0.15 0   1];
    m.graphics.edgeColor                 = [0.15 0.5 1];
    m.graphics.specularExponent          = 10;
    m.graphics.specularStrength          = 1;
    m.graphics.diffuseStrength           = 0.3;
    m.graphics.ambientStrength           = 0.2;
    m.graphics.specularColorReflectance  = 0.5;
    m.optical = OpticalSurfaceProperties( 'solar cell' );

  case 'mirror'  % shiny
    m.graphics.faceColor                 = [1 1 1];
    m.graphics.edgeColor                 = [1 1 1];
    m.graphics.specularStrength          = 0.9;
    m.graphics.diffuseStrength           = 0.6;
    m.graphics.ambientStrength           = 0.2;
    m.graphics.specularExponent          = 100;
    m.graphics.specularColorReflectance  = 1;
    m.optical = OpticalSurfaceProperties('mirror');
	
  case 'gold foil' % shiny
    m.graphics.faceColor                 = [1 0.8 0.34];
    m.graphics.edgeColor                 = [1 0.8 0.34];
    m.graphics.specularStrength          = 0.9;
    m.graphics.diffuseStrength           = 0.6;
    m.graphics.ambientStrength           = 0.2;
    m.graphics.specularExponent          = 20;
    m.graphics.specularColorReflectance  = 1;
	  m.optical = OpticalSurfaceProperties('gold foil');

  case 'aluminum' % metal
    m.graphics.faceColor                 = [0.9 0.9 0.9];
    m.graphics.edgeColor                 = [0.9 0.9 0.9];
    m.graphics.specularStrength          = 1;
    m.graphics.diffuseStrength           = 0.3;
    m.graphics.ambientStrength           = 0.2;
    m.graphics.specularExponent          = 25;
    m.graphics.specularColorReflectance  = 0.5;
	  m.optical = OpticalSurfaceProperties('aluminum');
	
  case 'steel' % metal
    m.graphics.faceColor                 = [0.5 0.5 0.5];
    m.graphics.edgeColor                 = [0.5 0.5 0.5];
    m.graphics.specularStrength          = 1;
    m.graphics.diffuseStrength           = 0.3;
    m.graphics.ambientStrength           = 0.2;
    m.graphics.specularExponent          = 25;
    m.graphics.specularColorReflectance  = 0.5;
	  m.optical = OpticalSurfaceProperties('steel');
	
  case 'aluminum truss'  % metal
    m.graphics.faceColor                 = [0 0 0];
    m.graphics.edgeColor                 = [0.9 0.9 0.9];
    m.graphics.specularStrength          = 1;
    m.graphics.diffuseStrength           = 0.3;
    m.graphics.ambientStrength           = 0.2;
    m.graphics.specularExponent          = 25;
    m.graphics.specularColorReflectance  = 0.5;
	  m.optical = OpticalSurfaceProperties('aluminum');
	
  case {'radiator','shunt'} % dull
    m.graphics.faceColor                 = [0.2 0.2 0.2];
    m.graphics.edgeColor                 = [0.2 0.2 0.2];
    m.graphics.specularStrength          = 0;
    m.graphics.diffuseStrength           = 0.8;
    m.graphics.ambientStrength           = 0.2;
    m.graphics.specularExponent          = 10;
    m.graphics.specularColorReflectance  = 1;
	  m.optical = OpticalSurfaceProperties('radiator');
	
  case 'white' % dull
    m.graphics.faceColor                 = [1 1 1];
    m.graphics.edgeColor                 = [1 1 1];
    m.graphics.specularStrength          = 0;
    m.graphics.diffuseStrength           = 0.8;
    m.graphics.ambientStrength           = 0.2;
    m.graphics.specularExponent          = 10;
    m.graphics.specularColorReflectance  = 1;
	  m.optical = OpticalSurfaceProperties('white');
	
  case 'black'  % dull
    m.graphics.faceColor                 = [0 0 0];
    m.graphics.edgeColor                 = [0 0 0];
    m.graphics.specularStrength          = 0;
    m.graphics.diffuseStrength           = 0.8;
    m.graphics.ambientStrength           = 0.2;
    m.graphics.specularExponent          = 10;
    m.graphics.specularColorReflectance  = 1;
  	m.optical = OpticalSurfaceProperties('black');
	
  case 'magenta'  % dull
    m.graphics.faceColor                 = [0.8 0.0 0.55];
    m.graphics.edgeColor                 = [0.8 0.0 0.55];
    m.graphics.specularStrength          = 1;
    m.graphics.diffuseStrength           = 0.7;
    m.graphics.ambientStrength           = 0.2;
    m.graphics.specularExponent          = 10;
    m.graphics.specularColorReflectance  = 0.1;
	  m.optical = OpticalSurfaceProperties('black');

  otherwise
    MessageQueue('add', 'CreateComponent',[m.faceColor,' surface properties are not available'],'error')
    m.graphics.faceColor                 = [0.7 0.7 0.7];
    m.graphics.edgeColor                 = [0 0 0];
    m.graphics.specularStrength          = 0.9;
    m.graphics.diffuseStrength           = 0.6;
    m.graphics.ambientStrength           = 0.2;
    m.graphics.specularExponent          = 10;
    m.graphics.specularColorReflectance  = 0.5;
	  m.optical                            = GenericProperties('optical');
end

%--------------------------------------------------------------------------
%   Display available colors
%--------------------------------------------------------------------------
function DisplayColors

c =  {'solar cell' 'mirror' 'gold foil' 'aluminum' 'steel' 'aluminum truss' 'radiator' ...
      'white' 'black' 'magenta'};

% See if the window is open
%--------------------------
figH = findobj( 'tag', 'colorpopup' );


if( isempty(figH) )
  h     = 200;
  hFig  = figure( 'position', [250 250 200 h], 'units','pixels',...
                  'NumberTitle', 'off', 'name', 'Color Popup', 'tag', 'colorpopup', 'resize', 'off' );
              
  hAxes = axes( 'Parent', hFig, 'box', 'off', 'units','pixels',...
                'color', [1 1 1],...
                'XGrid','off',...
                'YGrid','off',...
                'ZGrid','off',...
                'YTickLabel',[],...
                'XTickLabel',[],...
                'ZTickLabel',[]);
				
  n     = length(c);

  space = h/50;

  dY    = (h - 2*space)/n;
  hB    = dY - space;
  y     = h - dY;

  for k = 1:length(c)
        z.graphics.faceColor = c{k};
        m = SetColorAndSurfaceProps( z );
        v = [60 95 95 60;y y y+hB y+hB;0 0 0 0]';
        patch(  'parent', hAxes, 'Vertices', v, 'Faces', [1 2 3 4],...
                'FaceColor',                m.graphics.faceColor,...
                'edgeColor',                m.graphics.faceColor,...
                'ambientStrength',          m.graphics.ambientStrength,...
                'diffuseStrength',          m.graphics.diffuseStrength,...
                'specularStrength',         m.graphics.specularStrength,...
                'specularExponent',         m.graphics.specularExponent,...
                'specularColorReflectance', m.graphics.specularColorReflectance);
	if( mean(m.graphics.faceColor) < 0.4 )
      text(65,y+hB/2,5,c{k},'color',[1 1 1]);
	else
      text(65,y+hB/2,5,c{k},'color',[0 0 0]);
	end
    y = y - dY;
  end
end
					   
%--------------------------------------------------------------------------
%   Remove used cells
%--------------------------------------------------------------------------
function [v, f] = RemoveCells( v, f, varargin )

for k = 1:length(varargin)
  i = StringMatch( varargin{k}, f );
  v = DeleteCell( v, i );
  f = DeleteCell( f, i );
end


%--------------------------------------
% $Date: 2020-06-12 21:19:56 -0400 (Fri, 12 Jun 2020) $
% $Revision: 52720 $
