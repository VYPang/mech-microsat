function t = FSWClock( action, d )

%% This routine implements the flight software clock.
%--------------------------------------------------------------------------
%   Form:
%   t = FSWClock( action, d );
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   action        (1,:)     Action to be performed        
%   d             (1,1)     Data structure for inputs
%
%   -------
%   Outputs
%   -------
%   t             (1,1)     Data structure with outputs. Valid only
%                           with action 'update' and 'get telemetry'
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2001 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

persistent s

switch action
  case 'initialize'
    s = DefaultData;

  case 'update'
    s = d;
	
  case 'get jd'
    t = s.jD;

  case 'get met'
    t = s.mET;
   
  case 'get telemetry'
    t = [s.mET;s.jD];

  case 'get telemetry names'
    t = {'C:MET' 'C:JD'};

  case 'get telemetry units'
    t = {'sec' 'days'};
    
end

%--------------------------------------------------------------------------
%  Default data
%--------------------------------------------------------------------------
function s = DefaultData

s.mET = 0;
s.jD  = JD2000;

%--------------------------------------
% $Date: 2019-11-23 15:43:09 -0500 (Sat, 23 Nov 2019) $
% $Revision: 50377 $
