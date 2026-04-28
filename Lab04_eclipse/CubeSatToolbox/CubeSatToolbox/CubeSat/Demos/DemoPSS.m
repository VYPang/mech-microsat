function y = DemoPSS( action, varargin )

%---------------------------------------------------------------------------
%   Demonstrate the toolbox
%---------------------------------------------------------------------------
%   Form:
%   DemoPSS( action, info  )
%---------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   action            Action
%
%   -------
%   Outputs
%   -------
%   none
%
%---------------------------------------------------------------------------

%---------------------------------------------------------------------------
%   Reference: None
%---------------------------------------------------------------------------
%   Copyright (c) 1998-2001 Princeton Satellite Systems, Inc.
%   All rights reserved.
%---------------------------------------------------------------------------

persistent hDemo;

% Global for the time GUI
%------------------------
global simulationAction
simulationAction = ' ';

if( nargin < 1 )
  action = 'initialize';
end
y = [];

switch action

  case 'help'
    HelpSystem( 'initialize', 'OnlineHelp' );

  case 'initialize'
    hDemo = Initialize;

  case 'select file'
    SelectFile;

  case 'get hierarchical data'
    y = GetHierarchicalData;
    return;
	
    case 'run demo'
      s = GetFileName;
      if( ~isempty(s) && exist(s)==2 )
        ClearPlots;
        j = strfind(s,'.');
        set( hDemo.fig, 'HandleVisibility', 'off' );
        set(0, 'ShowHiddenHandles', 'off');
        catchStr = ['disp(''Sorry, but ' s ' had this problem executing:''); s = lasterr; disp(s);'];
        eval( s(1:(j-1)), catchStr );
        set(0, 'ShowHiddenHandles', hDemo.showH);
        set( hDemo.fig, 'HandleVisibility','on' );
      end

    case 'stop demo'
      simulationAction = 'plot';

    case 'run all'
      % DemoPSS('run all',toolbox,kInit), for testing builds
      DemoPSS;
      toolbox = []; % This can be [] or 'SC', 'Orbit', etc.
      kInit   = 1;  % If using [] for toolbox, hardcode a start demo # here.
      if ~isempty(varargin)
        toolbox = varargin{1};
      end
      if length(varargin)>1
        kInit = varargin{2};
      end
      if ~isempty(toolbox)
        kInit   = strmatch(toolbox,{hDemo.hData.name},'exact');
        if length(kInit)>1
          warning('Multiple folder matches found, running all');
        end
        for k = 1:length(kInit)
          kParent = [kParent find([hDemo.hData.parent]==kInit(k))];
        end
      else
        kParent = [hDemo.hData.parent];
      end
      pause off
      
      numErrors     = 0;
      problemDemos  = {};
      errorMessages = {};
      keepVars      = {};
      
      total = 0;
      for k = kInit:length(hDemo.hData)
         if( ~isempty(findstr('.',hDemo.hData(k).name)) & ismember(hDemo.hData(k).parent,kParent) )
            total = total + 1;
         end
      end
      total = num2str(total);
      
      nDemo = 0;
      for k = kInit:length(hDemo.hData)
        j = findstr('.',hDemo.hData(k).name);
        if( ~isempty(j) )
          if ismember(hDemo.hData(k).parent,kParent)
            nDemo = nDemo + 1;
            disp('')
            disp('------------------')
            disp(['Running # ' num2str(nDemo) ' of ' total ': ' hDemo.hData(k).name ])
            disp('------------------')
            ClearPlots;
            set( hDemo.fig, 'HandleVisibility', 'off' );
            set(0, 'ShowHiddenHandles', 'off');
            demoName = hDemo.hData(k).name(1:(j-1));
            newError = 0;
            
            % record all variables that must be kept
            if( isempty(keepVars) ), keepVars = who; end
            
            % call the function
            eval( demoName, 'newError = 1;' );
            
            % clear new variables from the script
            clearVars = setdiff( who, keepVars );
            for jjj = 1:length(clearVars), clear(clearVars{jjj}); end
            clear clearVars;
            
            if( newError )
               numErrors            = numErrors + 1;
               problemDemos{end+1}  = demoName;
               errorMessages{end+1} = lasterr;
            end
            set(0, 'ShowHiddenHandles', hDemo.showH);
            set( hDemo.fig, 'HandleVisibility','on' );
          end
        end
      end
      
      disp(sprintf('\n\n\n%d Total Demos Ran\n',nDemo));
      disp(sprintf('%d Problem Demos:\n----------------------------------------',numErrors));
      for j=1:numErrors,
         d = fileparts(which(problemDemos{j}));
         category = [filesep, d(findstr(lower(d),'demos')+6:end)];
         disp(sprintf('\n#%2d. %s',j,problemDemos{j}));
         disp(sprintf('\t %s',category));
         disp(sprintf('\t %s\n',errorMessages{j}));
      end

    case 'show script'
      s = GetFileName;
      if( ~isempty(s) & exist(s)==2 )
        eval( ['edit ' s] );
      end

    case 'quit'
     set(hDemo.fig,'HandleVisibility','on');
	 	 h = GetH;
     set(0, 'ShowHiddenHandles', h.showH);
     close all
