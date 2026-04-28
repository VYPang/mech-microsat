function tR = TReceiver( tA, lFRX, tF, tERX )

%% Compute the noise temperature of a receiver attached to an antenna. 
%   tA is the ambient temperature of the antenna and tERX is the receiver
%   noise temperature. tF is the feeder noise temperature. This function
%   combines them to compute the noise temperature at the input.
%--------------------------------------------------------------------------
%   Form:
%   tR = TReceiver( tA, lFRX, tF, tERX )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   tA            (1,1)  Antenna temperature (deg-K)
%   lFRX          (1,:)  Feeder loss (dB)
%   tF            (1,1)  Feeder temperature (deg-K)
%   tERX          (1,1)  Receiver temperature (deg-K)
%                        
%   -------
%   Outputs
%   -------
%   tR            (1,1)  Temperature at input (deg-K)
%                        
%--------------------------------------------------------------------------
%   References:	Maral, G. and M. Bousquet. (1998.) Satellite Communications
%               Systems. Wiley. pp. 17-18.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2001, 2008 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
  tA   = 50;
  tF   = 290;
  tERX = 50;
  lFRX = linspace(0,10);
  TReceiver( tA, lFRX, tF, tERX )
end

% Feeder loss
%------------
lFRX = 10.^(0.1*lFRX);

tR = tA./lFRX + tF*(1 - 1./lFRX) + tERX;

% Default output
%---------------
if( nargout < 1 )
  Plot2D( lFRX, tR, 'Loss (dB)', 'Noise (deg-K)', 'Receiver' )
  clear tR
end


%--------------------------------------
% $Date: 2019-09-05 20:12:10 -0400 (Thu, 05 Sep 2019) $
% $Revision: 49726 $
