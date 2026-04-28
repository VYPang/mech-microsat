function [mag, phase, w, io] = FResp( a, b, c, d, iu, iy, w, uPhase, pType )

%% Compute the frequency response of the system given a, b, c and d.
%   .
%   x = ax + bu
%   y = cx + du
%
%   for the input vector iu, and output vector iy. If no output arguments
%   are given it will automatically display Bode plots for all channels.
%
%   If only 1 output is requested, the complex values will be output.
%
%--------------------------------------------------------------------------
%   Form:
%   [mag, phase, w, io] = FResp( a, b, c, d, iu, iy, w, uPhase, pType )
%   [mag, phase, w, io] = FResp( num, den, w, uPhase, pType )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   a                   Plant matrix
%   b                   Input matrix
%   c                   Measurement matrix
%   d                   Input feedthrough matrix
%   iu                  Inputs  ( = 0, or leave out for all)
%   iy                  Outputs ( = 0, or leave out for all)
%   w            (1,:)  Frequency vector
%   uPhase       (1,:)  Unwrap phase = 'wrap' to wrap it within 180 deg
%   pType        (1,:)  'bode' or 'nichols'
%
%   -------
%   Outputs
%   -------
%   mag                 Magnitude vector
%   phase               Phase angle vector (deg)
%   w            (1,:)  Frequencies computed
%   io                  Input/output vector per plot [input,output;...]
%
%--------------------------------------------------------------------------
%   References: Laub, A., "Efficient Multivariable Frequency Response
%               Computations," IEEE Transactions on Automatic Control,
%               Vol. AC-26, No. 2, April 1981, pp. 407-408.
%               Maciejowski, J. M., Multivariable Feedback Design,
%               Addison-Wesley, Reading, MA, 1989, pp. 368-370.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993, 2019 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%   2019.1 Fixed titles for plots. Now they give correct inputs and 
%   outputs. Added a demo.
%--------------------------------------------------------------------------

% Demo
if( nargin < 1 )
  FResp( [0 1;-1 0], [1;0], [1 0], 0, 1, 1 );
  return
end

% Check arguments
%----------------
if( isa( a, 'statespace' ) )
   if ( nargin < 2 )
      iu = [];
   end

   if( nargin < 3 )
      iy = [];
   end

   if( nargin < 4 )
      w = [];
   end

   if( nargin < 5 )
      uPhase = [];
   end

   if( isempty(uPhase) )
      uPhase = 'wrap';
   end

   if( nargin < 6 )
      pType = 'bode';
   else
      pType = lower(pType);
   end

   f = a;

   [a,b,c,d] = getabcd( f );

   if( strcmp( get(f, 'type' ), 's') )
      if( isempty( w ) )
         [g,cb,w] = GSS( a, b, c, d, iu, iy );
      else
         [g,cb,w] = GSS( a, b, c, d, iu, iy, w );
      end
   else
      [num,den] = SS2ND( a, b, c, d, iu );
      cb        = length( iu );
      dT        = get( f, 'dT' );
      if( isempty( w ) )
         [g, w] = ZFresp( num(iy,:), den);
      else
         [g, w] = ZFresp( num(iy,:), den, dT*w );
      end
   end


else
   if ( nargin < 2 )
      error('Insufficient number of arguments')
   end

   if( nargin < 8 )
      uPhase = [];
   end

   if( nargin < 9 )
      pType = [];
   end

   if( isempty(uPhase) )
      uPhase = 'wrap';
   end

   if( isempty(pType) )
      pType = 'bode';
   end

   pType = lower(pType);

   % If a state-space model go through the first path
   %-------------------------------------------------
   if     ( nargin == 1 )
      error('Insufficient number of arguments')
   elseif ( nargin == 2 )
      [g,cb,w] = GND(a,b);
   elseif ( nargin == 3 )
      [g,cb,w] = GND(a,b,c);
   elseif ( nargin == 4 )
      [g,cb,w] = GSS(a,b,c,d);
   elseif ( nargin == 5 )
      [g,cb,w] = GSS(a,b,c,d,iu);
   elseif ( nargin == 6 )
      [g,cb,w] = GSS(a,b,c,d,iu,iy);
   elseif ( nargin > 6 )
      [g,cb,w] = GSS(a,b,c,d,iu,iy,w);
   end
end

rc = size(g,1);
n       = length(w);
nplots  = cb*rc;

if( nargout > 0 )
   ny = 1;
   nu = 1;
   ix = 0:n-1;
   for i=1:nplots
      v = ix*cb + nu;
      if ( nargout > 1 )
         lg = length(g(ny,v));
         if ( norm(g(ny,v)) > eps*lg )
            mag(i,:)   = abs(g(ny,v));
            if( strcmp(uPhase(1:4),'wrap'))
               phase(i,:) = (180/pi)*angle(g(ny,v));
            else
               phase(i,:) = (180/pi)*unwrap( angle(g(ny,v)),3*pi/2 );
            end
            if( length(w) > 1 )
               pGP        = 90*(log10(mag(i,2))-log10(mag(i,1)))/log10(w(2)/w(1));
               dP         = round((pGP - phase(i,1))/180)*180;
               phase(i,:) = phase(i,:) + dP;
            end
            io(i,:)    = [nu,ny];
         else
            mag(i,:)   = zeros(1,lg);
            phase(i,:) = NaN*ones(1,lg);
            io(i,:)    = [nu,ny];
         end
      else
         mag(i,:)   = g(ny,v);
         io(i,:)    = [nu,ny];
      end
      ny = ny + 1;
      if( ny > rc )
         ny = 1;
         nu = nu + 1;
      end
   end
elseif( nargout == 0 )
   ny = 1;
   nu = 1;
   ix = 0:n-1;
   for i=1:nplots
      v     = ix*cb + nu;
      if ( norm(g(ny,v)) > eps*length(g(ny,v)) )
         magp  = 20*log10(  abs(g(ny,v)));
         if( strcmp(uPhase(1:4),'wrap'))
            phase = (180/pi)*angle(g(ny,v));
         else
            phase = (180/pi)*unwrap( angle(g(ny,v)), 0.95*pi );
         end
         if( length(w) > 1 )
            pGP   = (90/20)*(magp(2)-magp(1))/log10(w(2)/w(1));
            dP    = round((pGP - phase(1))/180)*180;
            phase = phase + dP;
         end

         yL    = ['Magnitude (db)';'Angle (deg)   '];
         if( nargin > 4 )
            pTitle = sprintf('Input %d to Output %d',iu(nu),iy(ny));
         else
            pTitle = sprintf('Input 1 to Output 1');
         end

         if( strcmp(pType(1:4),'bode'))
            Plot2D(w,[magp;phase],'Frequency (rad/sec)',yL,pTitle,['xlog';'xlog']);
         else
            % Nichols plot
            %-------------
            Plot2D(phase,magp,yL(2,:),yL(1,:),pTitle);
            hold on
            plot(-180,0,'xr');
            hold off

            % Print frequency labels
            %-----------------------
            if( length(w) > 5 )
               kP = floor( linspace(1,length(w),5) );
            else
               kP = 1:length(w);
            end

            for j = 1:length(kP)
               n = kP(j);
               TextS( phase(n), magp(n), sprintf('  w = %10.2e', w(n) ) );
            end
         end
         ny = ny + 1;
         if ( ny > rc )
            ny = 1;
            nu = nu + 1;
         end
      end
   end
end

%--------------------------------------
% $Date: 2020-06-10 17:27:43 -0400 (Wed, 10 Jun 2020) $
% $Revision: 52705 $
