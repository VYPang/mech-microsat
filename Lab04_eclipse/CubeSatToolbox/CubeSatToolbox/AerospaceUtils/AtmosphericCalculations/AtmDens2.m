function rhoOut = AtmDens2( h, varargin )

%% Computes the Earth's atmospheric density using scale heights.
% Valid from 0 to 1000 km.
%
% Type AtmDens2 for demo.
%
%--------------------------------------------------------------------------
%   Form:
%   rhoOut = AtmDens2( h )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   h            (1,:) Altitude (km)
%
%   -------
%   Outputs
%   -------
%   rhoOut       (1,:) Atmospheric Density (kg/m^3)
%
%--------------------------------------------------------------------------
%   References: Wertz, J.R., Spacecraft Attitude Determination and
%               Control, Kluwer, 1976, p. 820.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1994-2002 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
% Since version 1.
%--------------------------------------------------------------------------

rhoRef  = [1.225     3.899e-2  1.774e-2  8.279e-3  3.972e-3  1.995e-3...
           1.057e-3  5.821e-4  3.206e-4  1.718e-4  8.770e-5  4.178e-5...
           1.905e-5  8.337e-6  3.396e-6  1.343e-6  5.297e-7  9.661e-8...
           2.438e-8  8.484e-9  3.845e-9  2.070e-9  1.244e-9  5.464e-10...
           2.789e-10 7.248e-11 2.418e-11 9.158e-12 3.725e-12 1.585e-12...
           6.967e-13 1.454e-13 3.614e-14 1.170e-14 5.245e-15 3.019e-15];
		   
           
hRef    = [ 0, 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100, ...
            110 120 130 140 150 160, 180,...
            200 250 300 350 400 450 500, ...
            600 700 800 900 1000];
                  
lh      = length(hRef);
             
hScale  = (hRef(1:lh-1)-hRef(2:lh))./log(rhoRef(2:lh)./rhoRef(1:lh-1));
hScale  = [hScale hScale(length(hScale))];


if nargin > 0

  if( h <= 0 )
    rhoOut = rhoRef(1);
    return
  end

  rho = zeros(1,length(h));
  for i = 1:length(h)
    j  = find(hRef>h(i), 1 );
     if( ~isempty(j) )
       rho(i)        = rhoRef(j-1)*exp(-(h(i)-hRef(j-1))/hScale(j-1));
     else
       lh            = length(hScale);
       rho(i)        = rhoRef(lh)*exp(-(h(i)-hRef(lh))/hScale(lh));
     end
  end
end
     
if nargout == 0
  NewFig('Atmospheric Density');
  if nargin == 0
    semilogy(hRef,rhoRef)
  else
    semilogy(h,rho)
  end
  XLabelS('Altitude (km)')
  YLabelS('Density (kg/m^3)');
  TitleS('Atmospheric Density')
  grid
else
  [r,c] = size(h);
  if( r > c )
    rho = rho';
  end
  rhoOut = rho;
end

%--------------------------------------
% $Date: 2019-09-09 23:21:42 -0400 (Mon, 09 Sep 2019) $
% $Revision: 49752 $
