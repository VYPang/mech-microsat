function [p,g] = DeviceProperties( type, m, properties, values, computeInertia )

%% Generates default properties for specific devices.
% This function can perform the following actions:
%
% * return a list of available device types
% * return a list of parameters used to define any specific device
% * return component data for the device when passed the needed parameters
%
% The third form should only be used from within CreateComponent.
%--------------------------------------------------------------------------
%   Form:
%   types = DeviceProperties
%   [p,g] = DeviceProperties( type )
%       m = DeviceProperties( type, m, properties, values, computeInertia )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   type           (1,:)   Type
%   m               (:)    Component struct
%   properties      {:}    Property names
%   values          {:}    Property values
%   mass            (:)    Mass structure
%
%   -------
%   Outputs
%   -------
%   types           {:}   List of all available device types
%   p               (.)   Properties data structure
%   g               (.)   Geometry fields data structure
%   m               (:)   Updated component struct
%                           .v   Vertices
%                           .f   Faces
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2001-2003, 2006 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   2018.1 Remove obsolete sun sensor
%--------------------------------------------------------------------------

% No inputs, return a list of device types
%-----------------------------------------
if nargin == 0
  types = ListAllTypes;
  p     = sort(types);
  if nargout == 0
    disp('Available Devices:')
    disp(p')
    clear p
  end
  return;
end

% Output geometry information (v,f)
%----------------------------------
geom  = 0;
if nargin > 1
  geom = 1;
end

% Locally assign property values
%-------------------------------
data = [];
if nargin > 2
  for k = 1:length(properties)
    data.(properties{k}) = values{k};
    %eval( [properties{k} '= values{k};'] );
  end
end

p = []; % device parameters
g = {}; % geometry parameters needed for computing vertices and faces

switch lower(type)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Communications
  case 'ground link antenna'
    g = {'x' 'y' 'z'};
    if geom
      m = BoxModel( data.x, data.y, data.z, m, computeInertia );
    end
    
  case 'isl'
    if( exist( 'ISL','file' ) )
	    p = ISL('get default datastructure');
    end
    g = {'x' 'y' 'z'};
    if geom
      m = BoxModel( data.x, data.y, data.z, m, computeInertia );
    end
    
  case 'omni'
    if( exist('Omni','file') )
	    p = Omni('get default datastructure');
    end
    g = {'x' 'y' 'z'};
    if geom
      m = BoxModel( data.x, data.y, data.z, m, computeInertia );
    end
	
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Plumbing
  case {'fuel tank', 'hydrazine tank'}
      p = struct( 'volume', 0, 'massPressurant',0,'rPress',0,'massFuel',0,...
          'densityFuel', 1000,'temperatureTank', 300, 'fuelType', 'liquid');
      % archived format:
      %p = struct( 'volumeTank', 0, 'massPressurant',0,'rPress',0,'massFuel',0, 'densityFuel', 1000,'temperatureTank', 300, 'fuelType', 'liquid','thrust', 0);
      g = {'radius' 'n'};
      if geom
        if( ~isfield(data,'n') )
          data.n = 10;
        end
        [m.v, m.f] = GeomPatch( struct('a',data.radius,'b',data.radius,'c',data.radius, 'n', data.n) );
      end
	  	
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Actuators
  case {'hydrazine thruster','rea','onoff thruster'}
	  p = struct('pressureNominal',2200000, 'unitVector',[1;0;0],'positionVector',[0;0;0],...
                 'uECoefficient',[2000, 2200],'thrustCoefficient',[1 0],...
	             'thrusterType', 'liquid', ...
	             'thermalGainHeater',1, 'pulsewidthToThermalFlux',0,...
                 'minimumPulsewidth', 0.02, 'valveHeaterPower', 0,...
                 'displayPlume',false);
    g = {'model' 'unitVector'};
    if geom
      % model returns mass, propulsion, and power structs in d
      [m.v, m.f, d] = REAModel( data.model, -data.unitVector );
	    m.mass       = d.mass;
	    m.propulsion = d.propulsion;
	    m.power      = d.power;
    end

  case 'reaction wheel'
    if( exist('RWA','file') )
		  p          = RWA('get default datastructure');
		  p.fStatic  = 0;
		  p.kStatic  = 0;
		  p.fCoulomb = 0;
		  p.kCoulomb = 0;
		  p.bViscous = 0;
		  p = rmfield( p, 'friction' );
		  p.unitVector = [0;0;0];
    end
    g = {'model' 'unitVector'};
    if geom
      % returns mass and power structs in d
      [m.v, m.f, d] = RWAModel( data.model, data.unitVector );
	    m.mass        = d.mass;
	    m.power       = d.power;
    end

  case 'wheel'
    % cylinder origin is at the base
    % h is along the z axis of the frustrum
    g = {'radius' 'h'};
    p.unitVector = [0;0;1];
    if geom
      m = CylinderModel( data.radius, data.radius, data.h, 12, m, computeInertia );
    end

  case {'single axis drive','single axis stepper drive'}
    if( exist('SingleAxisDrive','file') )
	    p = SingleAxisDrive('get default datastructure');
	    p.drivenBody = 1;
    end
    % g = {'model' 'unitVector' 'driven body'};
    g = {'unitVector'};
    if geom
      [m.v, m.f] = CameraModel('generic',data.unitVector);
      if computeInertia
        m.mass.inertia = Inertias( m.mass.mass, [0.076 0.156 0.190], 'box', 1 ); 
      end
    end
    
  case 'single axis linear drive'
    if( exist('SingleAxisLinearDrive','file') )
	    p = SingleAxisLinearDrive('get default datastructure');
	    p.drivenBody = 1;
    end
    % g = {'model' 'unitVector' 'driven body'};
    g = {'unitVector'};
    if geom
      [m.v, m.f]       = CameraModel('generic',data.unitVector);
      if computeInertia
        m.mass.inertia = Inertias( m.mass.mass, [0.076 0.156 0.190], 'box', 1 ); 
      end
    end
	
  case 'hall thruster'
	  p = struct('efficiency',0, 'unitVector',[1;0;0],'positionVector',[0;0;0],...
      'thrust',0,'exhaustVelocity',0,'displayPlume',false);
    g = {'s'};
    if geom
      % scale [Diameter, length]
      [m.v, m.f] = HallThrusterModel( data.s );
    end

  case 'magnetic torquer'
    if( exist('MagneticTorquer','file') )
	    p = MagneticTorquer('get default datastructure');
    end
    g = {'x' 'y' 'z'};
    if geom
      m = BoxModel( data.x, data.y, data.z, m, computeInertia );
    end
	
  case 'f16 gas turbine'
    p = struct( 'unitVector',[1;0;0],'positionVector',[0;0;0],'thrust',0,'exhaustVelocity',0);
    g = {'vertex' 'face'};
    if geom
      m.v = data.vertex;
	    m.f = data.face;
    end
	
  case 'rocket engine'
    p = struct( 'unitVector',[1;0;0],'thrustMax',28024,'thrustMin',4670.6,'scale',1/1024);
    g = {'vertex' 'face'};
    if geom
      m.v = data.vertex;
      m.f = data.face;
    end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Sensors
  case 'gps receiver'
    if( exist('GPSReceiver','file') )
	    p = GPSReceiver('get default datastructure');
    end
    g = {'x' 'y' 'z'};
    if geom
      m = BoxModel( data.x, data.y, data.z, m, computeInertia );
    end
  
  case 'imu'
	  p = struct('scale',1,'bias',0,'randomWalk',0,'angleRandomWalk',0,...
               'outputNoise1Sigma',0,'beta',0,'rateLimit',0,'scaleFactor',1,...
               'lSB',1e-7,'countLimit',16777215);
    g = {'rUpper', 'rLower', 'h', 'n'};
    if geom
      if ~isfield(data,'var')
        data.n = 12; 
      end
      m = CylinderModel( data.rUpper, data.rLower, data.h, data.n, m, computeInertia );
    end

  case 'magnetometer'
    if( exist('Magnetometer','file') )
  	  p = Magnetometer('get default datastructure');
    end
    g = {'x' 'y' 'z'};
    if geom
      m = BoxModel( data.x, data.y, data.z, m, computeInertia );
    end
      
  case 'radar'
    if( exist('SC/Sensors/Radar.m','file') )
	    p = Radar('get default datastructure');
    else
      p.boresight = [1;0;0];
      p.cos3dB    = 0;
      p.maxRange  = 0;
    end
    g = {'rUpper' 'rLower' 'h' 'n'};
    if geom
      if ~isfield(data,'n')
        data.n = 12; 
      end
      m = CylinderModel( data.rUpper, data.rLower, data.h, data.n, m, computeInertia );
    end
	
  case 'star camera'
    p.boresight   = [1;0;0];
    p.catalogName = 'FK5';
    p.qBToS       = QZero;
    g = {'model' 'boresight'};
    if geom
      [m.v, m.f, d] = StarCameraModel( data.model, data.boresight );
	    m.mass  = d.mass;
	    m.power = d.power;
    end
    
  case 'camera'
    g = {'unitVector'};
    if geom
      [m.v, m.f, d] = CameraModel('generic',data.unitVector);
      if( ~isfield( m, 'mass' ) )
	      m.mass         = d.mass;
	      m.power        = d.power;
      end
    end       
    
  case 'star tracker'
    if( exist('StarTracker','file') )
	    p = StarTracker('get default datastructure');
    end
    g = {'model' 'boresight'};
    if geom
      [m.v, m.f, d] = CameraModel('generic',data.boresight);
      if( ~isfield( m, 'mass' ) )
	      m.mass         = d.mass;
	      m.power        = d.power;
      end
    end       
	
  case 'relative position sensor'
    if( exist('RelativePositionSensor','file') )
	    p = RelativePositionSensor('get default datastructure');
    end
    g = {'x' 'y' 'z'};
    if geom
      m = BoxModel( data.x, data.y, data.z, m, computeInertia );
    end
    
  case 'earth sensor'
    if( exist('EarthSensorScanning','file') )
	    p = EarthSensorScanning('get default datastructure');
    end
    g = {'model' 'boresight' 'xUnitVector'};
    if geom
      [m.v, m.f] = CameraModel('generic', [0;0;1] );
    end
    
  case 'temperature sensor'
    p.maxTemperature  = 0;
    p.component       = [];
    p.noise1sigma     = 0;
    p.lsb             = 0;
    g = {'x' 'y' 'z'};
    if geom
      m = BoxModel( data.x, data.y, data.z, m, computeInertia );
    end
	
  case 'current sensor'
    p.maxCurrent  = 0;
    p.component   = [];
    p.noise1sigma = 0;
    p.lsb         = 0;
    g = {'x' 'y' 'z'};
    if geom
      m = BoxModel( data.x, data.y, data.z, m, computeInertia );
    end
    
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  case 'pcu'
	  p = [];
    g = {'x' 'y' 'z'};
    if geom
      m = BoxModel( data.x, data.y, data.z, m, computeInertia );
    end
	
  case 'heater'
	  p = [];
    g = {'x' 'y' 'z'};
    if geom
      m = BoxModel( data.x, data.y, data.z, m, computeInertia );
    end
	
  case 'battery'
    g = {'x' 'y' 'z','batteryCharge','maximumBatteryCharge',...
       'maximumBatteryChargeRate'};
    if geom
      m = BoxModel( data.x, data.y, data.z, m, computeInertia );
    end
    
  case 'nuclear reactor'
	  p = struct('scale',1);
    g = {'powerThermal' 'conversionEfficiency' 'unitVector'};
    if geom
      % model returns mass and power structs in d
      [m.v, m.f, d] = NuclearReactorModel( data.powerThermal, data.conversionEfficiency, data.unitVector );
 	    m.mass        = d.mass;
	    m.power       = d.power;
    end
    
  case 'radiator'
	  p = [];
    g = {'x' 'y' 'z'};
    if geom
      m = BoxModel( data.x, data.y, data.z, m, computeInertia );
    end
	
  case 'shunt'
	  p = [];
    g = {'x' 'y' 'z'};
    if geom
      m = BoxModel( data.x, data.y, data.z, m, computeInertia );
    end
	
  case 'gun'
    if( exist('Gun','file') )
	    p = Gun('get default datastructure');
    end
    if geom
      [m.v, m.f] = Frustrum( 0.05, 0.05, 0.1, 6, 0, 0 );
    end
	
  case {'solar array', 'solar array front'}
    p = [];
    g = {'z' 'x' 'nZ' 'nX' 'theta' 'dirZ'};
    if geom
      mFront = ArrayPatch( data );
      if computeInertia
        m.mass.inertia = Inertias( m.mass.mass, [data.x data.z], 'plate', 1 ); 
      end
	    m.v = mFront.v;
	    m.f = mFront.f;
    end
	
  case 'solar array back'
	  p = [];
    g = {'z' 'x' 'nZ' 'nX' 'theta' 'dirZ'};
    if geom
      [~, mBack] = ArrayPatch( data );
      if computeInertia
        m.mass.inertia = Inertias( m.mass.mass, [data.x data.z], 'plate', 1 ); 
      end
	    m.v = mBack.v;
	    m.f = mBack.f;
    end
      
  case 'solar panel'
    p.unitSunVector = {' '};
    p.solarFlux = {' '};
    g = {'x' 'z'};
    if geom
      mFront = ArrayPatch( data );
      if computeInertia
        m.mass.inertia = Inertias( m.mass.mass, [data.x data.z], 'plate', 1 ); 
      end
	    m.v = mFront.v;
	    m.f = mFront.f;
    end
	
  case 'power relay'
    p.component = 0;
    g = {'x' 'y' 'z'};
    if geom
      m = BoxModel( data.x, data.y, data.z, m, computeInertia );
    end
   
  case 'sail'
    p.nonLambertian = 2/3*[1 1];
    g = {'vertex' 'face'};
    if geom
      m.v = data.vertex;
	    m.f = data.face;
    end
    
  case {'state sensor', 'position sensor', 'lem', 'magnet', 'angle of attack sensor', 'rate gyro'}
    g = {'x' 'y' 'z'};
    if geom
      m = BoxModel( data.x, data.y, data.z, m, computeInertia );
    end
    
  otherwise
	  p = [];
    if geom
      MessageQueue('add', 'DeviceProperties', sprintf('%s is not an available type',type));
    end
end

% Rename output if needed
%------------------------
if geom
  p = m;
  clear m  g;
end

%-------------------------------------------------------
% List all types
%-------------------------------------------------------
function types = ListAllTypes

f = [mfilename,'.m'];

[fid,msg] = fopen(f,'rt');

if( fid == -1 )
   errordlg(sprintf('Attempt to open "%s" to read list of cases failed:\n%s',f,msg));
   return;
end

types = {};
kT    = 0;

while 1
   
   t = fgetl(fid);
   
   % if end of file reached...
   if( ~ischar(t) ), break; end
   
   % if end of the list of cases reached...
   if( contains(t,'otherwise') )
     break; 
   end
   
   % look for "case"
   k = strfind(t,'case');
   
   % if "case" found
   if( ~isempty(k) )
      
      % look for "%"
      p = strfind(t,'%');
      
      showLine = 1;
      
      % if "%" found
      if( ~isempty(p) )
         
         % if "%" comes before "case"
         if( p(1) < k(1) )           
            showLine = 0;          
         end
         
      end
      
      if( showLine )
        tRem = t(k+6:end-1);
        
        if( contains( tRem, ',' ) )
          % multiple types in one case
          r  = strfind(tRem,'''');
          for j = 1:2:length(r)
            types{kT+1} = tRem(r(j)+1:r(j+1)-1); %#ok<*AGROW>
            kT = kT+1;
          end
        else
        
          types{kT+1} = tRem;
          kT = kT+1;
        
        end
      end
      
   end
   
end

fclose(fid);

%--------------------------------------------------------------------------
%  Cylinder model using Frustrum for geometry and computing inertias
%--------------------------------------------------------------------------
function m = CylinderModel( rUpper, rLower, h, n, m, computeInertia )
    
[m.v, m.f] = Frustrum( rUpper, rLower, h, n, 0, 0 );
if( computeInertia ) 
  m.mass.inertia = Inertias( m.mass.mass, [0.5*(rUpper + rLower) h], 'cylinder', 1 ); 
end
m.mass.cM = [0;0;h/2];

%--------------------------------------------------------------------------
%  Box model using Box for geometry and computing inertias
%--------------------------------------------------------------------------
function m = BoxModel( x, y, z, m, computeInertia )
    
[m.v, m.f]  = Box( x, y, z );
if computeInertia
  m.mass.inertia = Inertias( m.mass.mass, [x y z], 'box', 1 ); 
end


%--------------------------------------
% $Date: 2019-12-01 22:31:03 -0500 (Sun, 01 Dec 2019) $
% $Revision: 50474 $
