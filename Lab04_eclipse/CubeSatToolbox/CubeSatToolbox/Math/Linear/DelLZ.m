function v = DelLZ( v )

%% Deletes leading zeros from a vector.
%
%   Since version 1.
%--------------------------------------------------------------------------
%   Form:
%   v = DelLZ( v )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   v 			               Vector
%
%   -------
%   Outputs
%   -------
%   v 			               Vector
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------

rv = size(v,1);

if ( rv > 1 ),
  sv  = sum(v);
else
  sv  = v; 
end

i = find(abs(sv)>eps*norm(sv), 1 );  

if (i > 1),
  v(:,1:i-1)=[];
end

% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 17:07:25 -0400 (Thu, 11 May 2017) $
% $Revision: 44577 $
