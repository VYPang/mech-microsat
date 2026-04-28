function SaveStructure( g, fileName )

%% Save a structure in a file. You will be able to read it in by typing
%   g = load('fileName');
%--------------------------------------------------------------------------
%   Form:
%   SaveStructure( g, fileName )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%
%   g        (:)   Structure
%   fileName (1,:) .mat file name
%
%   -------
%   Outputs
%   -------
%   None
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1999 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

% Create the file name
%---------------------
if( nargin < 2 )
  if( isfield( g(1), 'name' ) )
    fileName = g(1).name;
  else
    t        = clock;
    fileName = ['Structure' num2str([t(5:6) 100*rand])];
  end
end

%  Must be a .mat file
%---------------------
k = findstr( '.mat', fileName );
if( isempty(k) )
  fileName = [fileName '.mat'];
end

m = ['save  ''' fileName '''' ];
if IsVersionAfter(6.5)
  m = [m ' -v6'];
end

% Get the field names
%--------------------
sFNxx1 = fieldnames( g );

% Create a string with the field names
% and set an internal variable equal to each field
%-------------------------------------------------
for k = 1:length(sFNxx1)
  m = [m ' ' sFNxx1{k}];
  eval( [sFNxx1{k} ' = g.' sFNxx1{k} ';'] ); 
end

% Save
%-----
eval( m );

%--------------------------------------
% $Date: 2019-12-27 14:31:09 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50728 $
