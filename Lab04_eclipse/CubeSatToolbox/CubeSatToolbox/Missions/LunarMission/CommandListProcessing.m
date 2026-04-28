function kCurrent = CommandListProcessing( jD0, cList, kCurrent, jD )

%% Processes command lists.
% The command list cell array format is {time command data}
% where data is a data structure for that command. The command list
% rows should be in order of Julian date. You can also use +sec instead of
% jD in which case the time is +sec after the previous command.  For 
% example, +6 indicates 6 seconds after the previous command.  If the 
% first command is +sec then it is +sec from the time passed on
% initialization.  
%
% Type CommandListProcessing for a demo.
%--------------------------------------------------------------------------
%	Form:
%	kCurrent = CommandListProcessing( jD0, cList, kCurrent, jD )
%--------------------------------------------------------------------------
%
% ------
%	Inputs
%	------
%   jD0       (1,1)	Base Julian date before any commands
%   cList     {:,3} Command list {time tag, string description, data structure}
%   kCurrent  (1,1) Current command
%   jD        (1,1) Current Julian date
%
%	-------
%	Outputs
%	-------
%   kCurrent  (1,1) Current command
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% Copyright (c) 2016 Princeton Satellite Systems, Inc. 
% All rights reserved.
%--------------------------------------------------------------------------
% Since 2016.1
%--------------------------------------------------------------------------

% This is for an lunar orbit insertion

if( nargin < 1 )
  jD0   = Date2JD;
  cList	= { jD0,            'align with a quaternion';...
           	jD0 + 12/86400,	'lunar orbit insertion prepare';...
           	+2,             'align for lunar insertion';...
            +60             'start main engine'};
  disp('Command list');
  for k = 1:size(cList,1)
    fprintf(1,'jD %14.5f %s\n',cList{k,1},cList{k,2}); 
  end
  kCurrent = 0;
  
  disp('Command processing');
  for t = 0:2:100
    kCurrent = CommandListProcessing(  jD0, cList, kCurrent, jD0 + t/86400);
  end
  
  fprintf(1,'\njD End = %12.5f\n',jD0+t/86400);
 
  clear kCurrent
  
  return
end

% Determine if the current command is ready to submit
k   = kCurrent;
if( k < size(cList,1) )
  jDK = GetJD( cList, k+1, jD0 );
  if( jD >= jDK )
   kCurrent = k + 1;
   fprintf(1,'jD %14.5f %s\n',jD,cList{kCurrent,2});
  end
end

%--------------------------------------------------------------------------
%	 Process the times
%--------------------------------------------------------------------------
function jD = GetJD( cList, kNext, jD0 )

secToDay = 86400;

jDMin = Date2JD([1980 1 1 0 0 0]);

if( cList{kNext,1} > jDMin )
  jD = cList{kNext,1};
elseif ( kNext > 1 )
  jD = GetJD( cList, kNext-1 ) + cList{kNext,1}/secToDay;
else
  jD = jD0 + cList{kNext,1}/secToDay;
end


%--------------------------------------
% $Date: 2017-05-09 13:33:53 -0400 (Tue, 09 May 2017) $
% $Revision: 44517 $
