function gravityModel = LoadSGM150( fileName )

%% Load the SGM150 Lunar gravity model. 
% The model is normalized.
%--------------------------------------------------------------------------
%   Form:
%   gravityModel = LoadSGM150( fileName )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   fileName        (1,:) Filename
%
%   -------
%   Outputs
%   -------
%   gravityModel    (1,1) Data structure
%                         .name (1,:) Model name
%                         .mu   (1,1) Gravitational constant (km^3/sec^2)
%                         .a    (1,1) Model earth radius (km)
%                         .c    (n,n) Cosine coefficients
%                         .s    (n,n) Sine coefficients
%                         .isNormalized  (1,1)  True
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2015 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since 2016.1
%   2017.1 Update field name for normalization
%   2019.1 Added default filename
%--------------------------------------------------------------------------

if( nargin < 1 )
  fileName = 'SGM150.geo';
end

[fId, msg] = fopen( fileName, 'rt' );
if( fId == -1 )
	error(msg);
end
		
% The header
fgetl(fId);
l                   = fgetl(fId);

gravityModel.name   = 'SGM150';
gravityModel.string	= '';
gravityModel.mu   	= str2double(l(24:45))/1e9;
gravityModel.a      = str2double(l(47:59))/1e3;

gravityModel.c      = zeros(150,150);
gravityModel.s      = zeros(150,150);

while( ~feof(fId) )
  l  = fgetl(fId);
  t  = l(1:7);
  i  = str2double(l(15:17));
  j  = str2double(l(18:20));
  c1 = str2double(l(25:45));
  
	switch t
    case 'GCOEFC1'
      if( j == 0 )
        gravityModel.j(i)   = c1;%*sqrt(2*i+1);
      else
        gravityModel.c(i,j) = c1;
      end
      
    case 'GCOEFS1'
      if( j > 0 )
        gravityModel.s(i,j) = c1;
      end
      
	end
end

fclose(fId);

gravityModel.isNormalized = 1;
gravityModel.name = 'SGM150';


%--------------------------------------
% $Date: 2020-05-12 16:22:33 -0400 (Tue, 12 May 2020) $
% $Revision: 52212 $
