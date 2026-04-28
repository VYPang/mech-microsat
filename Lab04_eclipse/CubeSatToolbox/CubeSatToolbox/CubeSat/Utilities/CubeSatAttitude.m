function q = CubeSatAttitude( d, r, v )

%--------------------------------------------------------------------------
%   Returns the CubeSat attitude quaternion from ECI to body.
%
%   There are two options. One is ECI in which case it just passes out
%   d.qECIToBody. For LVLH frame the routine computes the ECI to LVLH
%   quaternion from the entered r and v and multiplies that times
%   qLVLHToBody, to produce the qECIToBody.
%
%   This function is used when you don't want to simulate attitude
%   dynamics. There is an option to retrieve the default data structure. %
%   This sets both qLVLHToBody and qECIToBody to [1;0;0;0].
%   
%   Since version 8.
%--------------------------------------------------------------------------
%   Form:
%   q = CubeSatAttitude( d, r, v )
%   d = CubeSatAttitude
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   d         (.)    Data structure
%                    .type        (1,:) 'eci' or 'lvlh'
%                    .qLVLHToBody (4,1) Quaternion from LVLHToBody
%                    .qECIToBody  (4,1) Quaternion from ECI to body frame
%   r        (3,1)   ECI position vector
%   v        (3,1)   ECI velocity vector
%
%
%   -------
%   Outputs
%   -------
%   q        (4,1)   qECIToBody
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2009 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
  d = DefaultStruct;
  if( nargout == 1 )
    q = d;
    return;
  end
  q = CubeSatAttitude( d );
  disp(q);
  clear q
  return
end

switch( lower(d.type) )
    case 'eci'
        q = d.qECIToBody;
    case 'lvlh'
        q = QMult(QLVLH( r, v ), d.qLVLHToBody);
end

%-------------------------
function d = DefaultStruct

d.type          = 'eci';
d.qECIToBody    = [1;0;0;0];
d.qLVLHToBody   = [1;0;0;0];

%--------------------------------------
% $Date: 2019-09-06 11:24:45 -0400 (Fri, 06 Sep 2019) $
% $Revision: 49727 $
