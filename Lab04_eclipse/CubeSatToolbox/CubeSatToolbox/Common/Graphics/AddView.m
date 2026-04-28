function AddView( h )

%% Add view accelerators to a figure. 
% Snap to different frames as shown:
%
%   x-y   CTRL+J
%   y-x   CTRL+K
%   x-z   CTRL+L
%   y-z	  CTRL+M
%--------------------------------------------------------------------------
%   Form:
%   AddView( h )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   h                (:)  Handle to the figure (optional, default is gcf)
%
%   -------
%   Outputs
%   -------
%   none
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%	Copyright (c) 2005 Princeton Satellite Systems, Inc.
%	All rights reserved.
%--------------------------------------------------------------------------

if( nargin < 1 )
   h = gcf;
end

checks = 'set(gcbo,''checked'',''on''); set(get(gcbo,''userdata''),''checked'',''off'');';

cbxy = ['set(gca,''view'',[  0,  90]); ',checks]; 
cbyx = ['set(gca,''view'',[ 90, -90]); ',checks];
cbxz = ['set(gca,''view'',[  0,   0]); ',checks];
cbyz = ['set(gca,''view'',[ 90,   0]); ',checks];

viewMenu   = uimenu(h,'Label','&View');
if verLessThan('matlab','8.4.0')
  viewMenus    = zeros(1,4);
else
  viewMenus    = gobjects(1,4);
end
viewMenus(1) = uimenu(viewMenu, 'Label','x-y', 'Callback',cbxy, 'accelerator','j', 'checked','off' );
viewMenus(2) = uimenu(viewMenu, 'Label','y-x', 'Callback',cbyx, 'accelerator','k', 'checked','on' );
viewMenus(3) = uimenu(viewMenu, 'Label','x-z', 'Callback',cbxz, 'accelerator','l', 'checked','off' );
viewMenus(4) = uimenu(viewMenu, 'Label','y-z', 'Callback',cbyz, 'accelerator','m', 'checked','off' );

for i=1:4
   set(viewMenus(i),'userdata',viewMenus(setdiff(1:4,i)));
end

%--------------------------------------
% $Date: 2019-12-27 15:51:53 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50729 $

