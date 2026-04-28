function jDMid = JDToMidnight( jD )

%% Converts a Julian date to the nearest midnight.
%
%--------------------------------------------------------------------------
%   Form:
%    jDMid = JDToMidnight( jD )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   jD           (:)  Julian date
%
%   -------
%   Outputs
%   -------
%   jDMid        (:)  Julian midnights
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2012 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 10.
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
    JDToMidnight( JD2000 + 0.8 )
    JDToMidnight( JD2000 + 0.2 )
    return
end
    

jDFloor = floor(jD);

dJD = jD - jDFloor;

if( dJD >= 0.5 )
    jDMid = jDFloor + 0.5;
else
    jDMid = jDFloor - 0.5;
end

%--------------------------------------
% $Date: 2019-12-27 11:09:25 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50719 $
