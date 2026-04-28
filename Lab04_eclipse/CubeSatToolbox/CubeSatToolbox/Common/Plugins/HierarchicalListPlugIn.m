function x = HierarchicalListPlugIn( action, modifier, hFig, position, callback, params )

%% Create and manages a hierarchical list. Each element of the list is
%
%   h(k).name        = 'mike';
%   h(k).parent      = '';
%   h(k).child       = {'pete'};
%   h(k).data        = ...;         Data can be anything.
%
%   Initialize
%   ----------
%   tag = HierarchicalListPlugIn( 'initialize', h, figureHandle, position, callback )
%
%   API
%   ---
%   HierarchicalListPlugIn( 'add',    tag, h ) % Parent can be empty
%   HierarchicalListPlugIn( 'delete', tag )
%   HierarchicalListPlugIn( 'show',   tag )
%   HierarchicalListPlugIn( 'hide',   tag )
%   HierarchicalListPlugIn( 'set',    tag, d )
%   
%   d   = HierarchicalListPlugIn( 'get', tag ) % Gets the entire list
%
%   Get the name of the selected element
%   s   = HierarchicalListPlugIn( 'get selection', tag )
%   s   = HierarchicalListPlugIn( 'get data for selection', tag )
%   s   = HierarchicalListPlugIn( 'get list', tag )
%
%--------------------------------------------------------------------------
%   Form:
%   x = HierarchicalListPlugIn( action, modifier, hFig, position, callback, params )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   action      (1,:)  Action 'initialize', 'update'
%   modifier    (1,:)  Modifier to the action
%   hFig        (1,1)  Handle to the figure
%   position    (1,4)  [left bottom width height]
%   callback    (1,:)  Callback string when something has changed in this gui
%   params      {:}    Parameter pairs for the list uicontrol
%
%   -------
%   Outputs
%   -------
%   x           (1,1)  Depends on the action.
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2000-2001 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

if( nargin < 1 )
  action = 'initialize';
end

switch action

  case 'initialize'
    if( nargin < 2 ) modifier = []; end
    if( nargin < 3 ) hFig     = []; end
    if( nargin < 4 ) position = []; end
    if( nargin < 5 ) callback = ''; end
    if( nargin < 6 ) params   = {}; end
    x = Initialize( hFig, position, modifier, callback, params );

  case 'hide'
    Hide( modifier );

  case 'show'
    Show( modifier );

  case {'get', 'get data'}
    x = GetData( modifier );

  case 'get data for selection'
    x = GetDataForSelection( modifier );

  case 'get selection'
    x = GetSelection( modifier );

  case 'get full name for selection'
    x = GetFullName( modifier );

  case 'has children?'
    x = HasChildren( modifier );

  case 'get list'
    x = GetList( modifier );

  case 'select'
    Select( modifier );
	
  case 'select external'
    x = SelectExternal( modifier, hFig );

  case {'set' 'set data'}
    SetData( modifier, hFig );

  case 'add'
	AddToList( modifier, hFig );

  case 'delete'
	DeleteFromList( modifier );

end

%--------------------------------------------------------------------------
%   Initialize
%--------------------------------------------------------------------------
function tag = Initialize( hFig, position, d, callback, params )

% The Plug In name
%-----------------
name = 'Hierarchical List';

if( isempty(d) )
  d(1).name        = 'mike';
  d(1).parent      = 0;
  d(1).child       = [2 5];
  d(1).data        = {};

  d(2).name        = 'pete';
  d(2).parent      = 1;
  d(2).child       = [4];
  d(2).data        = {};

  d(3).name        = 'frank';
  d(3).parent      = 0;
  d(3).child       = [];
  d(3).data        = [];

  d(4).name        = 'ellen';
  d(4).parent      = 2;
  d(4).child       = [];
  d(4).data        = [];

  d(5).name        = 'george';
  d(5).parent      = 1;
  d(5).child       = [];
  d(5).data        = [];
end

if( isempty( position ) )
  position = [5 5 300 200];
end

if( isempty(hFig) )
  h.fig = figure( 'position', [50 50 position(3:4)+10], 'NumberTitle', 'off', 'name', name, 'resize','off' );
else
  h.fig = hFig;
end

fontSize = max([ 11 position(4)*9/185] );
v        = { 'parent', h.fig, 'fontunits', 'pixels', 'fontsize', fontSize, 'horizontalalignment','left','fontname','courier', params{:}};

% Draw the frame
%---------------
tag         = GetNewTag( name );
hMatlab6Bug = uicontrol('visible','off'); % Added to fix a Matlab 6 bug
h.frame     = uicontrol( 'style', 'frame', 'position', position, 'string', name, 'tag', tag );

% The gui elements. The positions should be defined relative to the size of the frame
%--------------------------------------------------------------------------
space    = position(3)/60;
x        = position(1) +   space;
y        = position(2) +   space;
xL       = position(3) - 2*space;
yL       = position(4) - 2*space;

h.list   = uicontrol( v{:}, 'position', [x y xL yL], 'style', 'listbox', 'string', ...
                      {}, 'callback', CreateCallback( 'select', tag, callback ) ); 

