function [v, f, c] = GeomPatch( d, cData, cMap )

%% Get vertices for surfaces of revolution, ellipsoids and cylinders
% All surfaces, except for ellipsoids, are closed. Type GeomPatch for a demo.
%--------------------------------------------------------------------------
%   Form:
%   [v, f, c] = GeomPatch( d, cData, cMap )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   d           (.)   Data structure
%                     Surface of revolution: d.a, d.n, d.zUpper, d.zLower
%                     d.a          r as a function of polynomial z
%                                  a(1)*z^n + a(2)*z^(n-1)... a(n)*z^0]
%                     d.n          Number of divisions
%                     d.zUpper     Upper z limit
%                     d.zLower     Lower z limit
%
%                     Cylinder: d.rU, d.rL, d.zUpper, d.zLower, d.n
%                     d.rU         Upper radius
%                     d.rL         Lower radius
%                     d.zUpper     Upper z limit
%                     d.zLower     Lower z limit
%                     d.endcap     Any value creates endcaps   
%
%                     Ellipsoid: d.a, d.b, d.c, d.thetaUpper, d.n
%                     d.a          X radius
%                     d.b          Y radius
%                     d.c          Z radius
%                     d.thetaUpper Upper angle. Ranges from 0 to thetaUpper
%                     d.n          Number of divisions
%
%                     The default value for n is 6.
%
%   cData       (m,p) Indexes to the color map where the values range
%                     from 1 to n
%   cMap        (n,3) Color Map
%
%   -------
%   Outputs
%   -------
%   v           (:,3) Vertices
%   f           (:,3) Faces
%   c           (:,3) Vertex color data where the number of rows equal
%                     the number of vertices
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1998-2000 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 2.
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
  d.rU     = 1;
  d.rL     = 1;
  d.zUpper = 1;
  d.zLower = -1;
  d.endcap = 1;
  d.n      = 10;
  GeomPatch( d );
  return;
end

% Determine the number of divisions
%----------------------------------
if( ~isfield( d, 'n') )
  if( nargin < 2 )
    nPhi = 6;
    nZ   = 6;
  else
    nPhi = size(cData,2);
    nZ   = size(cData,1);
  end
else
  if( d.n > 3 )
    if( isfield(d, 'nZ' ) )
      nZ = max([2 d.nZ]);
    else
      nZ = d.n;
    end
    nPhi = d.n;
  else
    nPhi = 3;
    nZ   = 3;
  end
end

% Circumferential about z
%------------------------
phi    = linspace(0,2*pi*(1 - 1/nPhi),nPhi);
sPhi   = sin(phi);
cPhi   = cos(phi);
clear phi

% Three cases: ellipsoid, cylinder and surface of revolution
%-----------------------------------------------------------
sOR       = 1;
ellipsoid = 2;
cylinder  = 3;

if( isfield( d, 'rU' ) )
  sORType = cylinder;
elseif( isfield( d, 'zUpper' ) )
  sORType = sOR;
else
  sORType = ellipsoid;
end

switch sORType

  case {sOR, cylinder}

    negRadius = 0;

    % Divide up the z divisions among the top and bottom end caps and the height
    %---------------------------------------------------------------------------
    switch sORType

      case sOR
        e      = (0:length(d.a)-1)';    
        rU     = d.a*(d.zUpper.^e);
        rL     = d.a*(d.zLower.^e);
        a      = d.a;

        if( (rU < 0) || (rL < 0) )
          negRadius = 1;
          rU        = abs(rU);
          rL        = abs(rL);
        end;

     case cylinder
        rU     = d.rU;
        rL     = d.rL;
        e      = [0 1]';
        m      = (d.rU - d.rL)/(d.zUpper - d.zLower);
        a      = [d.rL - m*d.zLower m];
    end

    if( isfield( d, 'nZ' ) )
      nL = 1;
      nU = 1;
      n  = max([0 nZ - 2]);
    else
      lTotal = rU + rL + abs(d.zUpper - d.zLower);
      nU     = ceil(nZ*rU/lTotal);
      nL     = ceil(nZ*rL/lTotal);
      n      = nZ - nU - nL;
    end

    if( isfield( d, 'endcap' ) )
      z = [ones(1,nL)*d.zLower linspace(d.zLower,d.zUpper,n) ones(1,nU)*d.zUpper];
      for k = 1:nZ
        if( k <= nL )              % bottom face
          r    = (k/nL)*rL;
          z(k) = - sqrt( d.rU^2 - r^2) + d.zLower;
        elseif( k > nZ - nU + 1 )  % top face
          r    = (nZ - k + 1)*rU/nU;
          z(k) = sqrt( d.rL^2 - r^2) + d.zUpper;
        end
      end
    else
      z = [ones(1,nL)*d.zLower linspace(d.zLower,d.zUpper,n) ones(1,nU)*d.zUpper];
    end

    % Create the vertex list
    %-----------------------
    v         = zeros(nPhi*nZ,3);
    kR        = 1;
    nV        = 0;

    for k = 1:nZ
      if( k <= nL )              % bottom face
        r = (k/nL)*rL;
      elseif( k > nZ - nU + 1 )  % top face
        r = (nZ - k + 1)*rU/nU;
      else
        r  = a*(z(k).^e);
      end

      if( r < 0 )
        negRadius = 1;
        r         = abs(r);
      end;

      nVS = nV + 1;
      for j = 1:nPhi
        nV      = nV + 1;
        v(nV,:) = [r*cPhi(j) r*sPhi(j) z(k)];
      end
      nR(kR,:) = [nVS:nV nVS];
      kR       = kR + 1;
    end
    if( isfield( d, 'endcap' ) )
      v  = [[0 0 d.zLower-d.rL];v;[0 0 d.zUpper+d.rU]];
    else
      v  = [[0 0 d.zLower];v;[0 0 d.zUpper]];
    end
    nR = [ones(1,nPhi+1);nR+1;size(v,1)*ones(1,nPhi+1)];

    if( negRadius )
      warndlg('Calculated radius is negative. Will use absolute value.');
    end;

  case ellipsoid

    if( isfield( d, 'r' ) )
      if( length(d.r) == 1 ) 
        rX = d.r;
        rY = d.r;
        rZ = d.r;
      else
        rX = d.r(1);
        rY = d.r(2);
        rZ = d.r(3);
      end
    else
      if( isfield( d, 'a' ) )
        rX = d.a;
      elseif( isfield( d, 'b' ) )
        rX = d.b;
      else
        rX = d.c;
      end

      if( isfield( d, 'b' ) )
        rY = d.b;
      elseif( isfield( d, 'a' ) )
        rY = d.a;
      else
        rY = d.c;
      end

      if( isfield( d, 'c' ) )
        rZ = d.c;
      elseif( isfield( d, 'a' ) )
        rZ = d.a;
      else
        rZ = d.b;
      end
    end

    if( isfield( d, 'thetaUpper' ) )
      theta      = linspace(0,d.thetaUpper,nZ);
      thetaUpper = d.thetaUpper;
    else
      theta      = linspace(0,pi,nZ);
      thetaUpper = pi;
    end

    sT     = sin(theta);
    cT     = cos(theta);

    % x = r*[cos(phi)*cos(theta);sin(phi)*sin(theta);cos(theta)]
    %-----------------------------------------------------------

    % Create the vertex list
    %-----------------------
    nV      = 1;
    v       = zeros(2 + nPhi*(nZ-2),3);
    v(nV,:) = [0 0 rZ];
    nR      = zeros(nZ,nPhi+1);
    nR(1,:) = ones(1,nPhi+1);
    kR      = 2;
    if( thetaUpper == pi )
      nVL      = 2 + nPhi*(nZ-2);
      nR(nZ,:) = ones(1,nPhi+1)*nVL;
      nZ       = nZ - 1;
      v(nVL,:) = [0 0 -rZ];
    else
      nVL = nV;
    end
    cT   = rZ*cT;
    cPhi = rX*cPhi';
    sPhi = rY*sPhi';
    j = 2:(nPhi+1);
    for k = 2:nZ
      v(j,1:2) = [cPhi*sT(k) sPhi*sT(k)];
      v(j,  3) = cT(k);
      nR(k,:)  = [j j(1)];
      j        = j + nPhi;
    end
