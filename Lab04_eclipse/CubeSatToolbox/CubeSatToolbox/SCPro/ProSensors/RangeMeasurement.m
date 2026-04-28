function [range, rangeRate] = RangeMeasurement( r, v, c, rSource, vSource )

%% Computes range and range rate measurements.
%
%--------------------------------------------------------------------------
%   Form:
%   [r, rRate] = RangeMeasurement( r, v, c, rSource, vSource )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   r           (3,:)  Position           
%   v           (3,:)  Velocity  
%   c           (2,:)  Clock errors [bias;bias drift]
%   rSource     (3,1)  Position of source           
%   vSource     (3,1)  Velocity of source        
%
%   -------
%   Outputs
%   -------
%   range       (1,:)  Range
%   rangeRate   (1,:)  Range rate
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2001 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 3.
%--------------------------------------------------------------------------

n         = size(r,2);
m         = size(rSource,2);
if n > 1
rR        = r - DupVect(rSource,n);
vR        = v - DupVect(vSource,n);
elseif m > 1
  rR        = DupVect(r,m) - rSource;
  vR        = DupVect(v,m) - vSource;
else
  rR        = r - rSource;
  vR        = v - vSource;
end  

range     = Mag(rR) + c(1,:);
rangeRate = Dot(rR,vR)./range + c(2,:);

%--------------------------------------
% $Date: 2019-12-08 19:16:35 -0500 (Sun, 08 Dec 2019) $
% $Revision: 50525 $
