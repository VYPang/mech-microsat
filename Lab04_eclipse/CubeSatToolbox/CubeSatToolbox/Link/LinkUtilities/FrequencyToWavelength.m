function lambda = FrequencyToWavelength( f, c )

%% Converts frequency to wavelength.
%--------------------------------------------------------------------------
%   Form:
%   lambda = FrequencyToWavelength( f, c )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   f           (1,:)     Frequency (Hz)
%   c           (1,1)     Propagation speed (m/s)
%                        
%   -------
%   Outputs
%   -------
%   lambda		(1,:)     Wavelength (m)
%                         
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2003, 2008 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------

if( nargin < 2 )
  c = [];
end

if( nargin < 1 )
  f = logspace(6,15);
end

if( isempty(c) )
  c = 299793.458e3;
end

lambda = c./f;

if( nargout == 0 )
  Plot2D( f/1e9, lambda*1000.0, 'Frequency  (GHz)', 'Wavelength (mm)', 'Wavelength', 'log' );
  clear lambda
end


%--------------------------------------
% $Date: 2019-09-05 19:16:04 -0400 (Thu, 05 Sep 2019) $
% $Revision: 49724 $
