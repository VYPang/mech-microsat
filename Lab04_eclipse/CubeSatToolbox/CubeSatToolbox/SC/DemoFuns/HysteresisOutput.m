function status = HysteresisOutput(t,y,flag,d)

%% Gather output from the hysteresis damping simulation
%--------------------------------------------------------------------------
%  Form:
%  d = HysteresisOutput;
%  status = HysteresisOutput(t,y,flag,d)
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   t    	(1,1)     Time
%   y   	(13+n,:)  [r;v;q;omega;z] 
%   flag  (1,:)     Operation to be performed.
%   d     (.)       Data structure see RHSRigidBodyWithDamping
%
%   -------
%   Outputs
%   -------
%   status	(1,1)    Result
%
%--------------------------------------------------------------------------
%  See also RHSRigidBodyWithDamping
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2014 Princeton Satellite Systems, Inc.
%   All Rights Reserved
%--------------------------------------------------------------------------
%   2019.1 Added default data structure
%--------------------------------------------------------------------------

if( nargin < 1 )
  status = RHSRigidBodyWithDamping;
  return
end

persistent xP zP tP kF

status  = 0;
degToRad = pi/180;

if isempty(flag)
  nP = size(y,2);
  n0 = length(tP);
  tP = [tP zeros(1,nP)];
  xP = [xP zeros(23,nP)];
  zP = [zP zeros(size(zP,1),nP)];
  for k = 1:size(y,2)
    x           =	y(:,k);
    tP(n0+k)    = t(k);
    [~, p]      = RHSRigidBodyWithDamping(x,t(k),d);
    uECI        = QTForm(x(7:10),d.uDipole);
    angle       = real(acos(Dot(uECI, Unit(p.bFieldECI))))/degToRad;
    xP(:,n0+k)  = [x(1:13);p.torqueDamper;p.torqueDipole;angle;p.bFieldECI*1e9];

    if( length(x)>13 )
      zP(:,n0+k) = [x(14:end);p.hMag;p.hDotMag];
    end
  end
  if t(end) > (kF+1)*d.end/10
    kF = kF+1;
    fprintf('%d0%% finished\n',kF);
  end
elseif strcmp(flag,'init')
  tP = 0;
  xP = [y(1:13); zeros(10,1)];
  z  = y(14:end);
  zP = zeros(3*length(z),1);
  kF = 0;
elseif strcmp(flag,'done')
elseif strcmp(flag,'x')
  status = xP;
elseif strcmp(flag,'z')
  status = zP;
elseif strcmp(flag,'t')
  status = tP;
end


%--------------------------------------
% $Date: 2019-12-18 22:54:26 -0500 (Wed, 18 Dec 2019) $
% $Revision: 50628 $
