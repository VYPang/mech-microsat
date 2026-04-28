function eff = ModulationSpectralEfficiency( modulation )

%% Spectral efficiency of different modulation schemes
% BPS = bandwidth* spectral efficiency
%
% There is a built-in demo that cycles through all the types.
%--------------------------------------------------------------------------
%   Form:
%   eff = ModulationSpectralEfficiency( modulation )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   modulation	(1,:)	'BPSK' 'QPSK' 'DE-BPSK' 'DE-QPSK' 'D-BPSK'
%
%   -------
%   Outputs
%   -------
%   eff           (1,1) bps/Hz
%
%--------------------------------------------------------------------------
%   Reference: Bousquet, M. and  Maral, G. "Satellite Communications 
%              Systems, 3rd Edition," Wiley p 121.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2016 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 2017.1
%--------------------------------------------------------------------------

if( nargin < 1 )
  eff     = zeros(1,5);
  type    = {'BPSK' 'QPSK' 'DE-BPSK' 'DE-QPSK' 'D-BPSK'};
  for k = 1:5
    eff = ModulationSpectralEfficiency( type{k} );
    fprintf(1,'Modulation: %7s efficiency %5.2f bit/s Hz\n',type{k},eff);
  end
  clear eff
  return
end

type    = {'BPSK' 'QPSK' 'DE-BPSK' 'DE-QPSK' 'D-BPSK'};

j       = strcmpi(modulation,type);

effType = [0.75 1.5 0.75 1.5 0.75];

eff     = effType(j);


%--------------------------------------
% $Date: 2017-05-22 16:50:05 -0400 (Mon, 22 May 2017) $
% $Revision: 44648 $