end

% Clean up memory
%----------------
clear cPhi sPhi sT cT theta

% Add the first column to the end to close the surface
%-----------------------------------------------------
[rNR,cNR] = size(nR);
cNR       = cNR - 1;

% Create the face list
%---------------------
nF = 1;
f  = zeros(2*cNR*(rNR-1),3);
for k = 1:(rNR-1)
  for j = 1:cNR
    if( nR(k+1,j) ~= nR(k+1,j+1) )
      f(nF,:) = [nR(k,j) nR(k+1,j) nR(k+1,j+1)];
      nF      = nF + 1;
    end
    if( nR(k,j) ~= nR(k,j+1) ) 
      f(nF,:) = [nR(k,j) nR(k+1,j+1) nR(k,  j+1)];
      nF      = nF + 1;
    end
  end
end

% Eliminate empty faces
%----------------------
jZ = min( find( f(:,1) == 0 ) );
f(jZ:end,:) = [];

% Scale the color index data to fit the patch vertex map
%-------------------------------------------------------
j = 1:cNR;
if( nargin > 1 )
  if( isfield( d, 'n') )
    nRCMap = size(cData,1);
    nCCMap = size(cData,2);
    cDataI = round(interp2(1:nCCMap,1:nRCMap,double(cData) + 1,linspace(1,nCCMap,cNR),linspace(1,nRCMap,rNR-1)'));
  else
    cDataI = double(cData) + 1;
  end
  c      = zeros(nVL,3);
  k      = 1:(rNR-1);
  c(nR(k,j),:) = cMap(cDataI(k,j),:);
end

% Clean up memory
%----------------
clear cData cDataI cMap

% If an open ellipsoid create faces on the interior
%--------------------------------------------------
if( sORType == ellipsoid )
  if( isfield( d, 'thetaUpper' ) )
    if( d.thetaUpper < pi )
      for k = 1:(rNR-1)
        for j = 1:cNR
          f(nF,:) = [nR(k,j) nR(k+1,j+1) nR(k+1,j  )];
          nF      = nF + 1;
          f(nF,:) = [nR(k,j) nR(k,  j+1) nR(k+1,j+1)];
          nF      = nF + 1;
        end
      end
    end
  end
end

% Clean up memory
%----------------
clear nR

% Draw the object
%----------------
if( nargout == 0 )
  NewFig('Patch')
  if( nargin < 2 )
    patch('vertices',v,'faces',f,'facecolor',[0.5 0.5 0.5]);
  else
    patch('vertices',v,'faces',f,'facecolor','interp','edgecolor','interp','FaceVertexCData',c,...
                                 'facelighting','phong', 'edgelighting','phong');
  end
  axis equal
  XLabelS('x')
  YLabelS('y')
  ZLabelS('z')
  view(3)
  grid on
  rotate3d on
  s = 10*max(Mag(v'));
  light('position',s*[1 1 1])
  clear v
end


%--------------------------------------
% $Date: 2017-05-02 10:35:58 -0400 (Tue, 02 May 2017) $
% $Revision: 44446 $
