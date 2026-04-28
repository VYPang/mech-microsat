function b = BFromHHysteresis( h, hDot, d )

%% Flux density from the magnetic field due to hysteresis.
%
%   Unlike Flatley, we use a tanh curve for the hysteresis boundaries.
%
%   Since version 10.
%--------------------------------------------------------------------------
%   Form:
%   b = BFromHHysteresis( h, hDot, d )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   h                  (1,:) Magnetic field in each bar
%   hDot               (1,:) Magnetic field rate in each bar
%   d                  (1,1) Data structure
%                            .bS (1,1) Saturation flux density 
%                            .hC (1,1) Coercive force
%                            .bR (1,1) Remnance
%
%   -------
%   Outputs
%   -------
%   b                  (1,:) Flux density
%   
%
%--------------------------------------------------------------------------
%   Reference: Flatley, T. W. and Henretty, D. A., "A Magnetic Hysteresis
%              Model."
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2011, 2014 Princeton Satellite Systems, Inc.
%   All Rights Reserved
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin  < 1 )
    
    d.Br	= 0.4;      % Remnance (T)
    d.Bs	= 0.65;     % Saturation flux density (T)
    d.Hc	= 1.2;      % Coercive force (A/m)
    
    h       = linspace(-10,10);
    hDot    = ones(1,length(h));

    BFromHHysteresis( h, hDot, d );
    
	  h       = linspace(-10,10);
    hDot    = -ones(1,length(h));

    b       = BFromHHysteresis( h, hDot, d );
    hold on
    plot(h,b,'r');
    legend('dh/dt > 0','dh/dt < 0','location','best');
    clear b
    
    return
end

b  = zeros(1,length(h));

k  = atanh(d.Br/d.Bs)/d.Hc;
    
j       = find(hDot < 0 );
b(j)	= d.Bs*tanh(k*(h(j) + d.Hc));
    
j       = find(hDot >= 0 );
b(j)	= d.Bs*tanh(k*(h(j) - d.Hc));


% Default output
%---------------
if( nargout == 0 )
    Plot2D(h,b,'H', 'B', 'B from H');
    clear b;
end

%--------------------------------------
% $Date: 2020-05-26 15:40:34 -0400 (Tue, 26 May 2020) $
% $Revision: 52440 $

