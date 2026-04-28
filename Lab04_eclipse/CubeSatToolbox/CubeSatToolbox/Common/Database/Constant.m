function [x, u] = Constant( q, gUICode )

%% Outputs the value of a constant or opens a GUI for searching. 
% q must be an exact match. Case and spaces have no effect. 
% To search for a string (without using the GUI) type 
%
%       Constant( searchString, 'find' )
%
% Loads either sCTConstants.mat or, if not found, ACTConstants.mat.
%--------------------------------------------------------------------------
%   Form:
%   [x, u] = Constant( q, gUICode )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   q               (1,:)  String describing the constant
%   gUICode         (1,:)  GUI code
%
%   -------
%   Outputs
%   -------
%   x               (1,1)  The value
%   u               (1,:)  Units (if applicable)
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%  Copyright (c) 1994-2004 Princeton Satellite Systems, Inc.
%  All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%   2018.1 Update some code based on MATLAB recommendations
%--------------------------------------------------------------------------

persistent constName constNameNoSpace value units reference changed currentDirectory sCTPath 

% Load the database only if the it is empty
%------------------------------------------
if( isempty(constName) )
	
  % There are space constants and other constants
  %----------------------------------------------
  ConstantsPath = which('Constants.mat');
  sCTPath       = which('sCTConstants.mat');
  ACTPath       = which('ACTConstants.mat');
  mLTPath       = which('mLTConstants.mat');
  
  if( ~isempty(ConstantsPath) )
    load Constants
    sCTPath = ConstantsPath;
  elseif( ~isempty(sCTPath) )
    load sCTConstants
  elseif( ~isempty(sCTPath) )
    load ACTConstants
    sCTPath = ACTPath;
  elseif( ~isempty(sCTPath) )
    load mLTConstants
    sCTPath = mLTPath;
  else
    disp('Constant: Sorry, no constant database was found.');
    return;
  end

end 

if( nargin == 0 )
  changed = 0;
  CreateGUI( sCTPath );
	if( nargout > 0 )
	  x = constName;
	end
  return
  
