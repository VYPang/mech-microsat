function b = BHinge( bHinge )

%% Compute a transformation matrix from a bHinge data structure.
% There are four possiblities: 
%
%   1) You can just input a transformation matrix by entering only the b field. 
%   2) You can input a quaternion by just entering the q field. This supercedes
%      a b field.
%   3) You can input an angle and axis of rotation (1=x,2=y,3=z).
%      If no axis is specified, the rotation will be about the positive z-axis.
%      This supercedes a quaternion.
%   4) If you enter the angle field and the b field, the output transformation 
%      matrix will be the total rotation first through the angle about 
%      the specified axis followed by rotation through the initial b matrix. 
%      If no axis is specified, the rotation will be about the positive z-axis.
%
% They are executed in 
%--------------------------------------------------------------------------
%   Form:
%   b = BHinge( bHinge )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%
%   bHinge  (.)
%                 .b     (3,3) Transformation matrix
%                 .q     (4,1) Quaternion
%                 .angle (1,1) Angle of rotation (radians)
%                 .axis  (1,1) Axis of rotation 1=x, 2=y, 3=z (default)
%                               Positive integer means transform from
%                               unrotated to rotated, negative means reverse
%                               or
%                        (3,1) Axis of rotation - see AUToQ
%
%   -------
%   Outputs
%   -------
%   b            (3,3)  Rotation matrix
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1998 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 2.
%--------------------------------------------------------------------------

if ( isfield( bHinge, 'angle' ) )
  c  = cos(bHinge.angle);
  s  = sin(bHinge.angle);

  if( isfield( bHinge, 'axis' ) )
    if( length(bHinge.axis) < 3 )
      switch bHinge.axis
        case 1
          bI = [1  0 0;0 c -s; 0 s c];
        case 2
          bI = [c  0 s;0 1  0;-s 0 c];
        case 3
          bI = [c -s 0;s c  0; 0 0 1];
        case -1
          bI = [1  0 0;0 c  s; 0 -s c];
        case -2
          bI = [c  0 -s;0 1  0; s 0 c];
        case -3
          bI = [c  s 0;-s c  0; 0 0 1];
      end
     else
       bI = Q2Mat( AU2Q( bHinge.angle, bHinge.axis ) );
     end
  else
    bI = [c -s 0;s c 0; 0 0 1];
  end

  if( IsValidField( bHinge, 'b' ) )
    b = bHinge.b*bI;
  else 
    b = bI;
  end

elseif( isfield( bHinge, 'q' ) )
  b = Q2Mat( bHinge.q );
  if( IsValidField( bHinge, 'b' ) )
    b = bHinge.b*b;
  end
else
  b = bHinge.b;
end

%--------------------------------------
% $Date: 2020-06-01 15:16:12 -0400 (Mon, 01 Jun 2020) $
% $Revision: 52606 $