end
clear y

%---------------------------------------------------------------------------
%   Initialize
%---------------------------------------------------------------------------
function h = Initialize

h = GetH;
if ~isempty(h)
  figure(h.fig);
  return;
end

load xSplash;
set(0,'units','pixels')   
p      = get(0,'screensize');
h.fig  = figure('Position',[10 p(4) - 480 630 400],'NumberTitle','off','color',[1 1 1],'tag','PSS Demo','Name','PSS Demo', 'units','pixels','resize','off');
set(h.fig,'color',[1 1 1]);
h.logo = axes( 'Parent', h.fig, 'box', 'off' ,'Units', 'pixels', 'Position', [10 300 273 70] );
image(xSplash);
axis off

v        = {'parent',h.fig,'units','pixels','fontunits','pixels'};

h.hData    = GetHierarchicalData;

space    = 10;
nButtons = 5;
w        = (630 - (nButtons+1)*space)/nButtons;
dX       = w + space;

hMatlab6Bug = uicontrol('visible','off'); % Added to fix a Matlab 6 bug

h.t      = uicontrol( 'parent',h.fig,'style','text','BackgroundColor',[1 1 1],'Position', [300 300 273 72]);
           set( h.t,'units','pixels','fontunits','pixels','string','Demos','FontName','helvetica','FontSize',72,'FontWeight','bold');
h.tL     = HierarchicalListPlugIn( 'initialize', h.hData, h.fig, [ 10 50 200 200], CreateCallback( 'select file' ) );
h.tE     = uicontrol( v{:},'Position',[ 220 50 400 200],'style','text','HorizontalAlignment','left');
x        = 10;
h.showS  = uicontrol( v{:},'Position',[   x 10 w  30],'string','Show the Script','callback', CreateCallback( 'show script')); x = x + dX;
h.pB     = uicontrol( v{:},'Position',[   x 10 w  30],'string','Run the Demo',   'callback', CreateCallback( 'run demo')   ); x = x + dX;
h.stop   = uicontrol( v{:},'Position',[   x 10 w  30],'string','Stop the Demo',  'callback', CreateCallback( 'stop demo')  ); x = x + dX;
h.quit   = uicontrol( v{:},'Position',[   x 10 w  30],'string','Quit',           'callback', CreateCallback( 'quit')       ); x = x + dX;
h.help   = uicontrol( v{:},'Position',[   x 10 w  30],'string','Help',           'callback', CreateCallback( 'help')       );

% Disable the demo button
%------------------------
set(h.pB,'enable','off')

% Make sure that Demo window doesn't get deleted by demo scripts
%---------------------------------------------------------------
h.showH = get(0,'ShowHiddenHandles');
PutH( h );

%---------------------------------------------------------------------------
%   Set the list box string
%---------------------------------------------------------------------------
function fileName = GetFileName

h        = GetH;
fileName = HierarchicalListPlugIn( 'get selection', h.tL );

%---------------------------------------------------------------------------
%   Select a file
%   The demo header must be encapsulated by dash lines.
%   It may also be started with a cell command (%%).
%---------------------------------------------------------------------------
function SelectFile

h = GetH;

fileName = HierarchicalListPlugIn( 'get selection', h.tL );

if( fileName(1:1) ~= '+' & fileName(1:1) ~= '-' )
  if( ~isempty(fileName) )
    c = cd;
    s = which(fileName);
    if( ~isempty(s) )
      cd( fileparts(s) );
      [fid, message] = fopen( fileName, 'r+' );
      cd( c );
    else
      return;
    end
  end

  if( fid > 0 )
    s   = char(fread(fid))';
    k0  = findstr('%%',s(1:10)); % title of a published script
    kF  = findstr('%%',s(11:end))+10; % cell break before copyright
    k   = findstr('%-------------',s);
    if isempty(k) && isempty(kF)
      warndlg('Sorry, this demo header can not be read. Add a separator line.','DemoPSS');
      fclose(fid);
      return;
    end
     
    if isempty(k0)
      s   = s( (k(1)+12):(k(2)-1) );
    else
      if ~isempty(kF)
        s   = s( (k0(1)+1):(kF(1)-1) );
      else
        s   = s( (k0(1)+1):(k(1)-1) );
      end
    end
    k   = findstr('%',s);
    s   = s((k(1)):length(s));
    k   = findstr('%',s);
    for j = k
      s(k) = ' ';
    end
    % JBM   The following function does not work properly for Windows
    %       Removing the call still enables header lines to be shown in
    %       the DemoPSS GUI for both Windows and Mac platforms for Matlab
    %       R2008b and later.
    %s = FixLineEndings(s);
    set( h.tE,'string',sprintf('\n%s',s));
    set( h.pB,'enable','on');
    fclose(fid);
  end
