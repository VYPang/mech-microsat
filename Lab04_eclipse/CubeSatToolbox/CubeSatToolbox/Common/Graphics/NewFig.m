function h = NewFig( x, varargin )

%% Creates a new figure.
% Sets the default axes font size to 12. Applies the global fontSizeIncrease
% in addition to the 12 pt, if defined. Tags the figure with 'PlotPSS'
% for use with DemoPSS.
%--------------------------------------------------------------------------
%   Form:
%   h = NewFig( x, varargin )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   x          (:)    Name for the figuref
%   varargin   {}     Parameter pairs to pass to figure()
%
%   -------
%   Outputs
%   -------
%   h                 Handle
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1995, 2015 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

global fontSizeIncrease

h = figure(varargin{:});
if( isempty(fontSizeIncrease) )
   fontSizeIncrease=0;
end
set(h,'tag','PlotPSS','defaultaxesfontsize',12+fontSizeIncrease);

if( nargin > 0 )
  set(h,'Name',x);
end

if( nargout < 1 )
  clear h
end


%--------------------------------------
% $Date: 2017-05-01 16:57:45 -0400 (Mon, 01 May 2017) $
% $Revision: 44443 $
