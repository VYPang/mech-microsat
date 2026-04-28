function TextS( x, y, s, k )

%% Prints labels on a graph using text with toolbox style settings.
%--------------------------------------------------------------------------
%   Form:
%   TextS( x, y, s, k)
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   x                 x location
%   y                 y location
%   s          (:)    Text
%   k                 Passed to text
%
%   -------
%   Outputs
%   -------
%   None
%
%--------------------------------------------------------------------------
%   See also PltStyle
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1996 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------


[style,font,fSI] = PltStyle;

if( nargin < 4 )
  text(x,y,s,'FontWeight',style,'FontName',font,'FontSize',12+fSI);
else
  text(x,y,s,k,'FontWeight',style,'FontName',font,'FontSize',12+fSI);
end


%--------------------------------------
% $Date: 2019-12-27 15:51:53 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50729 $
