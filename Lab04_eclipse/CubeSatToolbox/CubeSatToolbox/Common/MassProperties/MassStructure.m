function m = MassStructure( mass, type, info, cM )

%% Create a mass data structure.
%--------------------------------------------------------------------------
%   Form:
%   m = MassStructure( mass, type, info, cM )
%   m = MassStructure( mass, inr, cM )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   mass           (1,1)   Mass
%   type           (1,:)   Type of body or (3,3) Inertia matrix
%   info           (:,:)   Dimensions depends on type see Inertias
%   cM             (3,1)   Center-of-mass location
%
%   -------
%   Outputs
%   -------
%   m              (1,1)   Structure
%                          .mass     (1,1) mass
%                          .inertia  (3,3) Inertia matrix
%                          .cM       (3,1) Center of mass
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2002 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

m.mass = mass;

if( ischar( type ) )
  m.inertia = Inertias( mass, info, type, 1 );
  if( nargin > 3 )
	m.cM = cM;
  else
	m.cM = [0;0;0];
  end
else
  m.inertia = type;
  if( nargin > 2 )
	  m.cM = info;
  else
	  m.cM = [0;0;0];
  end
end


%--------------------------------------
% $Date: 2019-12-27 11:41:15 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50721 $
