function a = LossAtmosphericGas( f, E )

%% Computes the link attenuation due to gas. 
%   Assumes the signal passes through a fixed slice of atmosphere.
%
%   Type LossAtmosphericGas for a demo.
%
%   To make the output a gain change to sign of the output to negative.
%--------------------------------------------------------------------------
%   Form:
%   a = LossAtmosphericGas( f, E )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   f              (1,m)  Frequency (GHz)
%   E              (1,n)  Elevation angle (deg)
%
%   -------
%   Outputs
%   -------
%   a              (n,m)  Loss (dB)
%
%--------------------------------------------------------------------------
%   Reference:	Maral, G. and M. Bousquet. (1998.) Satellite Communications
%               Systems, Third Edition. John Wiley. p. 57.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2001, 2008 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
  f = logspace(log10(0.30000001),log10(50));
  E = [0 5 10 20 90];
  LossAtmosphericGas( f, E );
  return
end

j = [find( f < 0.3 ) find( f > 50 )];

if( ~isempty(j) )
  error('Frequency out of range');
end

aScale = 10.^( [40 50 55 60 74]*4/74 - 2)/10^(4*40/74-2);
eScale = [90 20 10 5 0];

scale  = interp1( eScale, aScale, E )';

fS     =       [0.3 0.5 1   2    3    5  7 10   14 20 22 30 37 50];
aS     = 10.^( [2   7   8.5 9.5 10.5 11 11.5 11.8 12.1 29 31 24 29 40]*4/74 - 2);

a      =  interp1( fS, aS, f );

a      = scale*a;


if( nargout == 0 )
 	Plot2D( f, a, 'Frequency (GHz)' ,'Attenuation', 'Gas Link Attenuation', 'log' );
	m = [];
	for k = 1:length(E)
	  m = char(m,sprintf('Elevation Angle = %3.1f deg',E(k)));
  end
  m(1,:) = '';
	legend(m,'location','best')
	clear a
end

%--------------------------------------
% $Date: 2020-03-16 11:18:13 -0400 (Mon, 16 Mar 2020) $
% $Revision: 51561 $


