function [b, bK] = RotMat( angle, axis )

%% Generates a rotation matrix that transforms in the opposite direction
%   of the rotation. Angle may be one to three. Axis gives the order of
%   transformation. For example:
%
%   axis = [1;2;3]
%
%   then b = b(3)*b(2)*b(1)
%
%   and v            = b*v
%        unrotated        rotated
%
%   If angle has more than one column, then b will be
%
%   [b1, b2, b3, ..., bn]
%
%   and each row of bK will give the column indices of the 
%   corresponding transformation matrix. For example, to get the
%   3rd transformation matrix type
%
%   b(:,bK(3,:))
%
%--------------------------------------------------------------------------
%   Form:
%   [b, bK] = RotMat( angle, axis )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   angle       (:,n)            Angle (rad)
%   axis        (:,n)            Axis of rotation
%
%   -------
%   Outputs
%   -------
%   b           (3,n)            Transformation matrix
%   bK          (3,n)            Indexes to n
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1996 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

[rAx,cAx] = size(axis);
[rAn,cAn] = size(angle);

if( rAn ~= rAx )
  error('axis and angle must be have the same number of rows')
end

if( cAn ~= cAx )
  if( cAx == 1 )
    axis = DupVect(axis,cAn)';
  else
    error('The number of columns in axis must equal 1 or be equal to the number of columns in angle')
  end
end

c = cos(angle);
s = sin(angle);

for i = 1:cAn

  rC      = (3*i-2):3*i;
  bK(i,:) = rC;
  
  for k = 1:rAx

    if( axis(k,i) == 1 )
      bT = [1 0 0;0 c(k,i) -s(k,i);0 s(k,i) c(k,i)];
    elseif( axis(k,i) == 2 )
      bT = [c(k,i) 0 s(k,i);0 1 0;-s(k,i) 0 c(k,i)];
    elseif( axis(k,i) == 3 )
      bT = [c(k,i) -s(k,i) 0;s(k,i) c(k,i) 0;0 0 1];
    else
      error(['Axis ',num2str(axis(k,i)), 'is not defined'] )
    end
  
    if( k == 1 )
      b(:,rC) = bT;
    else
      b(:,rC) = b(:,rC)*bT;    % to rotate B = B3*B2*B1 => B'=B1'*B2'*B3'
    end
  end
end

%--------------------------------------
% $Date: 2019-12-27 11:31:14 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50720 $
