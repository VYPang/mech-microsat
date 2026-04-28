function g = LoadOBJModel( file, path, kScale )

%% Load a Wavefront OBJ file. The file can have an associated .mtl file.
% If you call the function with no outputs it will draw the model. If you
% call the function with no inputs you can select a file using the dialog
% box.
%--------------------------------------------------------------------------
%   Form:
%   g = LoadOBJModel( file, path, kScale )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%
%   file        (1,:) Filename
%   path        (1,:) Path to the file
%   kScale      (1,1) Optional scale factor of the model
%
%   -------
%   Outputs
%   -------
%   g           (.)   Data structure
%                     .name       (1,:)  Model name
%                     .component  (:)    Component structure
%                     .radius     (1,1)
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1998-2000, 2009, 2020 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 8.
%   2019.1 Fixed bug with empty path and mtl
%   Fixed a bug when colors or specular exponents were empty
%   2020.1 Fixed bugs in loading obj data
%--------------------------------------------------------------------------

% Input processing
if( nargin < 1 )
  file = '';
end

if( nargin < 2 )
  path = '';
end

if( nargin < 3 )
  kScale = [];
end

if( isempty(path) && ~isempty(file) )
  path = fileparts(which(file));
end

if( ~contains(file,'.') && ~isempty(file) )
  file = [file '.obj'];
end

% Open the file
%--------------
if( isempty(file) )
	c = cd;
	if( ~isempty(path) )
    cd( path );
  end
	[file, path] = uigetfile( '*.obj', 'Open 3D Data file');
	if( file ~= 0 )
    cd( path );
    fid    = fopen( file, 'rt' );
    g.name = file;
  else
    fid = -1;
  end
	cd( c );
else
	if( ~isempty(path) )
     cd( path );
  end
	fid = fopen( file, 'rt' );
	g.name = file;  
end
 
if( fid < 0 )
  if(ischar(file) )
    fprintf('%s: %s could not be found.\n',mfilename,file)
  end
  g = [];
  return;
end

g = GetDataOBJ(  fid, g );

fclose( fid );

if( isempty( g ) )
  return;
end

% Scale the drawing
%------------------
if( isempty( kScale ) )
  kScale = 1;
end

