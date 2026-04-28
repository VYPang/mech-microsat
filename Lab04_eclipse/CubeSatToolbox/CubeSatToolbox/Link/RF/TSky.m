function t = TSky( f, e )

%% Brightness temperature of the sky.
%
%   Limited to frequencies between 2.5 and 60 GHz.
%
%   Type TSky for a demo.
%
%--------------------------------------------------------------------------
%   Form:
%   t = TSky( f, e )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   f            (1,n)  Frequency (GHz)
%   e            (1,m)  Elevation angle (deg)
%                        
%   -------
%   Outputs
%   -------
%   t            (n,m)  Temperature
%                        
%--------------------------------------------------------------------------
%   References:	Maral, G. and M. Bousquet. (1998.) Satellite Communications
%               Systems. Wiley. pp. 36.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2001, 2014 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

eT = [0 5 10 20 30 60 90];
fT = [2.5 5 10 15 20 22.5 25 30 35 40 45 50 55 60];

% Demo
%-----
if( nargin < 1 )
	f = linspace(2.5,60,1000);
  e = eT;
  TSky( f, e );
  return
end

j = find(f < fT(1) | f > fT(end), 1);
if( ~isempty(j) )
  error('Some frequencies are less than %4.1f GHz or greater than %4.1f GHz',fT(1),fT(end))
end


%      2.5  5   10    15  20 22.5  25  30  35  40  45  50  55  60
%----------------------------------------------------------------
tT = [  70 90  140   200 245  290 290 280 282 290 290 290 290 290;... %  0 deg
        18 22   30    53 130  190 140 120 135 160 220 285 290 290;... %  5 deg
         9 13   14.7  28  84  130  84  70  82 110 200 230 290 290;... % 10 deg
         5  6.4  9    15  44   70  70  38  45  60 150 190 290 290;... % 20 deg
         4  4.3  6.4  12  31   55  34  27  32  46  95 140 290 290;... % 30 deg
         2  2.5  3.8   7  11   32  20  15  20  26  42  90 290 290;... % 60 deg
         1  2.1  3.1   6   9   27  17  14  17  23  38  90 290 290];   % 90 deg
  
t = zeros(length(e),length(f));
for k = 1:length(e)
  j = find( e(k) == eT );
  if( isempty( j ) )
    j       = find( eT > e(k), 1 );
    t1      = interp1( fT, tT(j,  :), f );
    t2      = interp1( fT, tT(j+1,:), f );
    s       = (e(k) - eT(j))/(eT(j+1)-eT(j));
    t(k,:) = t1 + s*(t2-t1);
  else
    t(k,:) = interp1( fT, tT(j,:), f );
  end
end

% Plot if no outputs are specified
%---------------------------------
if( nargout == 0)
  Plot2D(f,t,'Frequency (GHz)','Brightness Temperature (deg-K)','TSky','ylog');
  if( length(f) > 1 )
    m = cell(1,length(e));
    for k = 1:length(e)
      m{k} = sprintf('E = %3.1f deg',e(k));
    end
    legend(m)
  end
  clear t;
end

%--------------------------------------
% $Date: 2019-09-05 20:12:10 -0400 (Thu, 05 Sep 2019) $
% $Revision: 49726 $