h        = RebuildList( h, d );

PutH( h )

%--------------------------------------------------------------------------
%   Hide the gui
%--------------------------------------------------------------------------
function Hide( tag )

h = GetH( tag );
set( h.list,  'visible', 'off' );
set( h.frame, 'visible', 'off' );

%--------------------------------------------------------------------------
%   Show the gui
%--------------------------------------------------------------------------
function Show( tag )

h = GetH( tag );
set( h.list,  'visible', 'on' );
set( h.frame, 'visible', 'on' );

%--------------------------------------------------------------------------
%   Get a new tag
%--------------------------------------------------------------------------
function tag = GetNewTag( name )

t   = clock;
tag = [name num2str([t(5:6) 100*rand])];

%--------------------------------------------------------------------------
%   Get the data structure stored in the frame
%--------------------------------------------------------------------------
function h = GetH( tag )

figH = findobj( 'tag', tag );
h    = get( figH, 'UserData' );

%--------------------------------------------------------------------------
%   Put the data structure into the user data
%--------------------------------------------------------------------------
function PutH( h )

set( h.frame, 'UserData', h );

%--------------------------------------------------------------------------
%   Create a callback string for this tool
%--------------------------------------------------------------------------
function s = CreateCallback( action, modifier, cB )

s = ['HierarchicalListPlugIn( ''' action ''',''' modifier ''');' cB ';'];

%--------------------------------------------------------------------------
%   Get the data from the gui fields
%--------------------------------------------------------------------------
function d = GetData( tag )

h = GetH( tag );
d = h.d;

%--------------------------------------------------------------------------
%   Get the data from the gui fields
%--------------------------------------------------------------------------
function d = GetDataForSelection( tag )

h = GetH( tag );
if( isfield( h, 'map') & (~isempty(h.map)) )
  j = h.map( get( h.list, 'value' ) );
  d = h.d(j);
else
  d = [];
end

%--------------------------------------------------------------------------
%   Get the data from the gui fields
%--------------------------------------------------------------------------
function x = GetSelection( tag )

h    = GetH( tag );

x    = GetListString( h.list );
j    = [findstr('+',x) findstr('-',x)];
x(j) = '';
x    = DeBlankLT(x);

%--------------------------------------------------------------------------
%   Get the data from the gui fields
%--------------------------------------------------------------------------
function x = GetList( tag )

h    = GetH( tag );

x    = get( h.list, 'string' );

%--------------------------------------------------------------------------
%   Get complete name of the element. This includes all parents.
%--------------------------------------------------------------------------
function name = GetFullName( tag )

h = GetH( tag );

s    = get( h.list, 'string' ); % The entire list
x    = GetListString( h.list ); % Find the selected item

if( isempty(x) )
    name = '';
    return;
end

j    = strmatch( x, DeBlankLT(s), 'exact' ); % Where it is in the list

if( x(1) == '+' | x(1) == '-' )
  x = x(2:end);
end

p       = 1;
name{1} = x;
for k = (j-1):-1:1
	
  % This branch happens if the name has been matched
  %-------------------------------------------------
  selectedName = DeBlankLT( s{k} );
  jP = findstr('+',selectedName);
  if( selectedName(1) == '-' )
   p       = p + 1;
   name{p} = selectedName(2:end);
  end
  
  if(s{k}(1) == '-')
	break;
  end

  % Find the selected name in the list
  %-----------------------------------
  if( strmatch(x,selectedName,'exact') )
	p       = 1;
	name{p} = selectedName;
  end
end
	
name = fliplr(name);  

%--------------------------------------------------------------------------
%   True if the element has children
%--------------------------------------------------------------------------
function k = HasChildren( tag )

h = GetH( tag );
x = GetListString( h.list );
j = [findstr('+',x) findstr('-',x)];

if( ~isempty(j) )
  k = 1;
else
  k = 0;
end

%--------------------------------------------------------------------------
%   Set the data in the gui fields
%--------------------------------------------------------------------------
function SetData( tag, d )

h = GetH( tag );
h = RebuildList( h, d );
set( h.list, 'value', 1 );
PutH( h );

%--------------------------------------------------------------------------
%   Rebuild the list. This is done whenever the list is edited.
%--------------------------------------------------------------------------
function h = RebuildList( h, d )

h.n        = length(d);
h.open     = zeros(1,h.n); % Determines if the element is open
h.next     = zeros(1,h.n); % Pointer to the children
h.previous = zeros(1,h.n); % Pointer to the parent
h.group    = [];
h.level    = [];
h.d        = d;

if( isempty(d) )
  set( h.list, 'string', {} );
  return;
end

% A group is a set of children
%-----------------------------
h.nGroup      = 1;
currentGroup  = h.nGroup;
iM            = 0;
h.map         = [];
for k = 1:length(h.d)
  if( h.d(k).parent == 0 )
	iM         = iM + 1;
	h.map(iM)  = k;
	h.group(k) = currentGroup; 
    h          = SetUpList( h, k, 0 );  
  end
end

SetList( h );

%--------------------------------------------------------------------------
%   Create the list
%--------------------------------------------------------------------------
function h = SetUpList( h, k, level )

% Find the parent
%----------------
h.previous(k) = h.d(k).parent;

% Go to the next level if there are children
%-------------------------------------------
h.level(k) = level;
if( ~isempty(h.d(k).child) )
  h.nGroup          = h.nGroup + 1;
  currentGroup      = h.nGroup;
  for j =  1:length(h.d(k).child)
    if( j == 1 )
	  h.next(k) = h.d(k).child(j);
	end
    h.group(h.d(k).child(j)) = currentGroup;
	h = SetUpList( h, h.d(k).child(j), level+1 );
  end
end      

%--------------------------------------------------------------------------
%   Set the list in the listbox. Draws + or - in front of the name if
%   the element has children.
%--------------------------------------------------------------------------
function h = SetList( h )

p = 0;
list = {};
for p = 1:length(h.map)
  j = h.map(p);
  if( p > 0 )
    if( h.next(j) > 0 )
	  if( h.open(j) )
	    list{p} = [blanks(h.level(j)) '-' h.d(j).name];
      else
	    list{p} = [blanks(h.level(j)) '+' h.d(j).name];
      end
    elseif( i ~= 0 )
      list{p} = [blanks(h.level(j)) ' ' h.d(j).name];
    end
  end
end
set( h.list, 'string', list );

%--------------------------------------------------------------------------
%   Select the list
%--------------------------------------------------------------------------
function h = Select( tag )

h         = GetH( tag );

k         = get( h.list, 'value' );
j         = h.map(k);

h.open(j) = ~h.open(j);
h         = BuildList( h );
h         = SetList( h );

PutH( h );

%--------------------------------------------------------------------------
%   Check for ancestors
%--------------------------------------------------------------------------
function lPath = CheckAncestors( name, kNameToCheck, kPersonFromList, h, lPath )

if( strcmp( name{kNameToCheck}, h.d(kPersonFromList).name ) )
  lPath = [kPersonFromList lPath];
  if( kNameToCheck == 1 )
    return;
  elseif( h.previous(kPersonFromList) > 0 );
	lPath = CheckAncestors( name, kNameToCheck-1, h.previous(kPersonFromList), h, lPath );
  end
else
  lPath = [];
end

%--------------------------------------------------------------------------
%   Select an element from the list using a full path name
%   The name is a cell array, e.g. {'grandparent' 'parent' 'name'}
%--------------------------------------------------------------------------
function failed = SelectExternal( tag, name )

h       = GetH( tag );
h       = RebuildList( h, h.d );
PutH( h );

k       = 0;
lD      = length(h.d);
lPath   = [];
while( k < lD )
  k     = k + 1;
  lPath = CheckAncestors( name, length(name), k, h, lPath );
  if( ~isempty(lPath) )
    break;
  end
end

if( isempty( lPath ) )
  failed = 1;
  return;
else
  failed = 0;
end

for k = lPath
  h = GetH( tag );
  j = find( k == h.map );
  set( h.list, 'value', j );
  Select( tag );
end

%--------------------------------------------------------------------------
%  Build the list
%--------------------------------------------------------------------------
function h = BuildList( h )

h.map = [];

[h, kL] = TraverseList( h, 1, 0 );

%--------------------------------------------------------------------------
%  Called recursively
%--------------------------------------------------------------------------
function [h, kL] = TraverseList( h, kGroup, kL )

j = find( kGroup == h.group );
for k = 1:length(j)
  p         = j(k);
  kL        = kL + 1;
  h.map(kL) = p;
  if( (h.next(p) > 0) & (h.open(p)) )
    [h, kL] = TraverseList( h, h.group(h.next(p)), kL );
  end
end

%--------------------------------------------------------------------------
%  Add an element to the list
%--------------------------------------------------------------------------
function AddToList( modifier, dNew )

h   = GetH( modifier );
s   = get( h.list, 'string' );

if( isempty(s) )
  d = dNew;
else
  k = get( h.list, 'value' );
  p = h.map(k);

  for k = 1:length(dNew)
	if( isempty(dNew(k).parent) )
      dNew(k).parent = h.d(p).parent;
	end
  end

  d = [h.d(1:p) dNew h.d((p+1):end)];
end

h = RebuildList( h, d );

PutH( h );

%--------------------------------------------------------------------------
%  Remove an element from the list
%--------------------------------------------------------------------------
function DeleteFromList( modifier )

h    = GetH( modifier );
if( ~isfield( h, 'map' ) )
  return;
end
k    = get( h.list, 'value' );
p    = h.map(k);
d    = h.d;
d(p) = [];
h.d  = d;
h    = RebuildList( h, h.d );
if( k > 1 )
  set( h.list, 'value', k-1 )
else
  set( h.list, 'value', 1   );
end

PutH( h );

%--------------------------------------
% $Date: 2019-12-29 14:10:38 -0500 (Sun, 29 Dec 2019) $
% $Revision: 50751 $
