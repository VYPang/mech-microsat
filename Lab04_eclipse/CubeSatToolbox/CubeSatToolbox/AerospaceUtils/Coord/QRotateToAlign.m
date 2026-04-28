function [qRot,ub,rotAngle,sepAngle] = QRotateToAlign( axis, ua, ut)

%% Rotate about an axis to align "ua" as close as possible to target "ut"
%--------------------------------------------------------------------------
%   Form:
%   [qRot,ub,rotAngle,sepAngle] = QRotateToAlign( axis, ua, uat);
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   axis       (3,1)  Axis of rotation
%   ua         (3,1)  Vector to align
%   ut         (3,:)  Target vector to be aligned with
%
%   -------
%   Outputs
%   -------
%   qRot       (4,1)  Quaternion that rotates ua to ub about axis
%   ub         (3,1)  Vector achieved after rotation
%   rotAngle   (4,1)  Angular rotation about the axis
%   sepAngle   (4,1)  Separation angle between ub and ut
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2007 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

ua = Unit(ua);
ut = Unit(ut);
axis = Unit(axis);

% compute min separation angle directly
%-----------------------------------------
x = Unit(axis);
z = Unit(Cross(x,ua));
y = Unit(Cross(z,x));
m = [x';y';z'];
rotAngle = atan2(z'*ut,y'*ut);
xc = x'*ua;
yc = y'*ua;
ub = m'*[xc*ones(size(rotAngle)); yc*cos(rotAngle); yc*sin(rotAngle)];
c = ub(1,:).*ut(1,:)+ub(2,:).*ut(2,:)+ub(3,:).*ut(3,:);
k = find(abs(c)>1);
c(k)=sign(c(k));  % do this to prevent rounding errors from causing |c|>1
sepAngle = acos(c);
qRot = [cos(rotAngle/2);...
  sin(rotAngle/2)*axis(1);...
  sin(rotAngle/2)*axis(2);...
  sin(rotAngle/2)*axis(3)];


if( nargout<1 )
  f=Coordinates;
  xx = [-axis,axis];
  line(xx(1,:),xx(2,:),xx(3,:),'color','w','linestyle','--','linewidth',2);
  line([0 ut(1)],[0 ut(2)],[0 ut(3)],'color','c','linewidth',3);
  hold on
  n = 360;
  theta = linspace(0,2*pi*(1-1/n),n);
  q     = [cos(theta/2);axis*sin(theta/2)];
  ua2   = QForm(q,ua);
  plot3(ua2(1,:),ua2(2,:),ua2(3,:),'y');
  line([0 ua(1)],[0 ua(2)],[0 ua(3)],'color','m','linewidth',3,'linestyle',':');
  line([0 ub(1)],[0 ub(2)],[0 ub(3)],'color','m','linewidth',3);
  
  rotAngleX = linspace(0,2*pi,3600);
  ubX = m'*[xc*ones(size(rotAngleX)); yc*cos(rotAngleX); yc*sin(rotAngleX)];
  c = ubX(1,:).*ut(1,:)+ubX(2,:).*ut(2,:)+ubX(3,:).*ut(3,:);
  k = find(abs(c)>1);
  c(k)=sign(c(k));  % do this to prevent rounding errors from causing |c|>1
  sepAngleX = acos(c);
  Plot2D(rotAngleX*180/pi,sepAngleX*180/pi,'Rot. Angle (deg)','Sep. Angle (deg)')
    
  [~,kmax] = max(sepAngleX);
  [~,kmin] = min(sepAngleX);
  disp( (rotAngleX(kmax)-rotAngleX(kmin))*180/pi )
  
end

%--------------------------------------
% $Date: 2020-04-27 15:36:14 -0400 (Mon, 27 Apr 2020) $
% $Revision: 51998 $
