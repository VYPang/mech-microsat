function [r, lambda, theta] = RSHMoon( nH, lambda, theta, s, c )

%% Generates a topographic map of the moon using spherical harmonics. 
%
%   Type RSHMoon for a demo.
%
%   This uses Clementine data. The highest harmonic is 72. 
%
%   If s and c are not entered it will load the lunar surface coefficients
%   each time is called. You can load the coefficients yourself using
%
%     [s,c] = LoadLunarTopography( nH );
%
%   Since version 2.
%--------------------------------------------------------------------------
%   Form:
%   [r, lambda, theta] = RSHMoon( nH, lambda, theta, s, c )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   nH            (1,1)  Highest harmonic 
%   lambda        (j)    Equatorial angle
%   theta         (i)    Angle from pole
%   s             (:,:)  Normalized sine coefficients
%   c             (:,:)  Normalized cosine coefficients
%
%   -------
%   Outputs
%   -------
%   r             (i,j)  Radius
%   lambda        (j)    Equatorial angle
%   theta         (i)    Angle from pole
%
%--------------------------------------------------------------------------
%   Reference: Smith, D. E., Zuber, M. T., Neumann, G. A., "Topography of the
%              Moon from the Clementine lidar", Journal of Geophysical
%              Research, Vol. 102, No. E1, pp. 1591-1611, January 25, 1997.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1996 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

% Constants
%----------
nHMax   = 72;
rSphere = 1738000; % Radius of moon in meters

% Check the inputs
%-----------------
if( nargin < 1 )
  nH = [];
end

if( nargin < 2 )
  lambda = [];
end

if( nargin < 3 )
  theta = [];
end

if( nargin < 4 )
  s = [];
end

% Defaults
%---------
if( isempty(nH) )
  nH = nHMax;
end

if( isempty(lambda) )
  nDiv   = 100;
  lambda = linspace(0,2*pi*(1-1/nDiv),nDiv);
end

if( isempty(theta) )
  theta = linspace(0,pi,100);
end

% Check the data validity
%------------------------
if ( nH > nHMax ),
  error('PSS:RSHMoon:error','Highest harmonic is %2i',nHMax);
end

% Add 1 because the coefficients start at 0
%------------------------------------------
nH = nH + 1;

% Load the topography file
%-------------------------
if( isempty(s) )
  [s,c] = LoadLunarTopography( nH-1 );
end

% Set up the arrays
%------------------
lTheta  = length( theta );
lLambda = length( lambda );

r       = zeros( lTheta, lLambda ); 

% Spherical harmonic
%-------------------
for i = 1:lTheta

  % The zonal harmonics
  %-------------------
  cTheta = cos( theta(i) );

  % PAL returns p(n+1,m+1)
  %-----------------------
  p    = PAL( nH-1, nH-1, cTheta );

  for k = 1:lLambda
  
    % sin(m*lambda), cos(m*lambda)
    %-----------------------------
    [sL,cL] = SCHarm( lambda(k), nH-1 ); % Harmonics 1 through nH
    sL      = DupVect([0 sL],nH);        % Add zeroeth harmonics
    cL      = DupVect([1 cL],nH);	
    r(i,k)  = sum(sum(p.*(c.*cL + s.*sL)));
  end
  
end

% Default output
%---------------
if( nargout == 0 )  
  hFig = Mesh2(lambda,theta,r-rSphere,'\lambda (rad)','\theta (rad)','Delta Radius (m)','Lunar Topography');
	Watermark('Princeton Satellite Systems',hFig);
  rotate3d on
  clear r
end


%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 14:11:01 -0400 (Thu, 11 May 2017) $
% $Revision: 44563 $


