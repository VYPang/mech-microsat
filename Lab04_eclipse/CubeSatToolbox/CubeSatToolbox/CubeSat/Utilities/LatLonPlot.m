function [lat2,lon2,p] = LatLonPlot( lat, lon, tol, varargin )

%% Plot latitude vs. longitude nicely
% The wrapped longitude will not create lines across the plot.
% Type LatLonPlot for a demo.
%--------------------------------------------------------------------------
%   Form:
%   [lat2,lon2,p] = LatLonPlot( lat, lon, tol, varargin )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   lat     (1,:)	Latitude vector (rad)
%   lon     (1,:)	Longitude vector (rad)
%   tol     (1,1)	Tolerance used for WrapSegments call. See WrapSegments
%   varargin (:)  Any additional inputs are treated as additional inputs
%                    to the plot command, as: plot(x,y,varargin)
%   
%   -------
%   Outputs
%   -------
%   lat2    (1,N)	Cell array of N segments of latitude vectors (rad)
%   lon2    (1,N)	Cell array of N segments of longitude vectors (rad)
%   p       (1,N) Pointers to plots
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2009 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 8.
%   2019.1 Added demo
%--------------------------------------------------------------------------

if( nargin < 1 )
  a = linspace(0,pi/2);
  NewFig('LatLonPlot')
  LatLonPlot( sin(a),cos(a) );
  return
end

if( nargin < 3 || isempty(tol) )
   tol = pi;
end

[lon2,w] = WrapSegments( lon, tol );
lat2 = cell(1,length(w));
p    = zeros(1,length(w));
for i=1:length(w)
   lat2{i} = lat(w{i});
   if( nargout==0 || nargout==3 )
     p(i) = plot(lon2{i},lat2{i},varargin{:});
   end
end

%--------------------------------------
% $Date: 2020-06-19 15:04:48 -0400 (Fri, 19 Jun 2020) $
% $Revision: 52850 $