end

%---------------------------------------------------------------------------
%   Get the data structure stored in the figure window
%---------------------------------------------------------------------------
function h = GetH

figH = findobj( 'tag', 'PSS Demo' );
h    = [];
if ~isempty(figH)
  h = get( figH, 'UserData' );
end

%---------------------------------------------------------------------------
%   Put the data structure into the user data
%---------------------------------------------------------------------------
function PutH( h )

set( h.fig, 'UserData', h );

%---------------------------------------------------------------------------
%   Create a callback string
%---------------------------------------------------------------------------
function c = CreateCallback( action )

c = ['DemoPSS( ''' action ''' )'];

%---------------------------------------------------------------------------
%   Get the data for the hierarchical menu
%---------------------------------------------------------------------------
function hD = GetHierarchicalData

s = which('DemoPSS','-all');

for i = 1:length(s)
  p = fileparts(s{i});

  f = GetFileNames( {}, p );

  % Delete path up to Demos:
  %-------------------------
  k = findstr( 'demos', lower(f{1}) );
  for j = 1:length(f)
    %f{j} = f{j}((k(1)+6):end);
  end

  j = 0;
  t = {};
  for k = 1:length(f)
    if( isempty(findstr( 'DemoPSS.m', f{k} )) )
      j    = j + 1;
      tTemp = StringToTokens( f{k}, filesep, 1 );
      t{j}  = tTemp([end-3 end-1 end]);
    end
  end

  d = {};
  for j = 1:length(t)
    d{j} = fullfile( t{j}{end-1}, t{j}{end} );
    for k = (length(t{j})-2):-1:1
      d{j} = fullfile( t{j}{k}, d{j} );
    end
  end

  if( i == 1 )
    dd = d;
  else
    dd = {dd{:} d{:}};
  end
end

hD = GetLineage( [], dd, 0 );

%-------------------------------------------------------------------------------
%   Get the lineage recursively
%-------------------------------------------------------------------------------
function h = GetLineage( h, d, parent )

% Find the highest level directory
%---------------------------------
for j = 1:length(d)
  i    = min(findstr(filesep,d{j})) - 1;
  p{j} = d{j}(1:i);
end

% Find all families
%------------------
m = 1;
l = length(d);
while( m <= l )
  k                  = strmatch( p{m}, {p{m:end}}, 'exact' )';
  f                  = {d{k+m-1}};
  m                  = m + length(k);
  q                  = length(h) + 1;
  j                  = findstr(filesep,f{1});
  jMin               = min(j);
  h(q).name          = f{1}(1:(jMin-1));
  h(q).parent        = parent;
  h(q).child         = [];

  if( parent > 0 )
    h(parent).child  = [h(parent).child q];
  end

  % If this is not the end of the path call GetLineage again
  %---------------------------------------------------------
  if( length(j) > 1 )
	j = min(j);
    for i = 1:length(f)
	  f{i} = f{i}((j+1):end);
    end
    h = GetLineage( h, f, q );
  else % These are the files in the final directory
	for i = 1:length(f)
	  [dC,nN,eE]      = fileparts(f{i});
	  h(q+i).name     = [nN eE];
	  h(q+i).parent   = q;
	  h(q+i).child    = [];
	  h(q  ).child    = [h(q).child q+i];
    end
  end
end

%---------------------------------------------------------------------------
%   Recursive function
%---------------------------------------------------------------------------
function f = GetFileNames( f, p )

s = dir( p );

for k = 1:length(s)
  if ~strcmp( s(k).name(1), '.' )
    if( s(k).isdir )
      f = GetFileNames( f, fullfile( p, s(k).name, '') );

    elseif( strcmp( s(k).name((end-1):end), '.m' ) & ~strcmp( s(k).name, 'Contents.m' ) )
      fN   = fullfile( p, s(k).name );
      n    = length(f) + 1;
      f{n} = fN;
    end
  end
end

%---------------------------------------------------------------------------
%   Clear plots
%---------------------------------------------------------------------------
function ClearPlots

figH = [findobj( 'tag', 'Plot2D' ); findobj( 'tag', 'PlotPSS' )];

for k = 1:length(figH)
  close( figH(k) );
end

% close additional figures
figH = findobj('type','figure');
for k = 1:length(figH)
  if ~strcmp(get(figH(k),'tag') , 'PSS Demo')
    close(figH(k))
  end
end


%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2019-04-29 15:51:39 -0400 (Mon, 29 Apr 2019) $
% $Revision: 48725 $
