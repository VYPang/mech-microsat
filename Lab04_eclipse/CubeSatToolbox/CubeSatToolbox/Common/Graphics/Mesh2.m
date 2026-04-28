function hFig = Mesh2( xCol, yRow, z, xLbl, yLbl, zLbl, figTitle )

%% Draws mesh plots with axis labels. 
% If either xCol or yRow are a scalar, draws a 2 dimensional plot. 
% Rows of z are y and columns are x. An example:
%
%   x = 1:10;
%   y = 1:20;
%   z = y'*x;
%   Mesh2(x,y,z,'X','Y','Z')
%
%--------------------------------------------------------------------------
%   Form:
%   hFig  = Mesh2( xCol, yRow, z, xLbl ,yLbl, zLbl, figTitle )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   xCol                Column Indices
%   yRow                Row indices
%   z                   Z values
%   xLbl                X label
%   yLbl                Y label
%   zLbl                Z label
%   title               figTitle
%
%   -------
%   Outputs
%   -------
%   hFig   (1,1) Figure handle
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1995, 2016 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%   2017.1 Added handle output
%--------------------------------------------------------------------------

if( nargin > 6 ) 
  hFig = NewFig(figTitle);
  set(hFig,'tag','PlotPSS');
elseif ( nargin > 5 )
  hFig = NewFig(zLbl);
  set(hFig,'tag','PlotPSS');
else
  hFig = NewFig;
  set(hFig,'tag','PlotPSS');
end

if( length(xCol) > 1 && length(yRow) > 1 )
  mesh(xCol,yRow,z);
  if( nargin > 3 ), XLabelS(xLbl); end;
  if( nargin > 4 ), YLabelS(yLbl); end;
  if( nargin > 5 ), ZLabelS(zLbl); end;
elseif( length(xCol) > 1 )
  plot(xCol,z)
  grid
  if( nargin > 3 ), XLabelS(xLbl); end;
  if( nargin > 5 ), YLabelS(zLbl); end;
elseif( length(yRow) > 1 )
  plot(yRow,z)
  grid
  if( nargin > 4 ), XLabelS(yLbl); end;
  if( nargin > 5 ), YLabelS(zLbl); end;
end


%--------------------------------------
% $Date: 2017-05-01 16:57:45 -0400 (Mon, 01 May 2017) $
% $Revision: 44443 $
