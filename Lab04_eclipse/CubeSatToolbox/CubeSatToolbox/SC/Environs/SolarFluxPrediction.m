function [aP, f, fHat, fHat400] = SolarFluxPrediction( jD, timing )

%% Computes the solar flux prediction based on Julian date. 
%   This function requires the mat file "SolarFluxPredictions". Returns
%   error bars on the daily 10.7 cm flux (predicted/high/low). The differences
%   between early, nominal, and late timing of the solar cycle are not that
%   great, shifting the model on the order of a few months.
%   The outputs of this function are used by AtmJ70.
%
%   The database is good until 2020.
%
%   Has a built-in demo that plots for no outputs. 
%--------------------------------------------------------------------------
%   Form:
%   [aP, f, fHat, fHat400] = SolarFluxPrediction( jD, timing )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   jD          (1,1) Julian date
%   timing      (1,1) 'nominal', 'early', 'late'
%
%   -------
%   Outputs
%   -------
%   aP          (1,1) Geomagnetic index 6.7 hours before the computation
%   f           (3,1) Daily 10.7 cm solar flux (e-22 watts/m^2/cycle/sec)
%   fHat        (3,1) 81-day mean of f (e-22 watts/m^2/cycle/sec)
%   fHat400     (3,1) fHat 400 days before computation date
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2002 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

if( nargin < 1 )
  jD = [];
end

if( nargin < 2 )
  timing = '';
end

if( isempty(jD) )
  jD = Date2JD([2005 3 16 0 0 0] );
end

if( isempty(timing) )
  timing = 'nominal';
end

load SolarFluxPredictions

cp = cd;
p = FindDirectory( 'SCData' );
cd(p)
save SolarFluxPredictions.txt d -ASCII
cd(cp)

month = d(:,1)';
year  = d(:,2)';

jDS = zeros(1,length(year));

for k = 1:length(year)
  jDS(k) = Date2JD([year(k) month(k) 1 0 0 0]);
end

switch timing
  case 'nominal'
    f(1,:) = d(:, 3)';
    f(2,:) = d(:, 4)';
    f(3,:) = d(:, 5)';
    aP     = d(:, 6)';
	
  case 'early'
    f(1,:) = d(:, 7)';
    f(2,:) = d(:, 8)';
    f(3,:) = d(:, 9)';
    aP     = d(:,10)';
	
  case 'late'
    f(1,:) = d(:,11)';
    f(2,:) = d(:,12)';
    f(3,:) = d(:,13)';
    aP     = d(:,14)';
    
end

% Plot the data if no output arguments are specified
%---------------------------------------------------
if( nargout == 0 )
  yL = ['Ap   ';'F10.7'];
  [~, hA] = Plot2D( year + month/12, [aP;f],'Year',yL,['Solar Flux (' timing ')'],'lin',[;'[1  ]';'[2:4]']);
  legend( hA(2).h, 'Prediction', 'High', 'Low' )
  clear aP 
else
  % Compute fHat coefficients
  %--------------------------
  aP   = interp1( jDS, aP, jD - 6.7/24 ,'linear','extrap');
  q    = zeros(3,1);
  for k = 1:3
    q(k) = interp1( jDS, f(k,:), jD ,'linear','extrap');
  end
  fHat    = zeros(3,1);
  fHat400 = zeros(3,1);
  for j = 0:-1:-80
    for k = 1:3
      fHat(k)    = fHat(k)    + interp1( jDS, f(k,:), jD-j ,'linear','extrap');  
      if( jD-j-400 > jDS(1) )
        fHat400(k) = fHat400(k) + interp1( jDS, f(k,:), jD-j-400 ,'linear','extrap');
      end
    end
  end
  f       = q;
  fHat    = fHat/81;
  fHat400 = fHat400/81;
end

%--------------------------------------
% $Date: 2019-11-27 10:04:34 -0500 (Wed, 27 Nov 2019) $
% $Revision: 50413 $
