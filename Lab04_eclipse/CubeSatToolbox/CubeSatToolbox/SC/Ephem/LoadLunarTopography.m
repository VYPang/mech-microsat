function [s,c] = LoadLunarTopography( nH )

%% Reads in the Clementine data.
%   It will automatically read the file gltm2b.topo.
%   If no output arguments are found it will create a file Topography.txt
%   with the s and c coefficients.
%--------------------------------------------------------------------------
%   Form:
%   [s,c] = LoadLunarTopography( nH )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   nH            (1,1)  Highest harmonic 
%
%   -------
%   Outputs
%   -------
%   s             (:,:)  Normalized sine coefficients
%   c             (:,:)  Normalized cosine coefficients
%
%--------------------------------------------------------------------------
%   Reference: Smith, D. E., Zuber, M. T., Neumann, G. A., "Topography of
%              the Moon from the Clementine lidar", Journal of Geophysical
%              Research, Vol. 102, No. E1, pp. 1591-1611, January 25, 1997.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2007 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

% Limit the number of harmonics
%------------------------------
if( nargin < 1 )
  nH = 72;
elseif( nH > 72 )
  nH = 72;
  disp('Maximum number of harmonics is 72')
end

% Read in the data
%-----------------
fID    = fopen('gltm2b.topo','rt');
buffer = fscanf(fID,'%c',inf);
s      = sprintf('\n');
r      = sprintf('\r');
k1     = strfind(buffer,'GLTM2B') + 7;
k2     = strfind(buffer,s) - 1;
if( isempty(k2) )
  k2 = strfind(buffer,r)-1;
end
lH     = length(k1);
c      = zeros(nH+1,nH+1);
s      = zeros(nH+1,nH+1);

for k = 1:lH
  z      = sscanf(buffer(k1(k):k2(k)),'%i %i %e %e');
  i      = z(1)+1;
  j      = z(2)+1;
  c(i,j) = z(3);
  if( length(z) == 3 )
    s(i,j) = 0;
  else
    s(i,j) = z(4);
  end 
  if( (i == nH) && (j == nH) )
    break
  end
end

clear buffer;

% Normalize the coefficients
%---------------------------
for l = 0:nH
  for m = 0:l
    if( m > 0 )
      delta = 0;
    else
      delta = 1;
    end
  
    fM = Factorl(l-m);
    fP = Factorl(l+m);

    f  = sqrt( fM*(2*l+1)*(2-delta)/fP );

    s(l+1,m+1) = f*s(l+1,m+1);
    c(l+1,m+1) = f*c(l+1,m+1);
  end
end

c(1,1) = 1738000 + c(1,1);

if( nargout == 0 )

  % Create a table up to order 16
  %------------------------------
  if( nH > 16 )
    nH = 16;
  end

  f = fopen('TopographyTable.txt','w');
  fprintf(f,'%12s %12s %12s %12s\n','Degree', 'Order', 'CHat', 'SHat');
  for k = 1:nH
    for j = 1:k
      fprintf(f,'%12i %12i %12.0f %12.0f\n',k-1,j-1,c(k,j),s(k,j));
    end
  end
  fclose(f);
  clear s;
  edit('TopographyTable.txt')
end


% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 14:11:01 -0400 (Thu, 11 May 2017) $
% $Revision: 44563 $
