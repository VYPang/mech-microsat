function l = LossPolarization( psi )

%% Computes the polarization loss.
%
%   Type LossPolarization for a demo.
%
%   Loss is converted to a gain by making it negative.
%--------------------------------------------------------------------------
%   Form:
%   l = LossPolarization( psi )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   psi   (:)  Angle between transmit and receive planes (deg)
%
%   -------
%   Outputs
%   -------
%   l     (:)  Loss (dB)
%
%--------------------------------------------------------------------------
%   Reference:  Maral, G. and M. Bousquet. (1998.) Satellite Communications
%               Systems, Third Edition. John Wiley. p. 27.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2001 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

if( nargin < 1 )
  psi      = linspace(0,89);
  LossPolarization( psi );
  return
end

l = -20*log10(CosD(psi));

if( nargout == 0 )
  Plot2D( psi, l, 'Angle (deg)', 'Loss (dB)' );
  clear
end


%--------------------------------------
% $Date: 2020-03-16 11:18:13 -0400 (Mon, 16 Mar 2020) $
% $Revision: 51561 $
