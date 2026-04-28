function dR = DataRateGain( power, d )

%% Computes communications sytems data rates
% This is similar to data rate except that you enter antenna gains.
%
% Type DataRateGain for a demo
%
%--------------------------------------------------------------------------
%   Form:
%   d  = DataRateGain
%   dR = DataRateGain( power, d )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   power       (1,:) Power transmit (W)
%   d           (.)   Data structure
%                     .fGHz         (1,1) Frequency (GHz)
%                     .range        (1,1) Range (km)
%                     .gainTransmit	(1,1) Transmit antenna gain (dB)
%                     .gainReceive	(1,1) Receiver antenna gain (dB)
%                     .tempS        (1,1) Receiver noise temperature (deg-K)
%                     .modulation   (1,:) 'BPSK' 'QPSK' 'DE-BPSK' 'DE-QPSK' 'D-BPSK'
%                     .sN           (1,1) Signal to noise ratio
%
%   -------
%   Outputs
%   -------
%   dR            (1,:) Data rate (bps)
%
%--------------------------------------------------------------------------
%   Reference: Bousquet, Maral, "Satellite Communications Systems", 
%              Third Ed., Wiley, 1998. p 130
%--------------------------------------------------------------------------
%  See also ModulationSpectralEfficiency, DataRate
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2020 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 2020.1
%--------------------------------------------------------------------------

% Demo
if( nargin < 1 )
  if( nargout == 1 )
    dR = DataStructure;
  else
    d     = DataStructure;
    power = logspace(0,3);
    DataRateGain( power, d );
  end
  return
end

lambda        = FrequencyToWavelength( d.fGHz*1e9 );
range         = d.range*1000; % Convert to meters
k             = 1.3806503e-23; % m^2 kg/ s^2 K

lossTransmit  = (lambda/(4*pi*range))^2;
gainTransmit  = DBSignalToPower( d.gainTransmit );
gainReceive   = DBSignalToPower( d.gainReceive  );


% Product of signal to noise ratio and bandwidth
f             = power*gainTransmit*lossTransmit*gainReceive/(k*d.tempS);
b             = f/d.sN;
dR            = ModulationSpectralEfficiency( d.modulation )*b;

if ( nargout == 0 )
  Plot2D(power,dR,'Power (W)', 'Data Rate (bps)', 'Data Rate','xlog');
  clear dR
end


%--------------------------------------------------------------------------
%   Default data structure
%--------------------------------------------------------------------------
function d = DataStructure

dG = AntennaGain;

gR = AntennaGain(dG,8.4);
d = struct('fGHz',8.4,'range',1000,'gainTransmit',1.5,'gainReceive',gR,'tempS',290,'modulation','qpsk', 'sN', 0.6);


%--------------------------------------------------------------------------
% $Date: 2020-05-26 13:52:35 -0400 (Tue, 26 May 2020) $
% $Revision: 52419 $
