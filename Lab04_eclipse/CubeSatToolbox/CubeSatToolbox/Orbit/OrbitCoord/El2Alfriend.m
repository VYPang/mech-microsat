function ela = El2Alfriend( el, nu )

%% Convert the standard orbital element set into an Alfriend orbital element set
%
%   [a,i,W,w,e,M]           ->           [a,th,i,q1,q2,W]
%--------------------------------------------------------------------------
%   Form:
%   ela = El2Alfriend( el, nu )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   el            (:,6) Standard orbital element set [a,i,W,w,e,M]
%
%   -------
%   Outputs
%   -------
%   ela           (:,6) Alfriend orbital element set [a,th,i,q1,q2,W]
%                          where:   th = true latitude
%                                   q1 = e*cos(w)
%                                   q2 = e*sin(w)
%   
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2002 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------

% similar elements
%-----------------
a  = el(:,1);     % semi-major axis
i  = el(:,2);     % inclination
Om = el(:,3);     % longitude of ascending node

% unique standard elements
%-------------------------
w = el(:,4);
e = el(:,5);
M = el(:,6);

% unique Alfriend elements
%-------------------------
if( nargin > 1 )
   th = WrapPhase( nu + w );               % argument of latitude  -pi < th < pi
else
   th = WrapPhase( M2Nu( e, M ) + w );     % argument of latitude  -pi < th < pi
end   
if( th < 0 )
   th = th + 2*pi;                           % further restrict angle to 0 < th < 2pi
end
q1 = e.*cos(w);
q2 = e.*sin(w);

% output
%-------
ela(:,1) = a;
ela(:,2) = th;
ela(:,3) = i;
ela(:,4) = q1;
ela(:,5) = q2;
ela(:,6) = Om;


%--------------------------------------
% $Date: 2017-05-09 11:41:04 -0400 (Tue, 09 May 2017) $
% $Revision: 44510 $
