function tA = TAntennaGround( tSky, aRain, tGround )

%% Compute the temperature of an antenna on the ground. 
%   Rain acts as an attenuator for the sky.
%
%   Type TAntennaGround for a demo. See also TSky and LossPrecipitation.
%--------------------------------------------------------------------------
%   Form:
%   tA = TAntennaGround( tSky, aRain, tGround )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   tSky          (1,1)  Ambient temperature of the sky
%   aRain         (1,1)  Rain Loss (dB)
%   tGround       (1,1)  Ambient temperature of the ground
%                        
%   -------
%   Outputs
%   -------
%   tA            (1,1)  Antenna noise temperature
%                        
%--------------------------------------------------------------------------
%  	References:	Maral, G. and M. Bousquet. (1998.) Satellite Communications
%               Systems. Wiley. p. 37.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2001 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

if( nargin == 0 )
  tSky  = TSky( 12, 10 );
  aRain = LossPrecipitation( 12, 'e', 0.01, 45, 0, 0, [40000;0;0], 0 );
  fprintf('------------- TAntennaGround Demo -------------\n')
  fprintf('Sky temperature           = %12.4f deg-K\n',tSky)
  fprintf('Rain loss                 = %12.4f dB\n',aRain)
  TAntennaGround( tSky, aRain )
  return
end

tM = 275;

if( nargin < 3 )
  tGround = 45;
end

aRain = 10^(0.1*aRain);
tA    = tSky/aRain + tM*(1 - 1/aRain) + tGround;

if( nargout == 0 )
  fprintf('Antenna noise temperature = %8.1f deg-K\n',tA)
  clear tA;
end


%--------------------------------------
% $Date: 2019-09-05 20:12:10 -0400 (Thu, 05 Sep 2019) $
% $Revision: 49726 $


