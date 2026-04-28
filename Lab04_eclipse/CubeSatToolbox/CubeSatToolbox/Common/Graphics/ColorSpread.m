function colors = ColorSpread( n, map )

%% Produce a set of 3-element RGB colors that spread across the colormap.
% If a map is not specified it will grab the default figure color map.
%--------------------------------------------------------------------------
%   Form:
%   colors = ColorSpread( n, map )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   n             (1,1)    Number of colors to produce
%   map           (:,3)    Colormap, optional
%
%   -------
%   Outputs
%   -------
%   colors        (n,3)    n rows of colors
%
%--------------------------------------------------------------------------
%   See also AssignColors
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2009 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 8.
%   2017.1 - add an optional colormap input and a demo
%--------------------------------------------------------------------------

if nargin == 0
  % Demo
  n = 20;
  ColorSpread( n );
end

if (nargin<2 || isempty(map))
  map = get(0,'defaultfigurecolormap');
end
nCM = size(map,1);
colors = zeros(n,3);
for i=1:n
   row = floor(rem(i*(nCM-1)/n,nCM))+1;
   colors(i,:) = map(row,:);
end

if nargout == 0
  y = linspace(0,2*pi,n);
  NewFig('ColorSpread Demo'); hold on;
  for k = 1:n
    plot(y,k*sin(y),'color',colors(k,:));
  end
  grid on
  clear colors
end


%--------------------------------------
% $Date: 2020-04-25 12:36:39 -0400 (Sat, 25 Apr 2020) $
% $Revision: 51970 $
