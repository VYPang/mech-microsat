function HelpSystem( action, file, searchText, title )

%-------------------------------------------------------------------------------
%   Creates the help system
%-------------------------------------------------------------------------------
%   Form:
%   HelpSystem( action, file, searchText, title )
%-------------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   action          (1,:)   Action to be taken 
%   file            (1,1)   .mat file
%   searchText      (1,:)   On initialize search for this text
%
%   -------
%   Outputs
%   -------
%   none
%
%-------------------------------------------------------------------------------

%-------------------------------------------------------------------------------
%   Copyright 1998 Princeton Satellite Systems, Inc. All rights reserved.
%-------------------------------------------------------------------------------

if( nargin < 1 )
  action  = 'initialize';
end

if( nargin < 2 )
  file = 'OnlineHelp.mat';
end

if( strcmp(action, 'initialize') &&... 
  ( strcmp(file,'OnlineHelp') ||...
    strcmp(file, 'OnlineHelp.mat') ) &&...
    exist('GUIindex.html','file') )

    if nargin < 3
        web GUIindex.html;
    else
        try
            htmlpage = searchHTMLheaders(searchText);
            web(htmlpage);
        catch 
            web GUIindex.html;
        end
    end
    return;
end

switch action
  case 'initialize'   
    if( ~Exists( file ) )
      if( nargin > 3 )
        h = InitializeGUI( file, title );
      else
        h = InitializeGUI( file, file );
      end
      h = InitializeHelp( h, file );
      PutH( h.fig, h );
    else
      h = GetH( file );
      figure( h.fig );
    end
    if( nargin > 2 && ~isempty(searchText) &&...
      ~( strcmp(file,'OnlineHelp') || strcmp(file, 'OnlineHelp.mat') ))
      set( h.search, 'string', searchText )
      h = Search( h, 'headers' );
      PutH( h.fig, h );
    end

  case 'select'
    h = GetH( file );
    h = Select( h );
    PutH( h.fig, h );

  case 'search text'
    h = GetH( file );
    h = Search( h, 'text' );
    PutH( h.fig, h );

  case 'search headers'
    h = GetH( file );
    disp('**** Second h *****')
    disp(h)
    h = Search( h, 'headers' );
    PutH( h.fig, h );

  case 'restore list'
    h = GetH( file );
    h = RestoreList( h );
    PutH( h.fig, h );

end

%-------------------------------------------------------------------------------
%   Initialize the GUI
%-------------------------------------------------------------------------------
function h = InitializeGUI( file, title )

% The figure window
%------------------
         set(0,'units','points');
p      = get(0,'screensize');
height = 290;
width  = 540;
bottom = p(4) - height - 80;
gray   = 0.9*[1 1 1];
h.fig  = figure('name','Online Help','Units','points',...
                'Position',[40 bottom width height ],...
                'NumberTitle','off','tag', GetTag( file ) );
set( h.fig, 'color', gray )

v            = {'Parent',h.fig,'units','points','fontunits','pixels','fontsize',11};

hMatlab6Bug  = uicontrol('visible','off'); % Added to fix a Matlab 6 bug

h.helpTopics = uicontrol( v{:}, 'fontName','courier','Position', [   5 60 150 height-75 ],...
                         'Style','listbox', 'string',{},'callback', HelpCallback( 'select', file )); 
h.help       = uicontrol( v{:}, 'Position', [  160 60 360 height-100 ], 'Style','listbox', 'string',{});
h.title      = uicontrol( v{:}, 'Position', [  160 height-30 360 15 ], 'Style','text','horizontalalignment','left','fontweight','bold');
h.searchT    = uicontrol( v{:}, 'Position', [    5 30  60 20 ], 'Style','text', 'string','Search For:',...
                          'backgroundcolor', gray,'horizontalalignment','right');
