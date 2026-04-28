function x = EditScroll( action, modifier, hFig, position )

%% Implement a scrollable edit window
%   tag = EditScroll( 'initialize', text, hFig, [10 10 200 100] )
%--------------------------------------------------------------------------
%   Form:
%   x = EditScroll( action, modifier, hFig, position )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   action    (1,:)    Action to perform
%   modifier  (1,:)    Modifier to the action
%   hFig      (1,1)    Figure handle
%   position  (1,4)    [left, bottom, width, height]
%
%   -------
%   Outputs
%   -------
%   x         (:,:)    The text
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1999 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------

% Input processing
%-----------------
if( nargin < 1 )
  action = [];
end

if( nargin < 2 )
  modifier = [];
end

if( nargin < 3 )
  hFig = [];
end

if( nargin < 4 )
  position = [];
end

% Defaults
%---------
if( isempty(action) )
  action = 'initialize';
end

if( isempty(position) )
  position = [0 0 200 100];
end

switch action

  case 'initialize'

    fontSize  = 10;

    % Defaults
    %---------
    if( isempty(hFig) )
      hFig = figure('units','pixels','position',[200 200 200 101],'resize','off','name','scroll bar','numbertitle','off');
    end

    h.fig       = hFig;
    v           = {'parent',h.fig,'units','pixels','fontunits','pixels'};
    tag         = GetNewTag;
    hMatlab6Bug = uicontrol('visible','off'); % Added to fix a Matlab 6 bug
    h.frame     = uicontrol( v{:}, 'style', 'frame', 'position', position, 'string', 'editScrollGroup', 'tag', tag);
 
    pEdit      = position + [5 20 -25 -25];
    pVSlider   = [position(1) + position(3)-20 21 + position(2)               15 position(4)-27];
    pHSlider   = [5 + position(1)               4 + position(2) position(3) - 25 15];

    h.edit    = uicontrol( v{:}, 'style', 'edit', 'max', 2, 'string', modifier, 'position', pEdit,...
                          'callback',CreateCallbackString('edit',tag),'fontsize',fontSize,'horizontalalignment','left');
    h.text    = modifier;
    sM        = max([2,size(modifier,1)]);
    h.rows    = 1:sM;
    h.vSlider = uicontrol( v{:}, 'callback', CreateCallbackString('vScroll',tag),'style','slider','min',1,...
                          'max',sM,'value',sM,'position',pVSlider,'userdata',1);
    sH        =  max([2,size(modifier,2)]);
    h.hSlider = uicontrol( v{:}, 'callback', CreateCallbackString('hScroll',tag),'style','slider','min',1,...
                          'max',sH,'value',1,'position',pHSlider,'userdata',1);

    h.rows    = 1:sM;
    h.cols    = 1:sH;
    h.edited  = 0;
    x         = tag;
    PutH( h );

  case 'edit'
    h         = GetH( modifier );
    hString   = get( h.edit, 'string' );
    hTop      = h.text(1:(h.rows(1)-1),:);
     if( h.cols(1) > 1 )
      hSide = h.text(h.rows,1:(h.cols(1)-1));
    else
      hSide = '';
    end
    if( ~isempty(hSide) )
      h.text = strvcat( hTop, [hSide hString] );
    else
      h.text = strvcat( hTop, hString );
    end
    h.edited  = 1;
    SetEditText( h );

  case 'get'
    h      = GetH( modifier );
    x      = h.text;

  case 'set'
    h         = GetH( modifier );
    h.text    = hFig;
    sM        = max([2,size(hFig,1)]);
    sH        = max([2,size(hFig,2)]);
    h.rows    = 1:sM;
    h.cols    = 1:sH;
    set( h.edit, 'string', hFig );
    PutH( h );

  case 'vScroll'
    h      = GetH( modifier );
    oldVal = get( h.vSlider, 'userdata' );
    val    = get( h.vSlider, 'value' );
    if( abs(oldVal - val) > 1 )
      if( oldVal < val )
        val = val + 1;
      else
        val = val - 1;
      end
    end
    sliderMax = get( h.vSlider, 'max' );
    if( val > sliderMax )
      val = sliderMax;
    elseif( val < 1 )
      val = 1;
    end
    set( h.vSlider, 'value', val, 'userdata', val );
    SetEditText( h );

  case 'hScroll'
    h      = GetH( modifier );
    oldVal = get( h.hSlider, 'userdata' );
    val    = get( h.hSlider, 'value' );
    if( abs(oldVal - val) > 1 )
      if( oldVal < val )
        val = val + 1;
      else
        val = val - 1;
      end
    end
    sliderMax = get( h.hSlider, 'max' );
    if( val > sliderMax )
      val = sliderMax;
    elseif( val < 1 )
      val = 1;
    end
    set( h.hSlider, 'value', val, 'userdata', val );
    SetEditText( h );

end

%--------------------------------------------------------------------------
%   Get a new tag
%--------------------------------------------------------------------------
function tag = GetNewTag

t   = clock;
tag = ['editScrollGroup' num2str([t(5:6) 100*rand])];

%--------------------------------------------------------------------------
%   Get the data structure stored in the frame
%--------------------------------------------------------------------------
function h = GetH( tag )

figH = findobj( 'string', 'editScrollGroup', 'tag', tag );
h    = get( figH, 'UserData' );

%--------------------------------------------------------------------------
%   Put the data structure into the user data
%--------------------------------------------------------------------------
function PutH( h )

set( h.frame, 'UserData', h );

%--------------------------------------------------------------------------
%   Create a callback string for this tool
%--------------------------------------------------------------------------
function s = CreateCallbackString( action, modifier )

s = ['EditScroll( ''' action ''',''' modifier ''')'];

%--------------------------------------------------------------------------
%   Return a string matrix that fits in the text box
%--------------------------------------------------------------------------
function SetEditText( h )

nHeight = size( h.text, 1 );
nWidth  = size( h.text, 2 );
hOld    = get( h.hSlider, 'max' );
vOld    = get( h.vSlider, 'max' );
set( h.vSlider, 'max', max( [ 2 nHeight] ));
set( h.hSlider, 'max', max( [ 2  nWidth] ));

% Horizontal slider
%------------------
hVal    = max([ 1 round(get( h.hSlider, 'value' )*nWidth/hOld)]);
set( h.hSlider, 'value', hVal );

% Vertical slider
%----------------
vVal    = max([ 1 round( get( h.vSlider, 'value' )*nHeight/vOld )]);
set( h.vSlider, 'value', vVal );

% Replace the text
%-----------------
h.rows = ((nHeight-vVal+1):nHeight);
h.cols = (hVal:nWidth);
if( ~isempty(h.rows) && ~isempty(h.cols) )
  set( h.edit, 'string', h.text(h.rows,h.cols) );
end
PutH( h )

%--------------------------------------
% $Date: 2019-12-27 14:31:09 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50728 $
