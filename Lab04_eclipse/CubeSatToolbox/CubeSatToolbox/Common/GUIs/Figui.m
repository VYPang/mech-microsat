function Figui( h, fs, pos )

%% User-interface to manage figure windows.
%--------------------------------------------------------------------------
%   Form:
%   Figui( h )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   h            (1,:)   Array of figure handles. Optional. If not
%                        provided, all current figure handles will be used.
%   fs           (1,1)   Font size to use for button text.
%   pos                  Position
%
%   -------
%   Outputs
%   -------
%   none
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2005 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

if( nargin<3 )
   pos = [];
end
if( nargin<2 )
   fs = 12; % default font size
end
if( ~nargin )
   h = [];
end
h0 = h;
if( isempty(h) )
   h = SortedHandles;
end
if( isempty(h) )
   disp('No figures exist.');
   return;
end

figH = findobj( allchild(0), 'flat', 'tag', 'Figui' );
if( ~isempty(figH) )   
  figuipos=get(figH,'position'); 
  close(figH), 
  h = SortedHandles;
  Figui(h,fs,figuipos);
  return;
end

h = h(ishandle(h));
k = length(h);

p      = get(0,'screensize');
bh     = 20;
bw     = 200;
maxBtnsPerCol = (p(4)-50)/bh;
cols = ceil( (k+2) / maxBtnsPerCol );

names = get(h,'name');
if( ~iscell(names) )
   dum = names;
   clear names;
   names{1} = dum;
end
dx     = 5;
dy     = 5;
width  = cols*bw + 2*dx + (cols-1)*dx;
if( cols == 1 )
   height = (k+3)*bh+2*dy;
else
   height = p(4)-50;
end

if( ~isempty(pos) )
   x = pos(1);
   y = pos(2)+pos(4)-height;
else
   x = 100;
   y = p(4)-height;
end

f = figure('Name','Figures','units','pixels','resize','off','tag','Figui',...
   'numbertitle','off','position',[x, y, width, height]);

props = {'style','pushbutton','parent',f,'units','pixels',...
   'fontsize',fs,'fontname','arial','horizontalalignment','left'};

fpos = get(f,'position');

% refresh...
%refreshCB = ['figuipos=get(gcf,''position''); disp(figuipos), close(gcf), ', mfilename,'([',num2str(h0(:)'),'],',num2str(fs),',figuipos); clear figuipos'];
uicontrol(props{:},'position',[dx, fpos(4)-dy-bh, bw, bh],...
   'string','Refresh','backgroundcolor','g','fontweight','bold',...
   'callback',@(hObject,callbackdata) RefreshCallback(h0,fs));

% cascade...
uicontrol(props{:},'position',[dx, fpos(4)-dy-2*bh, bw, bh],...
   'string','Cascade Figures','backgroundcolor','r','fontweight','bold',...
   'callback',@(hObject,callbackdata) SortFigs(h,250));

% help...
helpCB = @(hObject,callbackdata) HelpSystem( 'initialize', 'OnlineHelp', 'Figui' );
uicontrol(props{:},'position',[dx, fpos(4)-dy-3*bh, bw, bh],...
   'string','Help','backgroundcolor','b','fontweight','bold',...
   'callback',helpCB);

set(f,'menubar','none');   
drawnow;

% pushbutton for each figure 
count = 0;
col = 1;
xo = 0;
for i=1:k
   count = count + 1;
   if( cols>1 )
      if( col==1 )
         if( count > maxBtnsPerCol-2 )
            count = 0;
            col = col + 1;
            xo = xo+dx+bw;
            yo = bh*(maxBtnsPerCol-1);
         else
            yo = bh*(maxBtnsPerCol-count-2);
         end
      else
         if( count > maxBtnsPerCol )
            count = 0;
            col = col + 1;
            xo = xo+dx+bw;
            yo = bh*(maxBtnsPerCol-1);
         else
            yo = bh*(maxBtnsPerCol-count);
         end
      end
   else
      yo = (k-i)*bh;
   end
      
   % SJT use .Number field available in R2014b
   if isprop(h(i),'Number')
     figNum = h(i).Number;
   else
     figNum = h(i);
   end
   u(i) = uicontrol(props{:},'position',[xo+dx, yo+dy, bw, bh],...
      'string',sprintf('Fig %d: %s',figNum,names{i}),...
      'callback',@(hObject,callbackdata) figure(h(i)) );
   drawnow;
   align(u(i),'left','middle');
end


function RefreshCallback(h0,fs)

figuipos=get(gcf,'position'); 
%disp(figuipos), 
close(gcf),  
Figui(h0,fs,figuipos); 
clear figuipos


function h = SortedHandles

% Pre-2014b code:
% h = sort(findobj('type','figure'));

hs = findobj('type','figure');

if ~isempty(hs)
  if isnumeric(hs(1))
    h = sort(hs);
  else
    [y,k] = sort([hs(:).Number]);
    h = hs(k);
  end
else
  h = [];
end


%--------------------------------------
% $Date: 2019-12-24 00:15:38 -0500 (Tue, 24 Dec 2019) $
% $Revision: 50694 $

