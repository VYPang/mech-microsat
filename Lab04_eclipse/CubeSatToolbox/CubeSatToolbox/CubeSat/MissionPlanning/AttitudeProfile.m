function d = AttitudeProfile( d, varargin )

%% Build an attitude profile consisting of multiple overlapping modes.
% The first mode listed is the nominal mode. The attitude is defined
% according to this pointing mode by default. Additional modes are
% optional.
%
% Each mode defines the ECI-to-Body quaternion through the combination of
% primary and secondary alignments. The primary alignment directly aligns
% a body vector with an inertial target. The secondary alginment rotates
% about that primary body vector to align a second body vector with a
% second inertial vector as closely as possible.
%
% Each alignment can be defined as one of the following types, with the
% associated target data.
%
%   #  Alignment type      Target data
%   ====================================================================
%   1    'sun'                -
%   2    'nadir'              -
%   3    'orbitnormal'        -
%   4    'latlon'             [lat;lon]   Target latitude and longitude
%   5    'lvlh'               [x;y;z]     Target LVLH direction
%   6    'ueci'               [x;y;z]     Target ECI direction
%   7    'reci'               [x;y;z]     Target ECI point
%
%--------------------------------------------------------------------------
%   Form:
%   d = AttitudeProfileBuilder( d, mode1, mode2, mode3, ... );
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   d       (.)   Data structure with orbit and time information
%                    .jD0        (1,1)    Epoch Julian date
%                    .t          (1,:)    Time vector from jD0 (sec)
%                    .r          (3,:)    ECI position  (km)
%                    .v          (3,:)    ECI velocity (km/s)
%                 
%   mode1   (.)   Nominal Attitude Mode with fields:
%                    .type1      '...'    Primary alignment type
%                    .body1      (3,1)    Primary body vector to align
%                    .target1    (:,1)    Primary Target
%                    .type2      '...'    Secondary alignment type
%                    .body2      (3,1)    Secondary body vector to align
%                    .target2    (:,1)    Secondary target
%
%   mode2   (.)   Same as nominal mode but with additional field:
%                    .window     (:,2)    Time windows to use this mode
%   mode3
%   mode4
%    ...                    
%
%   -------
%   Outputs
%   -------
%   d       (.)   Data structure with added quaternion, and alignment info
%                    .jD0        (1,1)    Epoch Julian date
%                    .t          (1,:)    Time vector from jD0 (sec)
%                    .r          (3,:)    ECI position  (km)
%                    .v          (3,:)    ECI velocity (km/s)
%                    .el         (1,6)    Initial orbital elements
%                    .q          (4,:)    ECI-to-body quaternion
%                    .type1      (1,:)    # for primary alignment type
%                    .type2      (1,:)    # for secondary alignment type
%                    .rot        (1,:)    Rotation angle about primary body axis
%                    .sep        (1,:)    Separation angle from secondary target
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2009 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
% Since version 8.
%--------------------------------------------------------------------------

if( nargin<1 )
   
   % orbit and time information
   d.jD0 = Date2JD;
   d.t = 0:60:86400;
   d.el = [6800,pi/6,0,0,0,0];
   [d.r,d.v] = RVFromKepler( d.el, d.t );
   
   % nominal mode: nadir pointing with secondary orbit normal alignment
   a.type1  = 'nadir';
   a.body1   = [1;0;0];
   a.target1 = [];
   a.type2  = 'orbitnormal';
   a.body2   = [0;1;0];
   a.target2 = [];
   
   % next mode: lat/lon pointing with secondary orbit normal alignment
   b.type1  = 'latlon';
   b.body1   = [1;0;0];
   b.target1 = [0;pi/2];
   b.type2  = 'orbitnormal';
   b.body2   = [0;1;0];
   b.target2 = [];
   
   % compute observation windows for this target
   fov = pi;
   [track,obs] = ObservationTimeWindows( d.el, b.target1, d.jD0, d.t(end), fov );
   b.window    = obs.window;
   
   % build the profile
   d = AttitudeProfile( d, a,b );
   return;
end

modes = varargin;
n     = length(modes);

if( n==0 )
   return;
end

types = {'sun','nadir','orbitnormal','latlon','lvlh','ueci','reci','earth','moon'};

% First input is the nominal attitude mode. 
% If we are not in some other mode, then we are in this nominal mode.
mode = modes{1};