h.search     = uicontrol( v{:}, 'Position', [   70 30 230 20 ], 'Style','edit','horizontalalignment','left','backgroundcolor', gray);
h.searchH    = uicontrol( v{:}, 'Position', [  310 30 100 20 ], 'String','Search Headings','callback',HelpCallback( 'search headers', file ) );
h.searchA    = uicontrol( v{:}, 'Position', [  420 30 100 20 ], 'String','Search Text','callback',HelpCallback( 'search text', file ) );
h.restore    = uicontrol( v{:}, 'Position', [  420  5 100 20 ], 'String','Restore List','callback',HelpCallback( 'restore list', file ) );

%-------------------------------------------------------------------------------
%   Help System Callbacks
%-------------------------------------------------------------------------------
function c = HelpCallback( action, file )

c = ['HelpSystem(''' action ''',''' file ''')'];

%-------------------------------------------------------------------------------
%   Get data from the figure handle
%-------------------------------------------------------------------------------
function h = GetH( file )

figH = findobj( allchild(0), 'tag', GetTag( file ) );
h    = get( figH, 'userData' );

%-------------------------------------------------------------------------------
%   Get tag
%-------------------------------------------------------------------------------
function t = GetTag( file )

t = ['HelpSystem' file];

%-------------------------------------------------------------------------------
%   See if help window already exists
%-------------------------------------------------------------------------------
function s = Exists( file )

figH = findobj( allchild(0), 'tag', GetTag( file ));
if( isempty(figH) )
  s = 0;
else
  s = 1;
end

%-------------------------------------------------------------------------------
%   Put data into the figure handle
%-------------------------------------------------------------------------------
function PutH( h, d )

set( h, 'userdata', d );

%-------------------------------------------------------------------------------
%   Select the list
%-------------------------------------------------------------------------------
function h = Select( h )

kSelect = get( h.helpTopics, 'value' );
kAvail  = find(h.d.listMap>0);
j = h.d.listMap(kAvail(kSelect));
p = h.d.pointer(j);

if( p < 0 )
  set( h.help,  'string', h.d.text{-p});
  set( h.title, 'string', h.d.header(j) );
else
  [h.d.header(j),  h.d.open(j) ] = Toggle( h.d.header(j),  h.d.open(j) );
  h = BuildList( h );
  h = SetList( h );
end

%-------------------------------------------------------------------------------
%  Build the list
%-------------------------------------------------------------------------------
function h = BuildList( h )

h.d.listMap = zeros(1,length(h.d.pointer));

[h, kL] = TraverseList( h, 1, 0 );

%-------------------------------------------------------------------------------
%  Called recursively
%-------------------------------------------------------------------------------
function [h, kL] = TraverseList( h, kGroup, kL )

j = find( h.d.group == kGroup );
for k = 1:length(j)
  p  = j(k);
  kL = kL + 1;
  h.d.listMap(kL) = p;
  if( h.d.pointer(p) > 0 & h.d.open(p) )
    [h, kL] = TraverseList( h, h.d.pointer(p), kL );
  end
end

%-------------------------------------------------------------------------------
%   Toggle the variables
%-------------------------------------------------------------------------------
function [s, k] = Toggle( s, k )

k = ~k;

j = findstr(char(s),'+');
if( ~isempty(j) )
  s{1}(j) = '-';
else
  j = findstr(char(s),'-');
  s{1}(j) = '+';
end

%-------------------------------------------------------------------------------
%   Search the help file
%-------------------------------------------------------------------------------
function h = Search( h, type )

% Get the search string
%----------------------
s              = lower(get( h.search, 'string' ));
found          = {};
kF             =  0;
h.d.listMap    = zeros(1,length(h.d.pointer));

% Clear the help window
%----------------------
set( h.help, 'string', {} );

kText = find( h.d.pointer < 0 );

switch type
  case 'text'
    for k = 1:length(kText)

      match = 0;
      kT    = kText(k);
      j     = -h.d.pointer(kT);

      for i = 1:length(h.d.text{j})
        p = findstr(lower(char(h.d.text{j}(i))), s );
        if( ~isempty(p) )
          match = 1;
          break;
        end
      end

      if( match )
        kF              = kF + 1;
        found{kF}       = DeleteLeadingChars( h.d.header{kT} );
        h.d.listMap(kF) = kT;
      end

    end

  case 'headers'
    for k = 1:length(h.d.pointer)
      p     = findstr(lower(char(h.d.header{k})), s );

      if( ~isempty(p) )
        kF              = kF + 1;
        found{kF}       = DeleteLeadingChars( h.d.header{k} );
        h.d.listMap(kF) = k;
      end

    end
end
set( h.helpTopics, 'value', 1 );
set( h.helpTopics, 'string', found );

%-------------------------------------------------------------------------------
%   Initialize the display
%-------------------------------------------------------------------------------
function h = InitializeHelp( h, file )

% SJT: add .mat if missing to avoid errors
if ~strcmp(file(end-3:end),'.mat')
  file = [file '.mat'];
end

s   = which(file,'-all');
c   = cd;
for j = 1:size(s,1);
  p   = fileparts(s{j});
  x = load(s{j});
  if( j == 1 )
    h.d = x.d;
  else
     % Adjust indexing for stacking multiple databases
     n           = length(h.d.pointer);
     nP          = length(find(h.d.pointer>0));
     % Store headers, text, and open in order
     h.d.header  = {h.d.header{:} x.d.header{:}};
     h.d.text    = {h.d.text{:}   x.d.text{:}};
     h.d.open    = [h.d.open      x.d.open];
     % Increment text pointers by (n-nP)
     k = find(x.d.pointer<0);
     x.d.pointer(k) = x.d.pointer(k)-n+nP;
     % Increment positive listMap entries by n, for initial display
     k = find(x.d.listMap>0);
     x.d.listMap(k) = x.d.listMap(k)+n;
     h.d.listMap = [h.d.listMap   x.d.listMap];
     % Header pointers indicate next group
     k           = find(x.d.group>1);
     nGroups     = length(unique(h.d.group));
     x.d.group(k) = x.d.group(k)+nGroups;
     h.d.group   = [h.d.group     x.d.group];
     k = find(x.d.pointer>0);
     x.d.pointer(k) = x.d.pointer(k)+nGroups;
     h.d.pointer = [h.d.pointer   x.d.pointer];
  end
end

h = SetList( h );

%-------------------------------------------------------------------------------
%   Set the list in the listbox
%-------------------------------------------------------------------------------
function h = SetList( h )

k = find( h.d.listMap > 0 );
for j = 1:length(k)
  list{j} = h.d.header{h.d.listMap(k(j))};
end
set( h.helpTopics, 'string', list );
h.d.listMapOld = h.d.listMap;

%-------------------------------------------------------------------------------
%   Delete leading chars
%-------------------------------------------------------------------------------
function s = DeleteLeadingChars( c )

s = char( c );
k = find( s ~= ' ' );
s = s(min(k):length(s));
k = find( s == '+' );
if ~isempty(k)
  s = s(k:end);
end

%-------------------------------------------------------------------------------
%   Restore the list
%-------------------------------------------------------------------------------
function h = RestoreList( h )

if( isfield( h.d, 'listMapOld' ) )
  h.d.listMap = h.d.listMapOld;
end
h = SetList( h );

%-------------------------------------------------------------------------------
%   Search the HTML GUI help pages for header
%-------------------------------------------------------------------------------
function htmlpage = searchHTMLheaders(searchText)

indices = which('GUIindex.html','-all');
found = 0;

for k = 1:length(indices)
  fid = fopen(indices{k});
  htmlpage = 'GUIindex.html';
  while(~feof(fid))
      line = fgetl(fid);
      if strfind(line,searchText)
          locations = strfind(line,'"');
          htmlpage = line(locations(1)+1:locations(2)-1);
          found = 1;
          break;
      end
  end
  fclose(fid);
  if (found)
    break;
  end
end




% PSS internal file version information
%--------------------------------------
% $Date: 2015-07-10 11:44:52 -0400 (Fri, 10 Jul 2015) $
% $Revision: 40415 $
