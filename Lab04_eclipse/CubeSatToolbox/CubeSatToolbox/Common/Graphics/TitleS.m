function TitleS( x, font )

%% Creates a title using the toolbox style settings.
% x can be entered as 'text@fontName' to get a different font.
%--------------------------------------------------------------------------
%   Form:
%   TitleS( x, font )
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
%   Copyright (c) 1996-2000, 2016 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%   2016-02-23: switch from findstr to strfind as per MATLAB recommendation
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

title(x,'FontWeight',style,'FontName',font,'fontsize',12+fSI);

%--------------------------------------
% $Date: 2019-12-27 15:51:53 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50729 $
