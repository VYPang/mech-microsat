function bEP = LinkOrbitAnalysis( r, jD, d )

%% Link analysis computing bit error probability along an orbit. 
%
% The orbit is the spaceraft position in km. Each orbit position must
% have a corresponding Julian day number. Modulations are 'BPSK' 'QPSK'
% 'DE-BPSK' 'DE-QPSK' 'D-BPSK' The output is the bit error probability as
% a function of the orbit position. This will be zero if the ground
% station is not visible. Assumes antenna is omni-directional.
%
% Note that the TSky model is limited to frequencies between 2.5 and 60
% GHz. If a frequency outside this is entered the closest endpoint is used.
%
% Type LinkOrbitAnalysis for a demo.
%
% Since version 8.
%--------------------------------------------------------------------------
%   Form:
%   bEP = LinkOrbitAnalysis( r, jD, d )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   r      (3,:) Orbit Earth Fixed (km)
%   jD     (1,:) Julian date (days)
%   d      (1,1) Comm data structure
%                .fGHz                 (1,1) Frequency (GHz)
%                .diameterReceive      (1,1) Receive antenna diameter (m)
%                .apertureEfficiency   (1,1) Aperture efficiency
%                .polarizationAngle    (1,1) Polarization angle (deg)
%                .attError             (1,1) Average attitude error (deg)
%                .latitude             (1,1) Ground station latitude (rad)
%                .longitude            (1,1) Ground station longitude (rad)
%                .altitude             (1,1) Ground station altitude (km)
%                .bitRate              (1,1) Bit rate (bps)
%                .ampAntennaLoss       (1,1) Antenna loss (dB)
%                .beamEdgeLoss         (1,1) Beam edge loss (dB)
%                .powerTransmit        (1,1) Transmit power (W)
%                .temperatureERX       (1,1) ERX temperature (deg-K)
%                .temperatureFeeder    (1,1) Feeder temperature (deg-K)
%                .lossFeeder           (1,1) Feeder loss (dB)
%                .modulation           (1,:) Modulation e.g. 'D-BPSK';
%                .horizonAngle         (1,1) Horizon angle cutoff (rad)
%                .gainTransmit         (1,1) Gain of satellite transmitter (dB)
%
%   -------
%   Outputs
%   -------
%   bEP      (1,:)  Bit error probability
%
%--------------------------------------------------------------------------
%   See also LatLonAltToEF, FrequencyToWavelength, DBSignalToPower, TSky,
%   TAntennaGround, TReceiver, GroundStationVisibility, BEP
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2009, 2014 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------


% Demo
%-----
if( nargin < 1 )
    disp('Link analysis for a spacecraft in an 800 km orbit');
    sMA                    = 800 + 6378.165;
    p                      = Period(sMA);
    n                      = 200;
    [r, ~, t]              = RVFromKepler([sMA pi/2 0 0 0 0],linspace(0,p,n));
    jD                     = Date2JD([2014 4 1 16 18 0])  + t/86400;
    d.fGHz                 = 4;
    d.diameterReceive      = 1;
    d.apertureEfficiency   = 0.55;
    d.polarizationAngle    = 3.0;
    d.attError             = 1;
    d.latitude             =  40.37*pi/180; 
    d.longitude            = -74.67*pi/180;
    d.altitude             = 0.5;
    d.bitRate              = 1e5;
    d.ampAntennaLoss       = 1; % dB
    d.beamEdgeLoss         = 3; % dB
    d.powerTransmit        = 1; % W
    d.temperatureERX       = 75; % deg-K
    d.temperatureFeeder    = 290; % deg-K
    d.lossFeeder           = 0.5; % dB
    d.modulation           = 'D-BPSK';
    d.horizonAngle         = 5*pi/180;
    d.gainTransmit         = 1.5;
    LinkOrbitAnalysis( r, jD, d );
    clear d;
    return;
end

% Constants
%----------
kBoltz          = 1.38e-23; % Boltzmann's constant
kmToM           = 1e3;

