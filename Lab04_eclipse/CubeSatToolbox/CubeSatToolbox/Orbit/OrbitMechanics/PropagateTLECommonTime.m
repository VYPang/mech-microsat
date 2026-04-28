function [rECI,vECI,jD0] = PropagateTLECommonTime( jD0, tVec, file, model )

%% Propagates a set of NORAD two line elements with a common time frame.
%   
%   For each each TLE set, Propagate TLE is called with the appropriate
%   "tVec" input so that the starting epoch of all trajectories is "jD0".
%
%   If "jD0" is empty, the latest Julian date of the given TLEs is used.
%
%   See also NORAD, LoadNORAD, ConvertNORAD, PropagateTLE
%
%--------------------------------------------------------------------------
%   Form:
%   [r,v,x] = PropagateTLECommonTime( jD, tVec, file, model )
%   [r,v,x] = PropagateTLECommonTime( jD, tVec, x, model )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   jD0           (1,1)   Epoch Julian date for all TLEs
%   tVec          (1,:)   Time vector (sec). Referenced to jD0.
%   file          (1,:)   File name OR converted data structure
%   model         (1,:)   Model type 'SGP', 'SGP4', 'SDP4', 'SGP8', 'SGD8'
%                           The default model is SGP4.
%
%   -------
%   Outputs
%   -------
%   r      (3,:) or {:}   Position vectors
%   v      (3,:) or {:}   Velocity vectors
%   x             (:)     Structure of NORAD element data
%
%--------------------------------------------------------------------------
%   References:	Hoots, F. R. and R. L. Roehrich, "Spacetrack Report No. 3:
%               Models for Propagation of NORAD Element Sets", Dec. 1980.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright 1997, 2007 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 8.
%--------------------------------------------------------------------------

% Default model: SGP4
%--------------------
if( nargin < 4 )
	model = 'SGP4';
end

% If file is empty, open the file using the standard dialog box
%--------------------------------------------------------------
if( isempty(file) )
  currentPath = cd;

  [file,path] = uigetfile('*.*','NORAD Datafiles');
  if( file == 0 )
    return
  end

  eval(['cd ''',path,'''']);
end

% Already loaded?
%----------------
if isstruct(file)
  x = file;
  n = length(x);
else
  % Convert the input data
  %-----------------------
  [x, n] = ConvertNORAD( file );
end


% If jD0 empty, compute jD0 as latest Julian date of provided TLEs
%-----------------------------------------------------------------
if( isempty(jD0) )
   jD0 = 0;
   for i=1:n
      if( x(i).julianDate > jD0 )
         jD0 = x(i).julianDate;
      end
   end
end

% Compute ECI position and velocity using PropagateTLE
%-----------------------------------------------------
rECI = cell(1,n);
vECI = rECI;

for k = 1:n
   deltaT = (jD0-x(k).julianDate)*86400;
   [rECI{k},vECI{k}] = PropagateTLE( tVec+deltaT, x(k), model );
end


%--------------------------------------
% $Date: 2019-01-28 09:18:59 -0500 (Mon, 28 Jan 2019) $
% $Revision: 47889 $
