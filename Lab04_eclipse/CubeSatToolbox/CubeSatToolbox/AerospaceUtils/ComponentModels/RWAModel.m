function [v, f, p] = RWAModel( r, u )

%% Get CAD vertices and properties for a specific RWA model.
% Dimensions are in meters. If no outputs are given it will draw the
% wheel. Available types are: 
%
%       'dynacon1000'
%       'hr02'
%       'hr04'
%       'hr01'
%       'hr15S'
%       'hr17'
%       'hm07'
%       'hr20m'
%       'hr20x'
%       'hr15m'
%       'hm55'
%       'hr60'   (default)
%       'hm45'
%       'hr150'
%       'hr195'
%       'hm1800'
%--------------------------------------------------------------------------
%   Form:
%   [v, f, p] = RWAModel( type, u )
%   [v, f, p] = RWAModel( r, u )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   r           (1,:) Type string or struct with following fields:
%                     ('r','rTop','rBottom','hTop','hCenter','hBottom', 'u')
%   u           (3,1) Unit vector if r is a string.
%
%   -------
%   Outputs
%   -------
%   v           (:,3) Vertices
%   f           (:,3) Faces
%   p            (.)  Properties data structure
%                       mass  (.)
%                       power (.)
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1998-2002 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
  if( nargout > 1 )
    r       = 'hr60';
    rWAName = ['RWA: ' r];
  else
    v       = Models;
    return;
  end
else
  d = r;
  rWAName = 'RWA';
end

if( ischar(r) )
  [d, p] = StockWheel( r );
end

if( nargin > 1 )
  d.u = u;
end

if( d.isCylinder )
  [v, f] = Frustrum( d.rL, d.r0, d.l, 10, 0, 0 );
else

  % Number of circumferential divisions
  %------------------------------------
  nPhi      = 10;
  phi       = linspace(0,2*pi*(1 - 1/nPhi),nPhi)';
  cPhi      = cos(phi);
  sPhi      = sin(phi);

  % Create the vertex list
  %-----------------------
  hT        = d.hTop + d.hCenter/2;
  hC2       = d.hCenter/2;
  hB        = d.hBottom + d.hCenter/2;
  ones20    = ones(nPhi,1);
  v         = [0              0                hT;...
               d.rTop   *cPhi d.rTop   *sPhi   hT*ones20;...
               d.r      *cPhi d.r      *sPhi   hC2*ones20;...
               d.r      *cPhi d.r      *sPhi  -hC2*ones20;...
               d.rBottom*cPhi d.rBottom*sPhi  -hB*ones20;...
             0              0               -hB];
  
  nR        = [ones20';2:11;12:21;22:31;32:41;42*ones20'];
  nR        = [nR nR(:,1)];
  [rNR,cNR] = size(nR);

  % Create the face list
  %---------------------
  f       = zeros(2*(cNR-1)*(rNR-1),3);
  nF      = 1;
  for k = 1:(rNR-1)
    for j = 1:(cNR-1)
      f(nF,:) = [nR(k,j) nR(k+1,j) nR(k+1,j+1)];
      nF      = nF + 1;
      f(nF,:) = [nR(k,j) nR(k+1,j+1) nR(k,j+1)];
      nF      = nF + 1;
    end
  end
end