% compute inertial target vector for nominal mode
uT1 = ComputeTarget( d, mode.type1, mode.target1 );
uT2 = ComputeTarget( d, mode.type2, mode.target2 );

% compute ECI to body quaternion over full horizon
q0 = U2Q( uT1, mode.body1 );
[d.q,d.rot,d.sep]  = QAlign( q0, mode.body1, mode.body2, uT2 );

% record enumeration of types
d.type1 = StringMatch(mode.type1,types)*ones(size(d.t));
d.type2 = StringMatch(mode.type2,types)*ones(size(d.t));

% go through all other modes in reverse order
% so that high priority modes overwrite lower priority ones
b.jD0 = d.jD0;

for j=n:-1:2
   
   mode = modes{j};
   nWindows = size(mode.window,1);
   
   for k=1:nWindows
   
      % time, position and velocity over this window
      t1 = max(mode.window(k,1),d.t(1));
      t2 = min(mode.window(k,2),d.t(end));
      b.t = [t1, d.t(d.t>t1&d.t<t2), t2];
      b.r = interp1(d.t,d.r',b.t)';
      b.v = interp1(d.t,d.v',b.t)';
      
      % compute inertial target vector for nominal mode
      uT1 = ComputeTarget( b, mode.type1, mode.target1 );
      uT2 = ComputeTarget( b, mode.type2, mode.target2 );
      
      % compute ECI to body quaternion over this window
      q0 = U2Q( uT1, mode.body1 );
      [qk,rot,sep] = QAlign( q0, mode.body1, mode.body2, uT2 );
      
      % record enumeration of types
      type1 = StringMatch(mode.type1,types)*ones(size(b.t));
      type2 = StringMatch(mode.type2,types)*ones(size(b.t));

      % insert this segment into the attitude profile
      k1    = find(d.t<t1); 
      k2    = find(d.t>t2);
      d.t   = [d.t(k1),b.t,d.t(k2)];
      d.r   = [d.r(:,k1),b.r,d.r(:,k2)];
      d.v   = [d.v(:,k1),b.v,d.v(:,k2)];      
      d.rot = [d.rot(k1),rot,d.rot(k2)];
      d.sep = [d.sep(k1),sep,d.sep(k2)];
      d.q   = [d.q(:,k1),qk,d.q(:,k2)];
      d.type1 = [d.type1(k1),type1,d.type1(k2)];
      d.type2 = [d.type2(k1),type2,d.type2(k2)];
      
   end
end

% find any jumps between positvie / negative expressions of quaternion
d.q = RemoveQJumps( d.q );


function uT = ComputeTarget( d, align, target )

% compute the inertial alignment vector given the alignment type and target
% will return "uT" with size 3xN, where N is number of time points supplied

switch lower(DeBlankAll(align))
   case 'sun'
      uT = SunV1( d.jD0+d.t/86400.0, d.r );
   case {'nadir','earth'}
      uT = -Unit(d.r);
   case 'latlon'
      Re = 6378.14;
      rEF = LLAToECEF( [target;0], Re );
      uT = zeros(3,length(d.t));
      for j=1:length(d.t)
         m  = ECIToEF( JD2T( d.jD0+d.t(j)/86400.0 ) );
         uT(:,j) = Unit(m'*rEF - d.r(:,j));
      end
   case 'orbitnormal'
      uT = Unit(Cross(d.r,d.v));
   case 'lvlh'
      uT = Unit(QTForm( QLVLH(d.r,d.v), target ));
   case 'ueci'
      uT = DupVect( Unit(target), length(d.t) );
   case 'reci'
		uT = DupVect( Unit(target-d.r), length(d.t) );
  case 'moon'
    uT = MoonV1( d.jD0+d.t/86400.0, d.r );
end


function q = RemoveQJumps( q )

dq = diff(q,1,2);
[~,c] = find(abs(dq)>1);   % jumps larger than 1 must mean a sign switch
if( ~isempty(c) )
   % remove jumps by switching signs for every other segment between jumps
   c = [unique(c);size(q,2)];
   nJumps = length(c);
   for j=1:2:nJumps-1   % this makes j be 1,3,... to largest odd int < nJumps
      q(:,c(j)+1:c(j+1)) = -q(:,c(j)+1:c(j+1));
   end
end



%--------------------------------------
% $Date: 2019-09-07 15:22:51 -0400 (Sat, 07 Sep 2019) $
% $Revision: 49733 $
