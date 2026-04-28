function [el, jD0] = ISSOrbit

%% Generate Keplerian elements for the ISS
% Generates elements from a two-element set from April 1, 2020.
% Type ISSOrbit for a demo with a plot of the ISS ground track.
%--------------------------------------------------------------------------
%   Form:
%   [el, jD0] = ISSOrbit
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   None
%
%   -------
%   Outputs
%   -------
%   el    (1,6) Elements vector [a,i,W,w,e,M]
%   jD0   (1,1) Julian date of epoch
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2020 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 2020.1
%--------------------------------------------------------------------------

s = [ sprintf('ISS\n'),...                    
      sprintf('1 25544U 98067A   20092.51597385  .00016717  00000-0  10270-3 0  9025\n'),...   
    	sprintf('2 25544  51.6440   7.8556 0005107  74.2499 285.9214 15.48942018 20129')];
     
[el, ~, jD0] = NORADToEl(0,0,1,'sgp',s);
 
 if( nargout == 0 )
   [r, ~, t] = RVOrbGen( el );
   GroundTrack( r, t, jD0 );
   clear el
 end
 

%--------------------------------------
% $Date: 2020-06-25 12:45:01 -0400 (Thu, 25 Jun 2020) $
% $Revision: 52888 $


