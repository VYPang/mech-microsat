function [zeta, w, wR] = S2Damp( s )

%% Eigenvalues to damping and natural frequency.

%   Computes the damping ratios and natural frequency for a set
%   of eigenvalues of a continuous time plant.
%
%--------------------------------------------------------------------------
%   Form:
%   [zeta, w, wR] = S2Damp( s )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   s                   Eigenvalues
%
%   -------
%   Outputs
%   -------
%   zeta                Damping ratio
%   w                   Natural frequency
%   wR                  Resonant frequency
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

k    = find((abs(imag(s))>eps*real(s)) & (abs(s) > eps)); 
w    = s;
wR   = s;
zeta = zeros(size(s)); 

if ( ~isempty(k) )

  w(k)     =   abs(s(k));  
  zeta(k)  = - real(s(k))./w(k); 
  asq      =   1-2*zeta(k).^2; 
  inr      =   find(asq<10*eps); 
  Linr     =   length(inr); 
  if ( Linr > 0 )
    if ( Linr > 1 ) 
      asq(inr) = ones(size(inr));
    else
      asq(inr) = 1;
    end
  end
  wR(k) = w(k).*sqrt(asq);

end

%--------------------------------------
% $Date: 2017-05-02 11:55:12 -0400 (Tue, 02 May 2017) $
% $Revision: 44450 $
