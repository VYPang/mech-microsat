function dR = DataRateOrbit( r, rGS, power, jD, d )

%% Computes data rate over an orbit.
%
% Data rate is a function of range.
%
% Type DataRateOrbit for a demo.
%
%--------------------------------------------------------------------------
%   Form:
%   d  = DataRateOrbit
%   dR = DataRateOrbit( r, rGS, power, d )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   r           (3,:) Vector of orbit positions in ECI (km)
%   rGS         (3,1) Position of ground station in ECEF (km)
%   power       (1,:) Power transmit (W)
%   jD          (1,:) Julian date
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
%   dR          (1,:) Data rate (bps) 
%                        
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
    dR        = DataRateGain;
  else
    d         = DataRateGain;
    power     = 10;
    [el,jD0]  = ISSOrbit;
    t         = linspace(0,93*16*60,10000);
    r         = RVOrbGen(el,t);
    rD        = pi/180;
    rGS       = LatLonToR(33.9191667*rD,-118.4155556*rD); % El Segundo, CA
    jD        = jD0 + t/86400;
    DataRateOrbit( r, rGS, power, jD, d );
  end
  return
end

n   = length(jD);
dR  = zeros(1,n);
rng = zeros(1,n);
T   = JD2T(jD);

for k = 1:n
  rGSECI  = ECIToEF( T(k) )'*rGS;
  uSlant  = Unit(r(:,k)-rGSECI);
  d.range = Mag(rGSECI-r(:,k));
  angle   = acos(uSlant'*Unit(rGSECI));
  if( angle < pi/2 )
    dR(k)	= DataRateGain( power, d );
  end
  rng(k)  = d.range;
end

if( nargout == 0 )
  Plot2D(jD-jD(1),[dR;rng],'Days',{'Data Rate (bps)' 'Range (km)'},...
    'Data Rate in Orbit');
  clear dR
end


%--------------------------------------
% $Date: 2020-06-22 11:20:11 -0400 (Mon, 22 Jun 2020) $
% $Revision: 52861 $
