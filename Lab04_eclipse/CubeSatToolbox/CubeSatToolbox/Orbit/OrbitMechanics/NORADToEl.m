function [el, name, jD] = NORADToEl( dStart, dEnd, nPts, model, s )

%% Convert NORAD to Keplerian elements.
%   s can be a file name or a string input. The string must have the
%   same format as the file for example:
%
%   s = [sprintf('SGPTest \n'),...
%   sprintf('1 88888U          80275.98708465  .00073094  13844-3  66816-4 0     8\n'),...
%   sprintf('2 88888  72.8435 115.9689 0086731  52.6988  110.5714 16.05824518  105')];
%
%   A file may contain multiple sets of elements.
%
%--------------------------------------------------------------------------
%   Form:
%   [el, name, jD] = NORADToEl( jDStart, jDEnd, nPts, model, s )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   dStart        (1,1)   Days from Epoch of start
%   dEnd          (1,1)   Days from Epoch of end
%   nPts          (1,1)   Number of points
%   model         (1,:)   Model type 'SGP', 'SGP4', 'SDP4', 'SGP8', 'SGD8'
%   s             (1,:)   File name or string containing the two line elements
%                           * includes demo
%
%   -------
%   Outputs
%   -------
%   el            (:,6)   Elements vector [a,i,W,w,e,M]
%   name          {:}     Satellite name
%   jD            (1,1)   Julian day number
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2001-2003 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   2020.1 Added jD as an output
%--------------------------------------------------------------------------

if( nargin < 1 )
  s = [sprintf('HST\n'),...                    
       sprintf('1 20580U 90037B   01204.22157759  .00001766  00000-0  14691-3 0  6518\n'),...   
       sprintf('2 20580  28.4670 166.5350 0012416 329.1978  30.7878 14.94084709416384')];
  dStart = 0;
  dEnd   = 0.5;
  nPts   = 100;
  model  = 'sgp';
end

[rV,xN] = NORAD( dStart, dEnd, nPts, model, [], s );

jD = xN.julianDate;

n  = length(rV);
el = zeros(n,6);
for k = 1:n
  for j = 1:size(rV(k).r,2)
    elTemp(j,:) = RV2El( rV(k).r(:,j), rV(k).v(:,j) );
  end
  el(k,:) = mean(elTemp,1);
  el(k,6) = elTemp(1,6);
  name{k} = rV(k).name;
end

if( nargout == 0 )
  t = linspace(dStart,dEnd, nPts)*86400;
  
  for k = 1:length(rV)
    [r, v] = RVOrbGen( el(k,:), t );

    Plot2D( t, [r;rV(k).r], 'Time (sec)',['x';'y';'z'],   [rV(k).name ':Position'],'lin',['[1 4]';'[2 5]';'[3 6]']);
    legend('Kelperian','Norad')
    Plot2D( t, [v;rV(k).v], 'Time (sec)',['vX';'vY';'vZ'],[rV(k).name ':Velocity'],'lin',['[1 4]';'[2 5]';'[3 6]']);
    legend('Kelperian','Norad')
  end
  clear el
end


%--------------------------------------
% $Date: 2020-06-25 12:45:01 -0400 (Thu, 25 Jun 2020) $
% $Revision: 52888 $
