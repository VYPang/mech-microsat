function el = Alfriend2El( ela )

% Convert an Alfriend orbital element set into the standard orbital element set 
%%          [a,th,i,q1,q2,W]         ->     [a,i,W,w,e,M]
%--------------------------------------------------------------------------
%   Form:
%   el = Alfriend2El( ela )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   ela           (:,6) Alfriend orbital element set [a,th,i,q1,q2,W]
%                          where:   th = true latitude
%                                   q1 = e*cos(w)
%                                   q2 = e*sin(w)
%
%   -------
%   Outputs
%   -------
%   el            (:,6) Standard orbital element set [a,i,W,w,e,M]
%   
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2002 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------

% similar elements
%-----------------
a  = ela(:,1);     % semi-major axis
i  = ela(:,3);     % inclination
Om = ela(:,6);     % longitude of ascending node

% unique Alfriend elements
%-------------------------
th = ela(:,2);     % argument of latitude
q1 = ela(:,4);     % e*cos(w)
q2 = ela(:,5);     % e*sin(w)

% unique standard elements
%--------------------
w = atan2( q2, q1 );
e = sqrt( q1 .* q1 + q2 .* q2 );

M = Nu2M( e, th - w );

% output
%-------
el(:,1) = a;
el(:,2) = i;
el(:,3) = Om;
el(:,4) = w;
el(:,5) = e;
el(:,6) = M;


%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-09 11:41:04 -0400 (Tue, 09 May 2017) $
% $Revision: 44510 $
