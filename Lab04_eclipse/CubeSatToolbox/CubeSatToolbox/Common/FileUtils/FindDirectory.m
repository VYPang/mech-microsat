function p = FindDirectory( d, ~ )

%% Returns the path to a directory.
%--------------------------------------------------------------------------
%   Form:
%   p = FindDirectory( d )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   d        (1,:) Name of the directory
%
%   -------
%   Outputs
%   -------
%   p        (1,:) Path to the files in the directory OR
%            {:}   Cell array of paths if 'all' option is specified
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2000 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------

y  = path;
x  = lower(path);
d  = lower(d);

j  = strfind( x, pathsep );
k  = strfind( x, d  );

p = {};

for z = 1:length(k)

   k1 = max( find( j < k(z) ) );
   if( isempty(k1) )
     k1 = 1;
   else
     k1 = j(k1) + 1;
   end

   k2 = min( find( j > k(z) ) );
   if( isempty(k2) )
      k2 = length(x);
   else
      k2 = j(k2) - 1;
   end
   
   pTemp = x(k1:k2);
   
   s = strfind(pTemp,d)-1;
   s = s(end);
   if( s==0 )
      q = pTemp(1:length(d));
      r = d;
   else
      q = pTemp(s:s+length(d));
      r = [filesep, d];
   end
   
   if( strcmp(q,r) && length(pTemp)-s-1 <= length(d) )
      if nargin > 1
        p{end+1} = y(k1:k2); 
      else
        p = y(k1:k2); 
        break;
      end
   else
      clear pTemp;
   end

end

if isempty(p)
  p = '';
end

%--------------------------------------
% $Date: 2020-01-02 10:45:44 -0500 (Thu, 02 Jan 2020) $
% $Revision: 50823 $