if( norm( [0;0;1] - d.u ) > 100*eps )
  uX = Unit(Cross([0;0;1],d.u));
  uY = Unit(Cross(d.u,uX));
  b  = [uX uY d.u];
  v  = (b*v')';
end

% Draw the reaction wheel
%------------------------
if( nargout == 0 )
  DrawVertices(v,f,rWAName)
end

%--------------------------------------------------------------------------
%   Model names
%--------------------------------------------------------------------------
function d = Models

d = {'hr02' 'hr01' 'hr04' 'hr15S', 'hr17' 'hm07' 'hr20m' 'hr20x' 'hr15m' 'hm55' ...
     'hr60' 'hm45' 'hr150' 'hr195' 'hm1800'};

%--------------------------------------------------------------------------
%   Wheel properties
%--------------------------------------------------------------------------
function [d, p] = StockWheel( r )

p.mass  = GenericProperties('mass');
p.power = GenericProperties('power');

d.isCylinder = 0;
inToM        = 0.0254;

switch lower(deblank(r))
	  
    case 'dynacon1000'
      d.isCylinder = 1;
	    d.rL         = 0.129/2;
	    d.r0         = 0.129/2;
	    d.l          = 0.096;
      d.u          = [0;0;1];
      p.mass.mass  = 1.4;

	  
    case 'hr02'
      r         = 4.25*inToM;
      h         = 3.8*inToM;
      d.r       =     r;
      d.rTop    =  40*r/178;
      d.rBottom = 125*r/178;
      d.hTop    =  40*h/95;
      d.hBottom =  25*h/95;
      d.hCenter =  h - d.hTop - d.hBottom;
      d.u       =  [0;0;1];
      p.mass.mass = 3.2;
      
    case 'hr04'
	    d.isCylinder = 1;
	    d.rL         = 0.5*4.25*inToM;
	    d.r0         = 0.5*4.25*inToM;
	    d.l          = 2.12*inToM;
      d.u          = [0;0;1];
      p.mass.mass  = 1.3;

    case 'hr01'
      r         = 4.625*inToM;
      h         = 4.7*inToM;
      d.r       =     r;
      d.rTop    =  40*r/178;
      d.rBottom = 125*r/178;
      d.hTop    =  40*h/95;
      d.hBottom =  25*h/95;
      d.hCenter =  h - d.hTop - d.hBottom;
      d.u       =  [0;0;1];
      p.mass.mass = 5.2;
       
    case 'hr15S'
      r         =  6.9*inToM;
      h         =  6.7*inToM;
      d.r       =     r;
      d.rTop    =  40*r/178;
      d.rBottom = 125*r/178;
      d.hTop    =  40*h/95;
      d.hBottom =  25*h/95;
      d.hCenter =  h - d.hTop - d.hBottom;
      d.u       =  [0;0;1];
      p.mass.mass = 10;
      
    case 'hr17'
      r         = 6.3*inToM;
      h         = 7.4*inToM;
      d.r       =     r;
      d.rTop    =  40*r/178;
      d.rBottom = 125*r/178;
      d.hTop    =  40*h/95;
      d.hBottom =  25*h/95;
      d.hCenter =  h - d.hTop - d.hBottom;
      d.u       =  [0;0;1];
      p.mass.mass = 8.9;
      
    case 'hm07'
      r         = 6.25*inToM;
      h         = 7.8*inToM;
      d.r       =     r;
      d.rTop    =  40*r/178;
      d.rBottom = 125*r/178;
      d.hTop    =  40*h/95;
      d.hBottom =  25*h/95;
      d.hCenter =  h - d.hTop - d.hBottom;
      d.u       =  [0;0;1];
      p.mass.mass = 6.8;
      
    case 'hr20m'
      r         = 7*inToM;
      h         = 7.6*inToM;
      d.r       =     r;
      d.rTop    =  40*r/178;
      d.rBottom = 125*r/178;
      d.hTop    =  40*h/95;
      d.hBottom =  25*h/95;
      d.hCenter =  h - d.hTop - d.hBottom;
      d.u       =  [0;0;1];
      p.mass.mass = 9.6;
      
    case 'hr20x'
      r         = 7*inToM;
      h         = 7.6*inToM;
      d.r       =     r;
      d.rTop    =  40*r/178;
      d.rBottom = 125*r/178;
      d.hTop    =  40*h/95;
      d.hBottom =  25*h/95;
      d.hCenter =  h - d.hTop - d.hBottom;
      d.u       =  [0;0;1];
      p.mass.mass = 9.6;
    case 'hr15m'
      r         = 7*inToM;
      h         = 7.8*inToM;
      d.r       =     r;
      d.rTop    =  40*r/178;
      d.rBottom = 125*r/178;
      d.hTop    =  40*h/95;
      d.hBottom =  25*h/95;
      d.hCenter =  h - d.hTop - d.hBottom;
      d.u       =  [0;0;1];
      p.mass.mass = 10.4;
      
   case 'hm55'
      r         = 8*inToM;
      h         = 8*inToM;
      d.r       =     r;
      d.rTop    =  40*r/178;
      d.rBottom = 125*r/178;
      d.hTop    =  40*h/95;
      d.hBottom =  25*h/95;
      d.hCenter =  h - d.hTop - d.hBottom;
      d.u       =  [0;0;1];
      p.mass.mass = 11.6;
      
   case 'hr60'
      r         = 8*inToM;
      h         = 8.5*inToM;
      d.r       =     r;
      d.rTop    =  40*r/178;
      d.rBottom = 125*r/178;
      d.hTop    =  40*h/95;
      d.hBottom =  25*h/95;
      d.hCenter =  h - d.hTop - d.hBottom;
      d.u       =  [0;0;1];
      p.mass.mass = 14.3;
      
    case 'hm45'
      r         = 8*inToM;
      h         = 8.5*inToM;
      d.r       =     r;
      d.rTop    =  40*r/178;
      d.rBottom = 125*r/178;
      d.hTop    =  40*h/95;
      d.hBottom =  25*h/95;
      d.hCenter =  h - d.hTop - d.hBottom;
      d.u       =  [0;0;1];
      p.mass.mass = 11.9;
      
    case 'hr150'
      r         = 9*inToM;
      h         = 9*inToM;
      d.r       =     r;
      d.rTop    =  40*r/178;
      d.rBottom = 125*r/178;
      d.hTop    =  40*h/95;
      d.hBottom =  25*h/95;
      d.hCenter =  h - d.hTop - d.hBottom;
      d.u       =  [0;0;1];
      p.mass.mass = 27.7;
      
    case 'hr195'
      r         = 12.8*inToM;
      h         = 21.5*inToM;
      d.r       =     r;
      d.rTop    =  40*r/178;
      d.rBottom = 125*r/178;
      d.hTop    =  40*h/95;
      d.hBottom =  25*h/95;
      d.hCenter =  h - d.hTop - d.hBottom;
      d.u       =  [0;0;1];
      p.mass.mass = 48;
      
    case 'hm1800'
      r         = 14*inToM;
      h         = 27.2*inToM;
      d.r       =     r;
      d.rTop    =  40*r/178;
      d.rBottom = 125*r/178;
      d.hTop    =  40*h/95;
      d.hBottom =  25*h/95;
      d.hCenter =  h - d.hTop - d.hBottom;
      d.u       =  [0;0;1];
      p.mass.mass = 81.6;
      
    otherwise
      disp(['RWAModel: Data on ' r ' is not available'])
end


%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2020-06-03 11:33:54 -0400 (Wed, 03 Jun 2020) $
% $Revision: 52628 $
