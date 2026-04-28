function FileHelp( action, modifier )

%---------------------------------------------------------------------------
%   View the file headers.
%---------------------------------------------------------------------------
%   Form:
%   FileHelp( action, modifier )
%---------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   action            Action
%   modifier          Modifier to the action
%
%   -------
%   Outputs
%   -------
%   none
%
%---------------------------------------------------------------------------

%---------------------------------------------------------------------------
%   Copyright 1999 Princeton Satellite Systems, Inc. All rights reserved.
%---------------------------------------------------------------------------

if( nargin < 1 )
  action = 'initialize';
end

switch action

  case 'help'
    HelpSystem( 'initialize', 'OnlineHelp' );

  case 'initialize'
    Initialize;

  case 'run demo'
    h = GetH;
    eval( GetListString( h.files ) );

  case 'find all'
    h = GetH;
    set( h.files, 'string', h.d.fileName );
    h.listID = 1:length(h.d.fileName);
    LoadHeader( h );
	  PutH( h );

  case 'edit file'
    h = GetH;
    s = h.d.fileName{h.current};
    w = which( s );
    if( isempty( w ) )
      msgbox([s ' is not in the MATLAB path']);
    else
      edit( s );
    end

  case 'search file names'
    h = GetH;
    s = lower(get( h.searchString, 'string' ));
    h.listID = [];
    for k = 1:length( h.d.fileName )
      if( ~isempty( findstr( s, lower(h.d.fileName{k}) ) ) )
        h.listID = [h.listID k];
      end
    end
    set( h.files, 'value', 1 );
    set( h.files, 'string', {h.d.fileName{h.listID}} );
    LoadHeader( h );
    PutH( h );

  case 'search file headers'
    h = GetH;
    s = lower(get( h.searchString, 'string' ));
    h.listID = [];
    n = length( h.d.header );
    hWait = waitbar(0,'Searching Headers');
    kWait = round( linspace(1, n, 20) );
    for k = 1:length( h.d.header )
      if( k == kWait(1) )
        figure(hWait)
        waitbar(k/n);
        kWait = kWait(2:end);
      end
      for j = 1:length( h.d.header(k).line )
        if( ~isempty( findstr( s, lower(h.d.header(k).line{j}) ) ) )
          h.listID = [h.listID k];
          break
        end
      end
    end
    close(hWait);
    set( h.files, 'value', 1 );
    set( h.files, 'string', {h.d.fileName{h.listID}} );
    LoadHeader( h );
    PutH( h );

  case 'run example'
    h = GetH;
    s = h.d.fileName{h.current};
    w = which( s );
    if( isempty( w ) )
      msgbox([s ' is not in the MATLAB path']);
    else
      RunExample( h );
    end
 
  case 'save example'
    h = GetH;
    s = EditScroll( 'get', h.editScroll );
    k = h.listID(get(h.files,'value'));
    h.d.fileExample{k} = s;
    h.changed = 1;
    PutH( h );

  case 'select file'
    h = GetH;
    LoadHeader( h );

  case 'quit'
    Quit
end

%---------------------------------------------------------------------------
%   Get the data structure stored in the figure window
%---------------------------------------------------------------------------
function Initialize

% Colors
%-------
silver = [0.96 0.96 0.96];

% Load the data file
%-------------------
h.d = LoadDatabase;

% Create the figure
%------------------
set(0,'units','pixels')   
p      = get(0,'screensize');
h.fig  = figure( 'units', 'pixels', 'Position', [10 p(4) - 580 800 500],...
                 'numbertitle', 'off', 'tag', 'File Help System',...
                 'resize', 'off', 'name', 'File Help System' );

% Draw the logo
%--------------
load xSplash;
h.logo = axes( 'Parent', h.fig, 'box', 'off', 'units', 'pixels', 'position', [10 420 273 70] );
image( xSplash );
axis off

hMatlab6Bug = uicontrol('visible','off'); % Added to fix a Matlab 6 bug

