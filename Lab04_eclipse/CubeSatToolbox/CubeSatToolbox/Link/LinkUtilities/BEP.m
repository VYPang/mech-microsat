function [bEP, eOverN] = BEP( type, bitRate, cOverN )

%% Computes the bit error probability given C/N and the bit rate.
%   Five types of modulation, 'BPSK' 'QPSK' 'DE-BPSK' 'DE-QPSK' 'D-BPSK'
%   are available.
%
%   Type BEP for a demo of a 1 MB/s channel.
%
%--------------------------------------------------------------------------
%   Form:
%   bEP = BEP( type, bitRate, cOverN )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   type    (1,:)   Modulations: 'BPSK' 'QPSK' 'DE-BPSK' 'DE-QPSK' 'D-BPSK'
%   bitRate	(1,1)   Bit rate (bps)
%   cOverNo	(1,:)   (C/N)T (dB) 
%                        
%   -------
%   Outputs
%   -------
%   bEP     (1,:)   Bit error probability
%   eOverN	(1,:)   Energy per bit (dB)
%                         
%--------------------------------------------------------------------------
%   References:	Maral, G. and M. Bousquet, "Satellite Communications 
%               Systems Third Edition", Wiley, 1993, p. 125.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2004 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin == 0 )
  type    = {'BPSK' 'QPSK' 'DE-BPSK' 'DE-QPSK' 'D-BPSK'};
  eOverN  = linspace(4,13);
  bitRate	= 1e6;
  cOverN  = 10*log10((10.^(0.1*eOverN))*bitRate);
  b       = zeros(length(type),100);
  for k = 1:length(type)
    [b(k,:), eOverN] = BEP( type{k}, bitRate, cOverN );
  end
  Plot2D( eOverN, b, 'E/N (dB)','BEP', 'BEP', 'ylog' );
  legend(char(type))
  return;
end

eOverN = (10.^(0.1*cOverN))/bitRate;

switch type
  case {'BPSK', 'QPSK'}
    bEP = 0.5*erfc(sqrt(eOverN));
  
  case {'DE-BPSK' 'DE-QPSK'}
    bEP = erfc(sqrt(eOverN));
    
  case 'D-BPSK'
    bEP = 0.5*exp(-eOverN);
    
  otherwise
    error([type ' is not an available modulation']);
end

% Convert to dB for output and plotting
%--------------------------------------
eOverN = 10*log10(eOverN);

% Plot if there are no outputs
%-----------------------------
if( nargout == 0 )
  Plot2D( eOverN, bEP, 'E/N (dB)','BEP', 'BEPt' );
  clear bEP
end

%--------------------------------------
% $Date: 2019-09-05 16:53:53 -0400 (Thu, 05 Sep 2019) $
% $Revision: 49723 $
