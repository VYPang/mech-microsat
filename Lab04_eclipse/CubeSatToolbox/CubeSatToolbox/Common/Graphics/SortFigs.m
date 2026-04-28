function SortFigs( h, xo )

%% Sort figure windows by cascading them.
%--------------------------------------------------------------------------
%   Form:
%   SortFigs( h, xo )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   h            (1,:)   Array of figure handles. Optional. If not
%                        provided, all current figure handles will be used.
%   xo            (1)    Horizontal offset for first figure. Optional,
%                        default is 0.
%
%   -------
%   Outputs
%   -------
%   h            (1,:)   Array of figure handles.
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2005 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 7
%--------------------------------------------------------------------------

if( nargin<2 )
   xo = 0;
end

if( ~nargin || isempty(h) )
   h = findobj('type','figure');
end
if( isempty(h) )
   return;
end

h = h(ishandle(h));
pos = get(h,'position');
if( ~iscell(pos) )
   pos = {pos};
end

ps = get(0,'screensize');

for i=1:length(h)
   set(h(i),'position',[xo+(i-1)*15,ps(4)-pos{i}(3)-15*(i-1),pos{i}(3:4)]);
   figure(h(i));
end


%--------------------------------------
% $Date: 2017-05-01 16:57:45 -0400 (Mon, 01 May 2017) $
% $Revision: 44443 $