g.radius = 0;
if( isfield( g, 'component' ) )
  for k = 1:length(g.component)
    g.component(k).v = g.component(k).v*kScale;
    g.radius         = max([Mag(g.component(k).v') g.radius]);
  end

  if( nargout == 0 )
    DrawPicture( g );
  end
end

%---------------------------------------------------------------------------
%   Draw the picture
%---------------------------------------------------------------------------
function DrawPicture( g )

NewFig( g.name )
axes('DataAspectRatio',[1 1 1],'PlotBoxAspectRatio',[1 1 1] );

for k = 1:length(g.component)
  DrawMesh( g.component(k) );
end

XLabelS('X')
YLabelS('Y')
ZLabelS('Z')

grid
view(3)
rotate3d on
hold off

%---------------------------------------------------------------------------
%  Get the polygon data
%---------------------------------------------------------------------------
function g = GetDataOBJ( fid, g )


% Initialize counters
%--------------------
kV      = 0;
kF      = 0;
nG      = 0;
hasG    = false;

% Read the file
%--------------
while( feof(fid) == 0)
  line = fgetl(fid);
  
  jX = strfind(line,'\');
  if( ~isempty(jX) )
    line(jX) = '';
    hasContinuation = 1;
  else
    hasContinuation = 0;
  end
  
  t = split(line);
  
  while( hasContinuation )
    line = fgetl(fid);
    jX = strfind(line,'\');
    if( ~isempty(jX))
      line(jX) = '';
      hasContinuation = 1;
    else
      hasContinuation = 0;
    end
    t = split(line);
  end
  
  if( ~isempty(t{1}) )
    
    % The first token determines the action
    %--------------------------------------
    switch t{1}
      case '#'
        % A Comment
        %----------
        
      case 'v'
        kV      = kV + 1;
        v(kV,:) = [str2double(t{2}) str2double(t{3}) str2double(t{4}) ];
        
      case 'vn'
        % Normals
        %--------
        
      case 'vt'
        % Texture map coordinates
        %------------------------
        
      case 'f'
        if( ~hasG )
          kG        = 1;
          group{1}  = 'Default';
          nG        = 1;
        end
        lT        = length(t) - 1;
        vT        = zeros(1,lT);
        for k = 1:lT
          if( ~isempty(t{k+1}) )
            gVO = GetVertexOBJ(t{k+1});
            
            if( ~isempty(gVO) )
              vT(k) = gVO;
            end
          end
        end
        
        % Assign the faces to all groups
        %-------------------------------
        for k = 1:length(kG)
          j     = kG(k);
          kF(j) = kF(j) + 1;
          component(j).f(kF(j),1:lT) = vT;
        end

        
      case 'g'
        hasG = true;
        n = length(t) - 1;
        if( ~isempty( t{2} ) )
          kG = [];
          for j = 1:n
            isANewGroup = 1;
            if( nG > 0 )
              for i = 1:nG
                if( strcmp( group{i}, t{j+1} ) )
                  isANewGroup = 0;
                  break;
                end
              end
              if( isANewGroup )
                nG        = nG + 1;
                kF(nG)    = 0;
                group{nG} = t{j+1};
                i         = nG;
              end
              kG = [kG i];
            else
              nG       = 1;
              kG       = 1;
              group{1} = t{2};
            end
          end
        end
        
      case 'usemtl'
      case 'mtllib'
      case 's'
      case 'o'
        
        % Unknown command
        %----------------
      otherwise
        disp(line)
        fprintf(1,'%s: Line ''%s'' is not recognized\n',mfilename,t{1});
    end
  end
end

% Sort into groups
%-----------------
kG = 0;
for k = 1:nG
  [n,m] = size( component(k).f );
  fC    = sort(reshape( component(k).f, n*m, 1 ));
  
  % Delete duplicates
  %------------------
  fC(fC == 0) = [];
  kDelete = [];
  for j = 2:length(fC)
    if( fC(j) == fC(j-1) )
      kDelete = [kDelete j];
    end
  end
  
  fC(kDelete) = [];
  if( ~isempty(fC) )
    kG                  = kG + 1;
    g.component(kG)     = CreateComponent('make','empty');
    g.component(kG).nV  = [];
    g.component(kG).f   = component(kG).f;
    g.component(kG).v   = v(fC,:);
    [rF,cF]             = size( g.component(kG).f );
    
    for i = 1:rF
      for j = 1:cF
        if( g.component(kG).f(i,j) == 0 )
          break;
        else
          p = find( fC == g.component(kG).f(i,j) ); % Reindexing
          g.component(kG).f(i,j) = p;
        end
      end
      nM = find(g.component(kG).f(i,:) == 0);
      if( isempty(nM) )
        nM = length( g.component(kG).f(i,:) );
      else
        nM = min(nM) - 1;
      end
      g.component(kG).nV(i) = nM; % The number of vertices per face
    end
    
    g.component(kG).name                                = group{k};
    g.component(kG).graphics.faceColor                  = [0.6 0.6 0.6];
    g.component(kG).graphics.edgeColor                  = [0.6 0.6 0.6];
    g.component(kG).graphics.diffuseStrength            = 0.3;
    g.component(kG).graphics.specularStrength           = 0.3;
    g.component(kG).graphics.ambientStrength            = 1;
    g.component(kG).graphics.specularExponent           = 10;
    g.component(kG).graphics.specularColorReflectance   = 1;
  end
end

%--------------------------------------------------------------------------
%  Get the vertex from the face vertex list
%--------------------------------------------------------------------------
function v = GetVertexOBJ( t )

k = strfind(char(t),'/');

if( isempty(k) )
  v = str2num(t); %#ok<ST2NM>
else
  k = k(1);
  v = str2num(t(1:(k-1))); %#ok<ST2NM>
end

%---------------------------------------------------------------------------
%  Draw a mesh
%---------------------------------------------------------------------------
function h = DrawMesh( m )

kMax = max(m.nV);
kMin = min(m.nV);
i    = 1;
for k = kMin:kMax
  j = find( m.nV == k );
  if( ~isempty(j) )
    h(i) = patch( 'Vertices', m.v, 'Faces',   m.f(j,1:k),...
      'FaceColor',                m.graphics.faceColor,...
      'EdgeColor',                [0 0 0],...
      'ambientStrength',          m.graphics.ambientStrength,...
      'SpecularExponent',         m.graphics.specularExponent,...
      'SpecularColorReflectance', m.graphics.specularColorReflectance,...
      'EdgeLighting', 'phong',...
      'FaceLighting', 'phong');
    i = i + 1;
  end
end


%---------------------------------------------------------------------------
%  Load a material library
%---------------------------------------------------------------------------

function mtl = LoadMTLLIB( file, path )

if( ~isempty(path))
  cd(path)
end
f = fopen( file, 'rt' );
j = 0;
while( feof(f) == 0)
	line = fgetl(f);
    t    = StringToTokens( line );
    if( isempty(t) )
        t{1} = 'blankline';
    end
    switch t{1}
        case 'newmtl'
            j = j + 1;
            mtl(j).name = t{2};
            
        case 'Kd'
            mtl(j).Kd = [str2double(t{2}) str2double(t{3}) str2double(t{4}) ];

        case 'Ns'
            mtl(j).Ns = str2double(t{2});

        case 'illum'
            mtl(j).illum = str2double(t{2});

        case 'Ks'
            mtl(j).Ks = [str2double(t{2}) str2double(t{3}) str2double(t{4}) ];

        case 'Ka'
            mtl(j).Ka = [str2double(t{2}) str2double(t{3}) str2double(t{4}) ];

        case 'd'
            mtl(j).d = str2double(t{2});

    end
        
end
fclose(f);


%---------------------------------------------------------------------------
%  Select a material library
%---------------------------------------------------------------------------
function material = GetMaterial( name, mtllib )

for k = 1:length(mtllib)
    if( strcmp(name, mtllib(k).name) )
        material = mtllib(k);
        return;
    end
end

%--------------------------------------
% $Date: 2020-06-19 15:04:48 -0400 (Fri, 19 Jun 2020) $
% $Revision: 52850 $
