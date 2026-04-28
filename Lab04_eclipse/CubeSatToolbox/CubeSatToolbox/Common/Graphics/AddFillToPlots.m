function AddFillToPlots(time,data,h,colors,alpha)

%% Find mode changes in data and draw as filled sections on existing plots.
%
% Time and data must be the same size. diff will be used to find the points
% where the value of data changes. Each segment will then be assigned a
% background color from colors. The 'auto' colors mode used the axes color
% order property. If a figure handle is not specified the current figure is
% used.
%   
% Type AddFillToPlots for a demo.
%--------------------------------------------------------------------------
%   Form:
%   AddFillToPlots(time,data,h,colors,alpha)
%--------------------------------------------------------------------------
%
%   -------
%   Inputs:
%   -------
%   time      (1,n)            Time axis data (the same for all subplots)
%   data      (1,n)            Data containing the mode changes
%   h         (1,1)            Figure handle with plots
%   colors    (n,3) or 'auto'  Colors for fill patches
%   alpha     (1,1)            facealpha property for the patch, in range [0 1]
%
%   --------
%   Outputs:
%   --------
%   None.
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2007 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%   Since version 11.
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin<1 )

    time = linspace(0,20);
    data = zeros(size(time));
    data(time>3)=1;
    data(time>6)=2;
    data(time>9)=3;
    data(time>12)=1;
    data(time>15)=3;

    x = sin(time);
    y = cos(time);

    Plot2D( time, [x;y], 'Time', {'x','y'}, 'Example Plot' );
    AddFillToPlots(time,data,gcf,'auto',.5);
    return
  
end
  

% Skipped inputs
%---------------
if nargin < 5
    alpha = [];
end

if nargin < 4
    colors = [];
end

if nargin < 3
    h = [];
end

% Defaults for any empty inputs
%------------------------------
if isempty(h)
    h = gcf;
end

if isempty(alpha)
    alpha = 0.5;
end

if isempty(colors)
    colors = [1 1 1; 0.9 0.9 0.9];
end

if (ischar(colors) && strcmp(colors,'auto'))
    colors = get(gca,'colororder');
end

% Find the subplots in the figure
%--------------------------------
hAll = h;

for figIndex=1:length(hAll)
    h = hAll(figIndex);
    kids = get(h,'children');
    hAxes = [];
    
    for k = 1:length(kids)
        
        if strcmp(get(kids(k),'type'),'axes') && strcmp(get(kids(k),'visible'),'on')
            hAxes(end+1) = kids(k);
        end
    end
  
    % Compute the mode changes
    %-------------------------
    [changes,kk] = find( diff(data) );
    nModes = length(kk)+1;
    tE = cell(1,nModes);
    kStart = [1 kk+1];
    kEnd = [kk length(data)];
    
    for k = 1:nModes
        tE{k} = time(kStart(k):kEnd(k));
    end
    
    xE = 1:nModes;
  
    % Plotting
    %---------
    for k = 1:length(hAxes)
    axes(hAxes(k));
    
        if( ~strcmp(get(hAxes(k),'tag'),'legend') )
            hold on;
            axLim = axis;
            yMin = axLim(3) + 0.01*(axLim(4)-axLim(3));
            yMax = axLim(4) - 0.01*(axLim(4)-axLim(3));
        
            for j=1:nModes
                kColor = rem(j-1,size(colors,1))+1;
                times = tE{j};
                xMin = times(1);
                xMax = times(end);
                if (xMin==axLim(1))
                  xMin = xMin + 0.01*(axLim(2)-axLim(1));
                end
                if (xMax==axLim(2))
                  xMax = xMax - 0.01*(axLim(2)-axLim(1));
                end
                fill([xMin xMax xMax xMin],...
                [yMin,yMin,yMax,yMax],...
                colors(kColor,:),'edgecolor','none','facealpha',alpha);
            end
      
            % reorder children
            %-----------------
            babes = get(hAxes(k),'children');
            set(hAxes(k),'children',[babes(end); babes(1:end-1)])
            hold off;
        end
    end
end

%--------------------------------------
% $Date: 2019-12-27 15:51:53 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50729 $
