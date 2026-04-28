function g = AntennaGain( d, frequency )

%% Antenna gain.
%
% Type AntennaGain to run a demo.
%--------------------------------------------------------------------------
%   Form:
%   g = AntennaGain( d, frequency )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   d             (:)   Antenna data structure
%                         .type             (1,:) Type
%                         .area             (1,1) Area
%                         .effIllumination  (1,1) Illumination efficiency
%                         .effSpillover     (1,1) Spillover efficiency
%                         .effSurfaceFinish (1,1) Surface finish efficiency
%                         .effOhmic         (1,1) Ohmic losses
%                         .effImpedance     (1,1) Impedancy mismatch losses
%                         .eff              (1,1) Miscellaneous
%                         .n                (1,1) Number of turns (helical)
%                         .c                (1,1) Circumference (helical)
%                         .s                (1,1) Spacing (helical)
%   frequency    (1,:)  Frequency (GHz)
%                        
%   -------
%   Outputs
%   -------
%   g            (:)    Gain (dB)
%                        
%--------------------------------------------------------------------------
%   References:	Maral, G. and M. Bousquet. (1998) Satellite Communications
%               Systems. Wiley. pp. 14-17
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1998-2001 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since 2020.1 Switched to dynamic field names
%   Added helical antennas
%--------------------------------------------------------------------------

if( nargin < 1 )
  d = DefaultDataStructure;
  if( nargout > 0 )
    g = d;
  else
    AntennaGain(d);
  end
  return
end

if( nargin < 2 )
  frequency = [];
end

if( isempty(frequency) )
  frequency = logspace(9,log10(30e9));
else
  frequency = frequency*1e9;
end

% Set default values for efficiencies
%------------------------------------
f   = {'eff' 'effIllumination' 'effSpillover' 'effSurfaceFinish' 'effOhmic' 'effImpedance'};
fD  = fieldnames(d);
eff = 1;

for k = 1:length(f)
  if( isempty(StringMatch( f{k}, fD )) )
    d.(f{k}) = 1;
  end
  eff = eff*d.(f{k});
end

lambda = 299793458./frequency;

% Code
%-----
switch lower(d.type)
  case {'circular aperture' 'horn'}
    g  = (4*pi./lambda.^2)*eff*d.area;
  case {'omni', 'omnidirectional', 'dipole'}
    g  = 1.5;
  case {'helical'}
    g  = 15*d.eff*(d.c./lambda).^2*(d.n*d.s./lambda);
  otherwise
    error(['Antenna type: ' d.type ' is not available']);
end

g = 10*log10(g);
 
% Plotting
%---------
if( nargout == 0 )
  Plot2D(frequency/1e9,g,'Frequency (GHz)','Gain (dB)','AntennaGain','xlog');
  fprintf(1,'------------\n');
  fprintf(1,'Antenna Gain\n');
  fprintf(1,'------------\n');
  fprintf(1,'Area                        \t%12.4f\tm^2\n',d.area);
  fprintf(1,'Efficiency                  \t%12.4f\t\n',eff);
  for k = 1:length(f)
    fprintf('%-30s\t%12.4f\t \n',f{k}, d.(f{k}));
  end	
  clear g;
end

%% AntennaGain>DefaultDataStructure
function d = DefaultDataStructure

d.type             = 'circular aperture';
d.effIllumination  = 0.91;
d.effSpillover     = 0.8;
d.effSurfaceFinish = 0.85;
d.effOhmic         = 1;
d.effImpedance     = 1;
d.eff              = 1;
d.area             = 1;
d.n                = 1;
d.s                = 0.23*8e-2;
d.c                = 8e-2;


%--------------------------------------
% $Date: 2020-04-07 09:27:24 -0400 (Tue, 07 Apr 2020) $
% $Revision: 51752 $


