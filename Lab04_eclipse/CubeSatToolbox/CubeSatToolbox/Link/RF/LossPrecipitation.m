function aRain = LossPrecipitation( f, zone, pTime, latitudeS, longitudeS, hS, rSC, tau )

%% Computes the link attenuation due to precipation.
%   The output is a loss in dB. This is a positive quantity. The negative
%   must be used to get the gain for a link equation. 
%   e.g. 10 dB loss = -10 dB gain.
%   This function only works in the northern hemisphere.
%   Type LossPrecipitation for a demo for the 'K' zone.
%--------------------------------------------------------------------------
%   Form:
%   aRain = LossPrecipitation( f, zone, pTime, latitudeS, longitudeS, hS, rSC, tau )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   f              (1,1)  Frequency (GHz)
%   zone           (1,1)  Climate zone (A-Q)
%   pTime          (1,1)  Precipation percentage of time
%   latitudeS      (1,1)  Latitude of ground station (deg)
%   longitudeS     (1,1)  Latitude of ground station (deg)
%   hS             (1,1)  Ground station height (km)
%   rSC            (3,1)  Spacecraft distance (km)
%   tau            (1,1)  Polarization tilt angle (deg)
%
%   -------
%   Outputs
%   -------
%   aRain          (1,1)  Link attenuation (dB)
%
%--------------------------------------------------------------------------
%   Reference:  Maral, G. and M. Bousquet. (1998.) Satellite Communications
%               Systems, Third Edition. John Wiley. pp. 47-57.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2001 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

if( nargin < 1 )
  pTime      = 0.01;
  zone       = 'K';
  latitudeS  = 45;
  longitudeS = 0;
  hS         = 1;
  rSC        = [6479;0;4000];
  tau        = 0;
  f          = linspace(2,15);
  LossPrecipitation( f, zone, pTime, latitudeS, longitudeS, hS, rSC, tau );
  return
end

rain = [  0.1  0.5  0.7  2.1  0.6  1.7  3  2  8   1.5   2   4   5  12  24;...
          0.8  2    2.8  4.5  2.4  4.5  7  4 13   4.2   7  11  15  34  49;...
          2    3    5    8    6    8   12 10 20  12    15  22  35  65  72;...
          5    6    9   13   12   15   20 18 28  23    33  40  65 105  96;...
          8   12   15   19   22   28   30 32 35  42    60  63  95 145 115;...
          14  21   26   29   41   54   45 55 45  70   105  95 140 200 142;...
          22  32   42   42   70   78   65 83 55 100   150 120 180 250 170];
		  
zone              = double(upper(zone)) - 64;
percentageOfTime	= [1 0.3 0.1 0.03 0.01 0.003 0.0001];

% Interpolate using logs
%-----------------------
pTime    = log10(pTime);
pLog     = log10(percentageOfTime);
r        = interp1( pLog, rain(:,zone), pTime );


rG      = LatLonAltToEF( [latitudeS*pi/180;longitudeS*pi/180; hS] );

E      = HorizonAngle( rG, rSC );


if( 0 <= latitudeS && latitudeS < 36 )
  hR = 3 + 0.028*latitudeS;
elseif( latitudeS >= 36 )
  hR = 4 - 0.075*(latitudeS - 36);
else
  error('Latitudes < 0 are not allowed');
end

if( E < 0 )
	error('E < 0 not allowed');
end

fS  = [1       2        4        6        7        8        10       12       15       20       25       30       35        40];
kHC = [3.87e-5 3.649e-5 2.199e-5 3.202e-6 7.542e-6 2.636e-6 3.949e-6 1.094e-5 4.339e-5 8.951e-5 8.779e-5 1.009e-4 1.304e-4];
kVC = [3.52e-5 3.222e-5 2.187e-5 3.041e-6 7.89e-6  2.102e-6 2.785e-6 7.718e-6 3.674e-5 3.674e-5 1.143e-4 1.075e-4 1.163e-4];

kHE = [1.9925  2.0775   2.4426   3.5181   3.0778   3.5834   3.4078   2.9977   2.4890   2.2473   2.2533   2.2124   2.1402];
kVE = [1.9710  2.0985   2.3780   3.4791   2.9892   3.6253   3.5032   3.0929   2.5167   2.2041   2.1424   2.1605   2.1383];

aHC = [0.1694  0.5249   1.0619   0.3585  -0.0862  -0.5263   -0.7451 -0.6501  -0.4402  -0.3921  -0.5052  -0.6274  -0.6898];
aVC = [0.1428  0.5049   1.0790   0.7021  -0.0345  -0.4747   -0.8083 -0.7430  -0.5042  -0.3612  -0.3789  -0.5527  -0.5863];

aHB = [0.9120  0.8050   0.4816   1.0290   1.4049   1.8023    2.0211  1.9186   1.6717   1.6092   1.7672   1.9477   2.0440];
aVB = [0.8800  0.7710   0.4254   0.7187   1.3411   1.7387    2.0723  2.0018   1.7210   1.5349   1.5596   1.8164   1.8683];

aRain = zeros(1,length(f));

for j = 1:length(f)
  k = find( f(j) <= fS , 1 ) - 1;

  kH = kHC(k)*f(j)^kHE(k);
  kV = kVC(k)*f(j)^kVE(k);
  aH = aHC(k)*log10(f(j)) + aHB(k);
  aV = aVC(k)*log10(f(j)) + aVB(k);

  cE     = cos( E );
  sE     = sin( E );

  lS     = (hR - hS)/sE;
  l0     = 35*exp(-0.015*r);

  rA     = 1/(1 + (lS/l0)*cE );

  lE     = rA*lS;

  cET    = cE^2*cos(2*tau*pi/180);

  k      = 0.5*(kH + kV       + (kH - kV)      *cET);
  alpha  = 0.5*(kH*aH + kV*aV + (kH*aH - kV*aV)*cET)/k;

  gammaR = k*r^alpha;

  aRain(j)  = gammaR*lE;
end


if( nargout == 0 )
  Plot2D( f, aRain, 'Frequency (GHz)', 'Loss (dB)', 'Precipitation Loss');
  clear aRain
end


%--------------------------------------
% $Date: 2019-09-05 20:12:10 -0400 (Thu, 05 Sep 2019) $
% $Revision: 49726 $