% Controls
%---------
v                 = {'parent', h.fig, 'units', 'pixels','fontunits','pixels'};
h.findAll         = uicontrol( v{:},                  'position', [  5  10  60 20], 'string', 'Find All', 'callback', CreateCallback('find all') );
h.editFile        = uicontrol( v{:},                  'position', [ 70  10  60 20], 'string', 'Edit', 'callback', CreateCallback('edit file') );
h.searchFileNames = uicontrol( v{:},                  'position', [135  10 100 20], 'string', 'Search File Names', 'callback', CreateCallback('search file names') );
h.searchHeaders   = uicontrol( v{:},                  'position', [240  10  95 20], 'string', 'Search Headers', 'callback', CreateCallback('search file headers') );
h.searchString    = uicontrol( v{:}, 'style', 'edit', 'position', [340  10 120 20], 'string', 'Search String', 'backgroundcolor', silver );
h.runExample      = uicontrol( v{:},                  'position', [465  10  80 20], 'string', 'Run Example',   'callback', CreateCallback('run example') );
h.saveExample     = uicontrol( v{:},                  'position', [550  10  80 20], 'string', 'Save Example',  'callback', CreateCallback('save example') );
h.help            = uicontrol( v{:},                  'position', [635  10  80 20], 'string', 'Help',          'callback', CreateCallback('help') );
h.quit            = uicontrol( v{:},                  'position', [720  10  75 20], 'string', 'Quit',          'callback', CreateCallback('quit') );

% List mode control
%------------------
v              = {'parent', h.fig, 'units', 'pixels','style','radiobutton' };

% List boxes
%-----------
v        = {'parent', h.fig, 'units', 'pixels', 'style', 'listbox', 'backgroundcolor', silver };
h.hierL  = HierarchicalListPlugIn( 'initialize', h.d.hD, h.fig, [  5 260 280 130], CreateCallback( 'select file' ) );
           uicontrol( v{:}, 'style', 'text', 'position', [  5 391 280 15], 'string', 'Hierarchical List', 'backgroundcolor', [0.8 0.8 0.8],...
             'fontsize',12);
h.files  = uicontrol( v{:}, 'position', [  5 100 280 130], 'string', h.d.fileName, 'callback', CreateCallback( 'select file' ) );
           uicontrol( v{:}, 'style', 'text', 'position', [  5 231 280 15], 'string', 'Alphabetical List and Search Results', ...
             'backgroundcolor', [0.8 0.8 0.8],'fontsize',12 );
h.header = uicontrol( v{:}, 'position', [300 150 495 320], 'string', {}, 'fontsize', 10, 'fontname','courier' );
h.path   = uicontrol( v{:}, 'style','text', 'position', [300 475 495 15], 'string', {'Full path:'}, 'fontsize', 12, 'backgroundcolor', [0.8 0.8 0.8],...
                      'horizontalalignment','left');

% Edit boxes
%-----------
v            = {'parent', h.fig, 'units', 'pixels', 'style', 'edit', 'backgroundcolor', silver, 'horizontalalignment','left' };
h.template   = uicontrol( v{:}, 'style', 'text', 'position', [  5 35 280 60] );
h.editScroll = EditScroll( 'initialize',[], h.fig, [300 35 495 110] );

% New examples flag
%------------------
h.changed = 0;

h.listID = 1:length(h.d.fileName);
h.current = [];

PutH( h );

%---------------------------------------------------------------------------
%   Load the header for the selected file
%---------------------------------------------------------------------------
function LoadHeader( h )

hC = GetCurrentGUIObject( h.fig );

if( hC == h.files )
  k        = get( h.files, 'value' );
else
  name          = HierarchicalListPlugIn( 'get selection', h.hierL );
  if( name(1:1) == '+' | name(1:1) == '-' )
	  return;
  end
  k = strmatch( name, h.d.fileName, 'exact' );
  if length(k) > 1
    % Must consider path
    fullNameParts = HierarchicalListPlugIn( 'get full name for selection', h.hierL );
    lF            = length(fullNameParts);
    fullName      = fullfile( fullNameParts{lF-1},fullNameParts{lF} );
    for j = (lF-2):-1:1
      fullName = fullfile( fullNameParts{j}, fullName );
    end
    sep     = filesep;
		s       = strmatch(fullNameParts{1},h.d.fullName);
    helpSep = h.d.fullName{s(1)}(length(fullNameParts{1})+1);
    if ~strcmp( sep, helpSep )
      % Build was created on a different platform.
      j = findstr(sep,fullName);
      fullName(j) = helpSep;
    end
    k = strmatch( fullName, h.d.fullName, 'exact' );
  end
  if( isempty(k))
	return;
  end
