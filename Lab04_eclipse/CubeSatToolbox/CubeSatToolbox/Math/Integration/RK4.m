function x = RK4( Fun, x, h, t, varargin )

%% Fourth order Runge-Kutta. Called function is of the form:
%
% Fun(x,t,varargin)
%
% Accepts optional arguments that are passed through to Fun. Time is also
% optional.
% This version is streamlined and designed to take advantage of MATLAB's
% function handles feature (MATLAB versions 6 and up only). Passing a 
% string function name (version 5) will also work but is slower.
% 
%--------------------------------------------------------------------------
%   Form:
%   x = RK4( Fun, x, h, t, varargin )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   Fun                Function    Fun(x,{t,...})
%   x                  State (column vector)
%   h                  Independent variable step
%   t                  Current time
%   p1...              Optional arguments
%
%   -------
%   Outputs
%   -------
%   x                  Updated state
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993-1994, 2006 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

if( nargin < 4 )
  t = [];
end

ho2 = 0.5*h;

if ~isempty(t)
  k1  = feval( Fun, x, t, varargin{:} );
  k2  = feval( Fun, x + ho2*k1, t+ho2, varargin{:} );
  k3  = feval( Fun, x + ho2*k2, t+ho2, varargin{:} );
  k4  = feval( Fun, x + h*k3, t+h, varargin{:} );
else
  k1  = feval( Fun, x, varargin{:} );
  k2  = feval( Fun, x + ho2*k1, varargin{:} );
  k3  = feval( Fun, x + ho2*k2, varargin{:} );
  k4  = feval( Fun, x + h*k3, varargin{:} );
end

x   = x + h*(k1 + 2*(k2+k3) + k4)/6;


% PSS internal file version information
%--------------------------------------
% $Date: 2016-05-24 16:46:41 -0400 (Tue, 24 May 2016) $
% $Revision: 42526 $
