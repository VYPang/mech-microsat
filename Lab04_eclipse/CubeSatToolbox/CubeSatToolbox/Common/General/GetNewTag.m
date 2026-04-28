function tag = GetNewTag( name )

%% Get a new tag to uniquely identify a figure. 
% Uses clock and rand to generate a unique string.
%--------------------------------------------------------------------------
%   Form:
%   tag = GetNewTag( name )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   name        (1,:)  Name of the figure
%
%   -------
%   Outputs
%   -------
%   tag         (1,:)  Tag
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2000 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

t   = clock;
tag = [name num2str([t(5:6) 100*rand])];


%--------------------------------------
% $Date: 2019-12-27 14:31:09 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50728 $
