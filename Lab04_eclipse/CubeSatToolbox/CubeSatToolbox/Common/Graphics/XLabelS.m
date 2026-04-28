function XLabelS( x, font )

%% Creates an xlabel using the toolbox style settings
% x can be entered as 'text@fontName' to get a different font.
%--------------------------------------------------------------------------
%   Form:
%   XLabelS( x, font )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   x          (:)    Text
%   font       (1,:)  Font name
%
%   -------
%   Outputs
%   -------
%   None
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1995-2000 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

[style,fontX,fSI] = PltStyle;

if( nargin < 2 )
  font = fontX;
end

j = strfind(x,'@');
if( ~isempty(j) )
  font = DeBlankLT(x((j+1):end));
  x    = x(1:(j-1));
end

xlabel(x,'FontWeight',style,'FontName',font,'fontsize',11+fSI);


%--------------------------------------
% $Date: 2019-12-27 15:51:53 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50729 $
