function [aG, aS, aZ, aT] = AGravityC( r, nN, nM, s, c, j, mu, a, useNormM )

%% Compute the gravitational acceleration in cartesian coordinates. 
% Acceleration vectors are a [ aX;aY;aZ ].
%
% If the gravity coefficients are normalized, an additional matrix
% multiplication is required. The normalization matrix is stored as a persistent
% variable but AGravityC will gracefully update it if the normalization or order
% of the model changes between calls.
%--------------------------------------------------------------------------
%   Form:
%   [aG, aS, aZ, aT] = AGravityC( r, nN, nM, d )  % structure
%   [aG, aS, aZ, aT] = AGravityC( r, nN, nM, s, c, j, mu, a, useNormM )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   r           (3,:)    Position vector, planet-fixed
%   nN          (1,1)    Highest zonal harmonic (m = 0)
%                        (empty gives the max #) 
%   nM          (1,1)    Highest sectorial and tesseral harmonic 
%                        (empty gives the max #) 
%   d            (.)     Gravity model struct
%      -or-
%   s           (:,:)    S terms
%   c           (:,:)    C terms
%   j             (:)    m = 0 terms
%   mu          (1,1)    Spherical gravitational potential
%   a           (1,1)    Planet radius
%   useNormM    (1,1)    Generate the normalization matrix (default false)
%
%   -------
%   Outputs
%   -------
%   aG           (3,:)   Total gravitational acceleration km/sec^2
%   aS           (3,:)   Spherical term                   km/sec^2
%   aZ           (3,:)   Zonal term                       km/sec^2
%   aT           (3,:)   Tesseral term                    km/sec^2
%
%--------------------------------------------------------------------------
%	 Reference: Bond, V. R. and M. C. Allman (1996.) Modern Astrodynamics.
%                Princeton. pp. 212-213.
%             Lerch, F. J., Klosko, S. M., Labuscher, R. E., Wagner,
%                C.A., "Gravity Model Improvement GEOS-3 (GEM 9 & 10)," 
%                N78-10645, September, 1977.
%             Gottlieb, R. G., "Fast Gravity, Gravity Partials, Normalized 
%                Gravity, Gravity Graident Torque and Magnetic Field: 
%                Derivation, Code and Data, NASA CR 188243, February, 1993.
%--------------------------------------------------------------------------
%   See also UnnormalizeGravity, AGravity (output in spherical coords)
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1996-2001, 2015 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 5.5
%   2015-09-08 Add normalization input and persistent variable
%   2017.1 Add ability to bypass normalization variable
%   2018.1 Fixed demo - Gottlieb was in m/s^2
%--------------------------------------------------------------------------

persistent rNM useNorm

if( nargin < 1 )
  % Reference data: from Gottlieb (1993)
  %         m  1        2        3        4
  disp('Demo of AGravityC')
  % This is unnormalized
  gem     = LoadGEM( 1 );
  r       = [5489.150;802.222;3140.916];
  
  % Gottlied is in m/s^2
  aRef    =	[-8.44269212018857;-1.23393633785485;-4.84659352346614]*0.001; % GEM10

  aUnnorm = AGravityC( r, 4, 4, gem );
  

  fprintf(1,'Ref (GEM10):  [%24.16f %24.16f %24.16f]\n',aRef);
  fprintf(1,'AGravityC:    [%24.16f %24.16f %24.16f]\n',aUnnorm);
  fprintf(1,'Delta:        [%24.16f %24.16f %24.16f]\n',aUnnorm-aRef);
  return
end

if (nargin<9 || isempty(useNormM))
  useNormM = false;
end  
if( isstruct(s) )
  gm = s;
  s = gm.s;
  c = gm.c;
  j = gm.j;
  mu = gm.mu;
  a = gm.a;
  useNormM = gm.isNormalized;
end

if( isempty( nN ) )
  nN = size(s,1);
end
if( isempty( nM ) )
  nM = size(s,2);
end

if( isempty(rNM) || (useNorm~=useNormM) || ~all(size(rNM)==[nN,nM+1]) )
  if( useNormM )
    [f,fp] = NormalizationMatrix(nN,nM);
    rNM   = 1./[fp' f];
    useNorm = true;
  else
    rNM     = ones(nN,nM+1);
    useNorm = false;
  end
end

% Lump the j terms into c
%------------------------
c = [j' c];
s = [zeros(length(j),1), s];

cHat = zeros(1,nN);
sHat = zeros(1,nN);

nV   = size(r,2);
aS   = zeros(3,nV);
aZ   = zeros(3,nV);
aT   = zeros(3,nV);
aG   = zeros(3,nV);
dVDR = zeros(3,nV);
for k = 1:nV
  rG        = r(:,k);
  rMag      = sqrt(rG'*rG);
  rMagSq    = rMag^2;
  u         = rG/rMag;
  aOR       =  a/rMag;
  nu        = u(3);
  
  % C and S Hat are functions of r only
  % CHat(1) is equivalent to C~(0) in equations (index up)
  %------------------------------------
  cHat(1) = 1;
  sHat(1) = 0;
  cHat(2) = u(1);
  sHat(2) = u(2);
  for mB = 2:nM
	  mI       = mB + 1;
    % C~(m) = C~(1)*C~(m-1) - S~(1)*S~(m-1)
	  cHat(mI) = cHat(2)*cHat(mI-1) - sHat(2)*sHat(mI-1);
    % S~(m) = S~(1)*C~(m-1) - C~(1)*S~(m-1)
	  sHat(mI) = sHat(2)*cHat(mI-1) + cHat(2)*sHat(mI-1);
  end

  % p(1,1) is equivalent to P(0,0) in equations (index up)
  % Variables nI, mI are used to index into p (index of P plus 1)
  % p(n,m) is a function of nu only
  %--------------------------------
  p      = zeros(nN+1,nM+2);
  p(1,1) = 1;   % n = 0, m = 0
  p(2,1) = nu;  % n = 1, m = 0
  p(1,2) = 0;  	% n = 0, m = 1
  p(2,2) = 1;  	% n = 1, m = 1
  
  % m = 0
  mB = 0;
  mI = mB + 1; % index up
  for nB = 2:nN
    nI       = nB + 1; % index up into p
    % P(n,0) = (1/n)*{(2n-1)*nu*P(n-1,0) - (n-1)*P(n-2,0)}
    p(nI,1)	 = ((2*nB-1)*nu*p(nI-1,mI) - (nB-1)*p(nI-2,mI))/nB;
  end
    
  % m > 0
  for nB = 2:nN
	  nI = nB + 1;
	  for mB = 1:nM+1
	    mI       = mB + 1;
      % P(n,m) = P(n-2,m) - (2n-1)*P(n-1,m-1)}
	    p(nI,mI) = p(nI-2,mI) + (2*nB-1)*p(nI-1,mI-1);
    end
  end
  
  dVNM = [0;0;0];
  dVMZ = [0;0;0];

  for nB = 2:nN  % symbolic degree index - zonals (0 to max)
    nI      = nB + 1; % index up
	  
    % m = 0
    %------
    mB       = 0;      % symbolic order index - tesseral/sectorial
    mI       = mB + 1; % index up
    rK       = rNM(nB,mI);
    %  CCpSC = C(n,m)*C~(m) + S(n,m)*S~(m)
    cS       = c(nB,mI)*cHat(mI) + s(nB,mI)*sHat(mI); % SJT c(nI,mI), s(nI,mI)
    % H(n,m) = CCpSC * P(n,m+1)
    hNM      = cS*(rK*p(nI,mI+1)); % rK*p
    % B(n,m) = CCpSC * (n + m + 1) * P(n,m)
    bNM      = (nB+mB+1)*cS*(rK*p(nI,mI)); % rK*p
    dVM      = -u*(nu*hNM + bNM) + [0;0;hNM];
    dVMZ     = dVMZ + dVM*aOR^nB;
    dVM      = [0;0;0];

    % m > 0
    %------
    for mB = 1:nM 
      mI  = mB + 1;
      rK	= rNM(nB,mI); % nI,mI

      cNM = c(nB,mI); % SJT c(nI,mI)
      sNM = s(nB,mI); % SJT s(nI,mI)
      pNM = rK*p(nI,mI);
      cM1 = cHat(mI-1);
      sM1 = sHat(mI-1);
      cS  = cNM*cHat(mI) + sNM*sHat(mI);

      hNM =          cS*(rK*p(nI,mI+1));
      bNM =  (nB+mB+1)*cS*pNM;
      eNM = -mB*(cNM*sM1 - sNM*cM1)*pNM;
      dNM =  mB*(cNM*cM1 + sNM*sM1)*pNM;
      
      dVM = dVM - u*(nu*hNM + bNM) + [dNM;eNM;hNM];

    end
    dVNM = dVNM + dVM*aOR^nB;
  end
  aZ(:,k)   =  mu*dVMZ/rMagSq;
  aS(:,k)   = -mu*   u/rMagSq;
  aT(:,k)   =  mu*dVNM/rMagSq;
  dVDR(:,k) = aS(:,k) + aT(:,k) + aZ(:,k);
end

if( nargout == 0 )
  Plot2D(1:size(r,2),dVDR,'Step',['aX';'aY';'aZ'],'Gravitational Acceleration');
else
  aG = dVDR;
end


%--------------------------------------
% $Date: 2019-12-16 15:59:31 -0500 (Mon, 16 Dec 2019) $
% $Revision: 50604 $