elseif( nargin == 2 )

  h = GetH;

  switch gUICode
    case 'search'
      searchString = NoSpace( get( h.searchString, 'string' ) );
      tMatch = Search( searchString, constName, constNameNoSpace );
      if( ~isempty(tMatch) )
        set( h.tL, 'string', tMatch );
      else
        set( h.tL, 'string', 'No matches' );
      end
      set( h.tL, 'value', 1 );
      
    case 'find'
      x = Search( q, constName, constNameNoSpace );
     
    case 'get value'
      k = get( h.tL, 'value' );
      if( k > 0 )
        s  = get(h.tL,'string');
        kS = strmatch( s{k}, constName, 'exact' );
        set( h.value,  'string', num2str(value{kS},9) )
        set( h.units,  'string', units{kS} );
        set( h.string, 'string', constName{kS} );
        set( h.ref,    'string', reference{kS} );
        set( h.paste,  'string', ['Constant(''' constName{kS} ''')'] );
      end
      
    case 'all'
      set( h.tL, 'string', constName );
     
    case 'add'
       [constName, constNameNoSpace, value, units, reference] = AddToDatabase( constName, constNameNoSpace, value, units, reference );
       changed = 1;
       
    case 'delete'
       [constName, constNameNoSpace, value, units, reference] = DeleteFromDatabase( constName, constNameNoSpace, value, units, reference );
       changed = 1;
       
    case 'quit'
       if( changed )
         switch( questdlg(['Save changes to the database ' sCTPath, '?']) )
           case 'Yes'
             eval(['save ''' sCTPath ''' constName constNameNoSpace value units reference']);
             closereq
           
           case 'No'
             closereq
         end
       else
         closereq
       end
       
    case 'save'
       if( changed )
         switch( questdlg(['Save changes to the database ' sCTPath, '?']) )
           case 'Yes'
             eval(['save ''' sCTPath ''' constName constNameNoSpace value units reference']);
						 changed = 0;
          end
       end
      
  end
  
else
  k = strmatch( lower(q), constName, 'exact' );
  if( ~isempty(k) )
    x = value{k};
    u = units{k};
  else
    disp([q ' is not in the database']);
    x = [];
    u = ' ';
  end
end
  
%--------------------------------------------------------------------------
%   Initialize the display
%--------------------------------------------------------------------------
function CreateGUI( sCTPath )

if( ~isempty( GetH ) )
  return;
end

% The figure window
%------------------
p           = get(0,'screensize');
bottom      = p(4) - 480;
h.fig       = figure('name','Constant Database','Units','pixels',...
                     'Position',[40 bottom 540 370],'resize','off',...
                     'NumberTitle','off','tag','Constant Database', 'CloseRequestFcn','Constant([],''quit'')');
% List box
%---------
h.s         = {' '};
v           = {'parent',h.fig,'units','pixels','fontunits','pixels'};
hMatlab6Bug = uicontrol('visible','off'); % Added to fix a Matlab 6 bug
uicontrol( v{:}, 'Position',[15 330 250 15],'FontSize',12,'fontweight','bold',...
                 'FontName','Helvetica', 'Style','text','string','Search Results',...
                 'backgroundcolor',[0.8 0.8 0.8],'horizontalalignment','center');
								 
h.tL        = uicontrol('Parent',h.fig,'Units','pixels','style','listbox',  'Position',[15 5 250 305], ...
                        'HorizontalAlignment','left','string',h.s,'callback','Constant([],''get value'')');

uicontrol( v{:}, 'Position',[330 275 200 15],'FontSize',12,'fontweight','bold',...
                 'FontName','Helvetica', 'Style','text','string','Search String',...
                 'backgroundcolor',[0.8 0.8 0.8],'horizontalalignment','center');
uicontrol( v{:}, 'Position',[270 300 270 25],'FontSize',9,'fontweight','bold',...
                 'FontName','Helvetica', 'Style','text','string',sCTPath,...
                 'backgroundcolor',[0.8 0.8 0.8],'horizontalalignment','center');
								 
h.searchString = uicontrol( v{:}, 'Position',[330 250 205 20],'HorizontalAlignment','left', 'Style','edit','callback','Constant([],''search'')');
h.search       = uicontrol( v{:}, 'Position',[330 220  65 20],'callback', 'Constant([],''search'')','string','Find');
h.add          = uicontrol( v{:}, 'Position',[400 220  65 20],'callback', 'Constant([],''add'')',   'string','Add');
h.delete       = uicontrol( v{:}, 'Position',[470 220  65 20],'callback', 'Constant([],''delete'')','string','Delete');
h.all          = uicontrol( v{:}, 'Position',[270 250  55 20],'callback', 'Constant([],''all'')',   'string','Find All');
h.save         = uicontrol( v{:}, 'Position',[270 220  55 20],'callback', 'Constant([],''save'')',  'string','Save');

% Property edit boxes
%--------------------
uicontrol( v{:}, 'Position',[280 189 40 15], 'Style','text'...
          ,'string','String','HorizontalAlignment','right','FontSize',10,'FontName','Helvetica','backgroundcolor',[0.8 0.8 0.8]);

uicontrol( v{:}, 'Position',[280 140 40 15], 'Style','text',...
          'string','Value','HorizontalAlignment','right','FontSize',10,'FontName','Helvetica','backgroundcolor',[0.8 0.8 0.8]);
          
uicontrol( v{:}, 'Position',[280 94 40 15], 'Style','text'...
          ,'string','Units','HorizontalAlignment','right','FontSize',10,'FontName','Helvetica','backgroundcolor',[0.8 0.8 0.8]);

uicontrol( v{:}, 'Position',[270 39 50 25], 'Style','text'...
          ,'string','Reference','HorizontalAlignment','right','FontSize',10,'FontName','Helvetica','backgroundcolor',[0.8 0.8 0.8]);

uicontrol( v{:}, 'Position',[280  5 40 25], 'Style','text'...
          ,'string','Cut and Paste','HorizontalAlignment','right','FontSize',10,'FontName','Helvetica','backgroundcolor',[0.8 0.8 0.8]);
          

h.string = uicontrol( v{:}, 'Position',[330 185 205 25], 'Style','edit','backgroundcolor', [1 1 1],...
                     'FontSize',10,'FontName','Helvetica','horizontalalignment','left',...
                     'tooltipstring','The selected constant.');
                     
h.value  = uicontrol( v{:}, 'Position',[330 120 205 60], 'Style','edit','backgroundcolor', [1 1 1],...
                     'FontSize',10,'FontName','Helvetica','horizontalalignment','left','max',2,...
                     'tooltipstring','The value of the constant..');

h.units  = uicontrol( v{:}, 'Position',[330  90 205 25], 'Style','edit','backgroundcolor', [1 1 1],...
                     'FontSize',10,'FontName','Helvetica','horizontalalignment','left',...
                     'tooltipstring','The units for the constant.');

h.ref    = uicontrol( v{:}, 'Position',[330  35 205 50], 'Style','edit','backgroundcolor', [1 1 1],...
                     'FontSize',10,'FontName','Helvetica','horizontalalignment','left',...
                     'tooltipstring','Reference for the constant.');
                     
h.paste  = uicontrol( v{:}, 'Position',[330   5 205 25], 'Style','edit','backgroundcolor', [1 1 1],...
                     'FontSize',10,'FontName','Helvetica','horizontalalignment','left',...
                     'tooltipstring','Copy this into your script or function to use this constant.');

% PSS Logo
%---------
dI = load('xSplashSmall');
h.logo = axes( 'Parent', h.fig, 'box', 'off', 'units', 'pixels', 'position', [380 330 150 37] );
image( dI.dImage );
axis off

              
set( h.fig, 'UserData', h );

Constant( [], 'all' );

%--------------------------------------------------------------------------
%   Add a constant to the database
%--------------------------------------------------------------------------
function [constName, constNameNoSpace, value, units, reference] = AddToDatabase( constName, constNameNoSpace, value, units, reference )

h       = GetH;

s       = get( h.string,'string' );
u       = get( h.units, 'string' );
v       = get( h.value, 'string' );
r       = get( h.ref,   'string' );

n       = length(constName) + 1;

sN      = NoSpace( s );
j       = strmatch( sN, constNameNoSpace );

% Add to the database
%--------------------
update = 0;
if( ~isempty(j) )
  switch( questdlg( ['Replace existing constant ', s, '?']) );
     case 'Yes'
       update = 1;
       n      = j;
     otherwise
   end
else
  update = 1;
end

if( update )
  constName{n}        = s;
  constNameNoSpace{n} = NoSpace( s );
  value{n}            = str2num(v);
  units{n}            = u;
  reference{n}        = r;
  [constName, k]      = sort(constName);
  constNameNoSpace    = {constNameNoSpace{k}};
  value               = {value{k}};
  units               = {units{k}};
  reference           = {reference{k}};
end

%--------------------------------------------------------------------------
%   Delete a constant from the database
%--------------------------------------------------------------------------
function [constName, constNameNoSpace, value, units, reference] = DeleteFromDatabase( constName, constNameNoSpace, value, units, reference )

h       = GetH;

s       = get( h.string,'string' );

sN      = NoSpace( s );
j       = strmatch( sN, constNameNoSpace );

% Add to the database
%--------------------
update = 0;
if( ~isempty(j) )
  switch( questdlg( ['Delete constant ', s, '?']) );
     case 'Yes'
       update = 1;
     otherwise
   end
else
  update = 1;
end

if( update )
  jM               = j - 1;
  jP               = j + 1;
  constName        = DeleteCell( constName, j );
  constNameNoSpace = DeleteCell( constNameNoSpace, j );
  value            = DeleteCell( value, j );
  units            = DeleteCell( units, j );
  reference        = DeleteCell( reference, j );
end

%--------------------------------------------------------------------------
%   Add a constant to the database
%--------------------------------------------------------------------------
function h = GetH

hFig    = findobj( allchild(0), 'flat','Tag', 'Constant Database');

if( ~isempty(hFig) )
  h = get( hFig, 'UserData' );
else
  h = [];
end

%--------------------------------------------------------------------------
%   Remove spaces
%--------------------------------------------------------------------------
function x = NoSpace( s )

x = s;
j = isspace(x);
x(  j == 1  ) = [];

%--------------------------------------------------------------------------
%   Search
%--------------------------------------------------------------------------
function tMatch = Search( searchString, constName, constNameNoSpace )

kMatch = [];
for k = 1:length(constName)
  if( length( constNameNoSpace{k} ) >= length( searchString ) )
    if( ~isempty(strfind( constNameNoSpace{k}, searchString )) )
      kMatch = [kMatch k];
    end
  end
end

if( ~isempty(kMatch) )
  tMatch = {constName{kMatch}};
else
  tMatch = {};
end


%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2018-11-07 14:21:31 -0500 (Wed, 07 Nov 2018) $
% $Revision: 47408 $
