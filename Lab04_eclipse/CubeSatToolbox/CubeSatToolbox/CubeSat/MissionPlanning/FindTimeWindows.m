function window = FindTimeWindows( t, x, lim )

%% Find time windows when elements of vector x are within specified range
% Type FindTimeWindows for a demo.
%--------------------------------------------------------------------------
%   Form:
%   window = FindTimeWindows( t, x, lim );
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   t           (1,N)   N time points
%   x           (M,N)   Set of M variables across N time points
%   lim         (1,2)   Time window limits (min,max)
%
%   -------
%   Outputs
%   -------
%   window       (.)    Data structure array with window information.
%                       Each element "i" of this array is for a different
%                       row of the x matrix. Fields are:
%                  .nObs:       (1,1)     Number of observations (windows)
%                  .window:     (nObs,2)  Each row is a new time window
%                  .time:       {1,nObs}  Time vectors from t inside each window
%                  .x:          {1,nObs}  Data vectors from x(i,:) inside each window
%                  .indexStart  (1,nObs)  Starting time index for window
%                  .indexEnd    (1,nObs)  Ending time index for window
%
%--------------------------------------------------------------------------
%  See also: ObservationTimeWindows
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2010 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 9.
%   2019.1 Added demo
%--------------------------------------------------------------------------

% Demo
if( nargin < 1 )
  t = linspace(0,100,10);
  x = rand(2,10);
  lim = [2 90];
  FindTimeWindows( t, x, lim )
  return
end

n = length(t);
[rx,cx] = size(x);
if( rx==n && cx~=n )
   nx = cx;
   x = x';  % transpose so x columns go with time
elseif( cx==n && rx~=n )
   nx = rx;
elseif( cx~=n && rx~=n )
   error('Inconsistent sizes for t and x. Matrix x must have either same # rows or same # cols as length t.')
else
   % cx == rx == n
   nx = rx;
   % assume x columns go with time
end

window(nx) = struct('nObs',0,'window',[],'time',{[]},'x',{[]},'indexStart',0,'indexEnd',0);
for i=1:nx
   
   % first find discrete times that are within limits
   k = find( x(i,:)>=lim(1) & x(i,:)<=lim(2) );
      
   % jumps in index array distinguish different windows
   if( length(k)>1 )
      
      dk = diff(k);
      dkm = [find(dk>1),length(dk)];
      dkm(end) = dkm(end)+1;
      nWin = length(dkm);
      
      vec    = k(1):k(dkm(1));
      window(i).nObs = nWin;
      index{i}{1} = vec; %#ok<AGROW>
 

      for j=2:nWin
         vec = k(dkm(j-1)+1) : k(dkm(j));
         index{i}{j} = vec;                 
      end
      
      for j=1:nWin
         % find entry and exit times         
         ind1 = index{i}{j}(1);
         if( ind1==1 )
           t1 = t(1,1);
         elseif( x(i,ind1-1)<=lim(1,1) )
           % x crossing lower limit
           t1 = t(1,ind1-1) + (t(1,ind1)-t(1,ind1-1))/(x(i,ind1)-x(i,ind1-1)) * (lim(1,1)-x(i,ind1-1));
         elseif( x(i,ind1-1)>=lim(1,2) )
           % x crossing upper limit
           t1 = t(1,ind1-1) + (t(1,ind1)-t(1,ind1-1))/(x(i,ind1)-x(i,ind1-1)) * (lim(1,2)-x(i,ind1-1));
         end
         
         ind2 = index{i}{j}(end);
         if( ind2==n )
           t2 = t(1,n);
         elseif( x(i,ind2+1)<=lim(1,1) )
           % x crossing lower limit
           t2 = t(1,ind2) + (t(1,ind2+1)-t(1,ind2))/(x(i,ind2+1)-x(i,ind2)) * (lim(1,1)-x(i,ind2));
         elseif( x(i,ind2+1)>=lim(1,2) )
           % x crossing upper limit
           t2 = t(1,ind2) + (t(1,ind2+1)-t(1,ind2))/(x(i,ind2+1)-x(i,ind2)) * (lim(1,2)-x(i,ind2));
         end
                  
         window(i).window(j,:) = [t1 t2];
         window(i).time{j} = unique([t1 t(ind1:ind2) t2]);
         window(i).x{j} = interp1( t, x(i,:), window(i).time{j} );
         window(i).indexStart(j) = ind1;
         window(i).indexEnd(j)   = ind2;
                  
      end
      
      
   else
      
      window(i).nObs = 0;
      window(i).window = [];
      window(i).time = {};
      window(i).x = {};
      window(i).indexStart = 0;
      window(i).indexEnd   = 0;
      
   end
   
end
   
%--------------------------------------
% $Date: 2020-06-19 15:04:48 -0400 (Fri, 19 Jun 2020) $
% $Revision: 52850 $

