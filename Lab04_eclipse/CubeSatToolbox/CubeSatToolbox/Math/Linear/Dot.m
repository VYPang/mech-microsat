function d = Dot ( w, y )

%% Dot product with support for arrays. 
%   The number of columns of w and y can be:
%   - Both > 1 and equal
%   - One can have one column and the other any number of columns
%
%   Since version 1.
%--------------------------------------------------------------------------
%   Form:
%   d = Dot ( w, y )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   w                 (:,:)  Vector
%   y                 (:,:)  Vector
%
%   -------
%   Outputs
%   -------
%   d                 (1,:)   Dot product of w and y
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%	Copyright (c) 1993-1997 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

if( nargin < 2 )
  y = w;
end

cW = size(w,2);
cY = size(y,2);

if( cW == cY )
  d = sum(w.*y); 
		 
elseif( cW == 1)
  d = w'*y; 
		 
elseif( cY == 1)
  d = y'*w;
   
else
  error('w and y cannot have different numbers of columns unless one has only one column')
end


%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 17:07:25 -0400 (Thu, 11 May 2017) $
% $Revision: 44577 $