end
  
if( k > length(h.listID) )
  return;
end

j = h.listID(k);

% set value to prevent bug if new header is shorter than previous header
set( h.header,   'value', 1);
% set header itself and other strings
set( h.header,   'string', h.d.header(j).line );
set( h.template, 'string', h.d.fileFunction{j} );
set( h.path,     'string', ['Full path: ' h.d.fullName{j}]);
% set example
if( j < length(h.d.fileExample) )
  EditScroll( 'set', h.editScroll, h.d.fileExample{j} );
else
  EditScroll( 'set', h.editScroll, {} );
end

h.current = j;
PutH(h);


%---------------------------------------------------------------------------
%   Run an example
%---------------------------------------------------------------------------
function RunExample( h )

p = EditScroll( 'get', h.editScroll );
s = '';
for k = 1:size(p,1)
  if( p(k,1) ~= '%' )
    s = [s ',' p(k,:)];
  end
end
eval( s );

%---------------------------------------------------------------------------
%   Quit
%---------------------------------------------------------------------------
function Quit
   
h = GetH;
if( h.changed )
  switch( questdlg(['Save changes to the examples?']) )
    case 'Yes'
      d = h.d;
      eval( ['save FileHelpDatabase d'] );
      closereq
           
     case 'No'
       closereq
           
     case 'Cancel'
  end
else
  closereq
end

%---------------------------------------------------------------------------
%   Get the data structure stored in the figure window
%---------------------------------------------------------------------------
function h = GetH

h = get( findobj( allchild(0), 'flat', 'tag', 'File Help System' ), 'UserData' );

%---------------------------------------------------------------------------
%   Put the data structure into the user data
%---------------------------------------------------------------------------
function PutH( h )

set( h.fig, 'UserData', h );

%---------------------------------------------------------------------------
%   Create a callback string
%---------------------------------------------------------------------------
function c = CreateCallback( action, modifier )

if( nargin == 2 )
  c = ['FileHelp( ''' action ''',''' modifier ''' )'];
else
  c = ['FileHelp( ''' action ''' )'];
end

%---------------------------------------------------------------------------
%   Load the databases
%---------------------------------------------------------------------------
function d = LoadDatabase

s   = which('FileHelp','-all');
c   = cd;
d   = [];
for j = 1:size(s,1);
  p   = fileparts(s{j});
  cd(p);
  if exist(fullfile(p,'FileHelpDatabase.mat'))
      x   = load( 'FileHelpDatabase' );
      if( isempty(d) )
        d.fileName     = x.d.fileName;
        d.fullName     = x.d.fullName;
        d.fileFunction = x.d.fileFunction;
        d.header       = x.d.header;
        d.hD           = x.d.hD;
        d.fileExample  = x.d.fileExample;
      else
        d.fileName     = {d.fileName{:} x.d.fileName{:}};
        d.fullName     = {d.fullName{:} x.d.fullName{:}};
        d.fileFunction = {d.fileFunction{:} x.d.fileFunction{:}};
        d.header       = [d.header x.d.header];
		    n              = length(d.hD);
      	for k = 1:length(x.d.hD)
      	  if( x.d.hD(k).parent > 0 )
      		  x.d.hD(k).parent = x.d.hD(k).parent + n;
      	  end
      	  x.d.hD(k).child = x.d.hD(k).child + n;
      	end
        d.hD           = [d.hD x.d.hD];
        d.fileExample  = {d.fileExample{:} x.d.fileExample{:}};
      end
    end
end

cd(c)

% PSS internal file version information
%--------------------------------------
% $Date: 2007-07-12 12:41:51 -0400 (Thu, 12 Jul 2007) $
% $Revision: 10377 $
