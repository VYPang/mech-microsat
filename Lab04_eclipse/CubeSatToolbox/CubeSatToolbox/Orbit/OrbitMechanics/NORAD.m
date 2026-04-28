function [rV,x] = NORAD( dStart, dEnd, nPts, model, pType, file )

%% Propagates the NORAD two line elements, ex. SGP, SGP4, SGP8. 
% 
%   [] can be entered for any input. To input a time vector, pass it in for
%   dStart and pass an empty matrix ([]) for dEnd and nPts.
%   file can be a file name or a string input. The string must have the
%   same format as the file for example:
%
%   s = [sprintf('SGPTest \n'),...
%   sprintf('1 88888U          80275.98708465  .00073094  13844-3  66816-4 0     8\n'),...
%   sprintf('2 88888  72.8435 115.9689 0086731  52.6988  110.5714 16.05824518  105')];
%
%   See also LoadNORAD, ConvertNORAD, TNORAD, and PropagateTLE.
%
%   Since version 2.
%--------------------------------------------------------------------------
%   Forms:
%   rV = NORAD( dStart, dEnd, nPts, model, [], file )
%   rV = NORAD( tVec, [], [], model, [], file )
%   NORAD( tVec, [], [], model, pType, file ), creates desired plot type
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   dStart    (1,1) or (1,:)   Days from Epoch of start or time vector (sec)
%   dEnd          (1,1)        Days from Epoch of end
%   nPts          (1,1)        Number of points
%   model         (1,:)        Model type 'SGP', 'SGP4', 'SDP4', 'SGP8', 'SGD8'
%   pType         (1,:)        Either '2d' or '3d' plot, 3d is default
%   file          (1,:)        File name
%
%   -------
%   Outputs
%   -------
%   rV            (n)     Structure for position and velocity vectors
%                         rV.v    (3,:)
%                         rV.r    (3,:)
%                         rV.name (1,:)
%   x             (n)     Structure of NORAD element data
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%	 Copyright 1997, 2007, 2008 Princeton Satellite Systems, Inc. 
%  All rights reserved.
%--------------------------------------------------------------------------

% Less than all arguments
%------------------------
if( nargin < 1 )
  % Demo
  dStart = 0;
  dEnd = 1;
  nPts = 1000;
  model = [];
  file = 'sgp.txt';
  pType = '3d';
  if nargout == 0
    NORAD( dStart, dEnd, nPts, model, pType, file );
  else
    [rV,x] = NORAD( dStart, dEnd, nPts, model, pType, file );
  end
  return;
end

if( nargin < 2 )
	dEnd = [];
end

if( nargin < 3 )
	nPts = [];
end

if( nargin < 4 )
	model = [];
end

% Defaults
%---------
if( nargin < 5 )
	pType = '3d';
else
	pType = lower(pType);
end

if( isempty(nPts) )
  nPts = 100;
end

if isempty(model)
  model = 'sgp4';
end

daysToMin = 1440.0;
 secToMin = 1/60;
if (~isempty(dEnd))
  % User entered start and end days
  tVec = linspace(dStart,dEnd,nPts)*daysToMin/secToMin;
else
  % Assume time vector
  tVec = dStart;
end
  
% Open the file using the standard dialog box
%--------------------------------------------
if( nargin < 6 )
  currentPath = cd;

  [file,path] = uigetfile('*.*','NORAD Datafiles');
  if file == 0,
    return
  end

  eval(['cd ''',path,'''']);
end

% Convert the input data
%-----------------------
[x, n] = ConvertNORAD( file );

[r,v]  = PropagateTLE( tVec, x, model );

% Deal output to struct
%----------------------
rV = struct('r',r,'v',v,'name',{x(:).name});

% Currently OrbTrack only handles one orbit
%------------------------------------------
if( nargout == 0 )
	for k = 1:n
    % Have to assume a century
    if x(k).epochYear < 50
      year = 2000 + x(k).epochYear;
    else
      year = 1900 + x(k).epochYear;
    end
    jD0     = Date2JD(year) + x(k).epochDay - 1;
    jDStart = jD0 + dStart;
    jDEnd   = jD0 + dEnd;
  
    OrbTrack( rV(k).r, linspace(jDStart,jDEnd,nPts), pType );
    TitleS( rV(k).name );
	end
end

%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-09 11:41:04 -0400 (Tue, 09 May 2017) $
% $Revision: 44510 $
