function [a, e] = RPRA2AE( rP, rA )

%% Converts perigee and apogee to semi-major axis and eccentricity
%--------------------------------------------------------------------------
%   Form:
%   [a, e] = RPRA2AE( rP, rA )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   rP              (1,1) Perigee
%   rA              (1,1) Apogee
%
%   -------
%   Outputs
%   -------
%   a               (1,1) Semi-major axis
%   e               (1,1) Eccentricity
%
%--------------------------------------------------------------------------
%	  References:	  Bate, R.R., et. al. Fundamentals of Astrodynamics,
%                 pp. 70-71.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993-2000 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

gamma = rP/rA;

e     = (1-gamma)/(1 + gamma);

a     = 0.5*(rA + rP);


%--------------------------------------
% $Date: 2020-04-24 23:47:44 -0400 (Fri, 24 Apr 2020) $
% $Revision: 51969 $
