function xT = CoordinateTransform( from, to, x, jD )

%% Transform between selected coordinate frames and representations.
% The frames are:
%
% ECI      Earth centered inertial
% ECR/EF   Earth fixed
% LLR      Geodetic latitude, longitude and altitude
%
%--------------------------------------------------------------------------
%   Form:
%   x = CoordinateTransform( from, to, x, jD )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   from      (1,:)   From (ECI, EF/ECR, LLR)
%   to        (1,:)   To (ECI, EF/ECR, LLR)
%   x         (3,:)   Vectors
%   jD        (3,1)   Julian date
%
%   -------
%   Outputs
%   -------
%   xT        (3,:)   Vectors transformed
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2000 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------

% Check for input errors
%-----------------------
t  = {'ecr' 'ef' 'eci' 'llr'};
k  = strmatch( lower(from), t );
if( isempty(k) )
  error(['from ' from 'is not an available frame.']);
end

k  = strmatch( lower(to), t );
if( isempty(k) )
  error(['to ' to 'is not an available frame.']);
end

% Matrix from ECI to EF
%----------------------
if exist('TruEarth')
  m  = TruEarth( JD2T(jD) );
else
  m = ECIToEF( JD2T(jD) );
end

switch lower(from)
  case 'eci'
	switch lower(to)
	  case 'eci'
	    xT = x;
		
	  case {'ecr' 'ef'}
	    xT = m*x;
		
      case 'llr'
		xT = EFToLatLonAlt( m*x );
    end
  
  case {'ecr' 'ef' }
	switch lower(to)
	  case 'eci'
		xT = m'*x;
		
	  case {'ecr' 'ef'}
        xT = x;
		
      case 'llr'
		xT = EFToLatLonAlt( m'*x );
    end
  case 'llr'
	switch lower(to)
	  case 'eci'
		xT = m'*LatLonAltToEF( x );
		
	  case {'ecr' 'ef'}
		xT = LatLonAltToEF( x );
		
      case 'llr'
	    xT = x;
		
    end
 end	

%--------------------------------------
% $Date: 2020-04-27 15:36:14 -0400 (Mon, 27 Apr 2020) $
% $Revision: 51998 $
