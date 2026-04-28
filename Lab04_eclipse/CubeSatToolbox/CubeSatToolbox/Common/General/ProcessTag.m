function [k, tag] = ProcessTag( action, tag, k, name )

%% Code used to process tags for sensors and actuators.
%--------------------------------------------------------------------------
%   Form:
%   [k, tag] = ProcessTag( action, tag, k, name )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------  
%   action	(1,:) Action
%   tag    	{:}   Tag list
%   k     	{:}   Index or tag
%   name    (1,:) Name of calling function
%
%   -------
%   Outputs
%   -------
%   k	       {:}  Index
%   tag    	{:}  Tag list
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1999 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------

% Analyze the index
%------------------
m = length(tag);

switch action
  case 'initialize'
    if( isempty(k) )
      k      = m + 1;
      tag{k} = [name ' ' num2str(k)];
    elseif( ischar(k) )
      if( ~isempty(tag) )
        j = StringMatch( k, tag, 'exact' );
        if( isempty(j) )
          tag = {tag{:} k};
          k   = length(tag);
        else
          msgbox([k ' is already in use.'], name );
          k   = [];
        end
      else
        tag = {k};
        k   = 1;
      end
    end

  otherwise

    if( isempty(k) )
      k = 1;
    elseif( ischar(k) )
      k = StringMatch( k, tag, 'exact' );
    end

end

%--------------------------------------
% $Date: 2019-12-27 14:31:09 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50728 $
