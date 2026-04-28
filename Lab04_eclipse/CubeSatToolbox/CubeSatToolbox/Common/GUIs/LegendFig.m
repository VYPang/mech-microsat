function h = LegendFig( names, colors, figTitle )

%% Produce a new figure with just a legend of colors and names.
%
%--------------------------------------------------------------------------
%   Form:
%   h = LegendFig( names, colors, title )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   names         {1,n}    Cell array of names to go in the legend
%   colors        {1,n}    Cell array of 1-character colors 
%           -or-  (n,3)    n rows of 3-element color vectors 
%
%   figTitle      (1,:)    Title for new legend figure. Optional.
%
%   -------
%   Outputs
%   -------
%   h             (1,1)    Figure handle.
%
%   See also:  ColorSpread.m
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2009 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 8.
%--------------------------------------------------------------------------

if( nargin<3 )
   figTitle = 'Legend';
end

n = length(names);

h = figure('name',figTitle,'numbertitle','off','menubar','none','visible','off','resize','off');

pos = get(h,'position');

if( iscell(colors) && ischar(colors{1}) )
   
   if( length(colors)~=n )
      error('Inputs "names" and "colors" must have the same number of elements.')
   end
   
   for i=1:n
      bar(i,1,'facecolor',colors{i})
      hold on
   end
   
else
   
   [ncr,ncc] = size(colors);
   
   if( ncc==n & ncr~=n )
      % rotate to have n rows and 3 columns 
      colors = colors';
   end
   
   if(size(colors,1)~=n)
      error('Inputs "names" and "colors" must have the same number of elements.')
   end
   
   for i=1:n
      bar(i,1,'facecolor',colors(i,:))
      hold on
   end
   
end

set(gca,'position',[0 .95 .001 .001])
leg = legend(names{:},'Location','NorthEastOutside');
legPos = get(leg,'position');
width = (legPos(3)+.02)*pos(3);
height = (legPos(4)+.1)*pos(4);
set(h,'position',[pos(1)-width, pos(2), width, height])
set(h,'visible','on');


%--------------------------------------
% $Date: 2019-12-29 13:35:15 -0500 (Sun, 29 Dec 2019) $
% $Revision: 50749 $