% Find the ground location
%-------------------------
rGS             = LatLonAltToEF( [d.latitude;d.longitude;d.altitude], [], [] );

n               = size(r,2);

fHz             = d.fGHz*1e9;
lambda          = FrequencyToWavelength( fHz );

if( isfield(d,'gainTransmit') )
  gainTransmit    = DBSignalToPower( d.gainTransmit );
else
  gainTransmit    = DBSignalToPower( 1.5 );
end

if( isfield(d,'gainReceive') )
  gainReceive = d.gainReceive;
else
  gainReceive     = d.apertureEfficiency*(pi*d.diameterReceive/lambda)^2;
end
atmLoss         = DBSignalToPower( LossAtmosphericGas( d.fGHz , 10 ) );
polLoss         = DBSignalToPower( LossPolarization( d.polarizationAngle ) );
lFTX            = DBSignalToPower(d.ampAntennaLoss); % Loss between transmitter and amplifier and antenna
lT              = DBSignalToPower(d.beamEdgeLoss); % Beam edge loss
eIRP            = d.powerTransmit*gainTransmit/(lT*lFTX);
if (d.fGHz<2.5)
  tSky = TSky( 2.5, 45 );
elseif (d.fGHz>60)
  tSky = TSky( 60, 45 );
else
  tSky = TSky( d.fGHz, 45 );
end
feederLoss      = DBSignalToPower(d.lossFeeder);
tAntenna        = TAntennaGround( tSky, 0 );

tD              = TReceiver( tAntenna, d.lossFeeder, d.temperatureERX, d.temperatureFeeder );
gOverT          = gainReceive/feederLoss/tD;
bEP             = zeros(1,n);
visible         = zeros(1,n);

for k = 1:n
    g               = ECIToEF( JD2T( jD(k) ) );
    rGSECI          = g'*rGS;
    dR              = r(:,k) - rGSECI;
    range           = Mag(dR);
    rangeLoss       = (4*pi*range*kmToM/lambda)^2;
    lD              = atmLoss*polLoss*rangeLoss;
    cOverN          = eIRP*(1/lD)*gOverT/kBoltz;
    visible(k)      = GroundStationVisibility( rGS, jD(k), r(:,k), d.horizonAngle );
    if( visible(k) )
        bEP(k) = BEP( d.modulation, d.bitRate, 10*log10(cOverN) );
    end
end

% Default output
%---------------
if( nargout == 0 )
  GroundStationVisibility(rGS,jD,r,d.horizonAngle);
  jD = jD - jD(1);
  [tPlot,tLabl] = TimeLabl(jD*86400);
  Plot2D(tPlot,bEP,tLabl,'BEP','Bit Error over Orbit')
  if( visible(1) == 1 )
      rng(1,1) = 1;
  end
  i = 0;
  for k = 2:n
      if( visible(k) ~= visible(k-1) )
          if( visible(k) == 0 )
              rng(i,2) = k-1;
          else
              i = i + 1;
              rng(i,1) = k;
          end
      end
  end

  if( rng(end,2) == 0 ) 
      rng(end,2) = n;
  end

  NewFig('Bit Error Probability');

  m = size(rng,1);

  hold on

  for k = 1:m
      i = rng(k,1):rng(k,2);
      semilogy( tPlot(i), bEP(i) );
      set(gca,'yscale','log');
  end

  XLabelS(tLabl)
  YLabelS( 'BEP')

  % Fix units
  %----------
  if(     d.bitRate >= 1e9 )
      q  = 1e9;
      qL ='Gb';
  elseif( d.bitRate >= 1e6 )
      q  = 1e6;
      qL ='Mb';
  elseif( d.bitRate >= 1e3 )
      q  = 1e3;
      qL ='Kb';
  end
  TitleS(sprintf('Data Rate: %10.2f %s/s', d.bitRate/q, qL));
  grid

  clear bEP;
end


%--------------------------------------
% $Date: 2019-09-06 11:24:45 -0400 (Fri, 06 Sep 2019) $
% $Revision: 49727 $
