function [X, GM] = InterpolateState( target, time, fileName )

%% Interpolate a planet's state for a given Julian Date.
% Uses the JPL ephemeris files. The returned state is measured from the solar
% system barycenter and in the Earth equatorial frame. Can be initialized with
% the binary file name by passing empty for the other inputs, then future calls
% may omit the file name. The initialization status can be checked with a single
% empty input.
%
% A binary file can be generated from a text file (ex. ascp2000.405) 
% using the tool EphemUtil, available via ftp:
%
%      ftp://ssd.jpl.nasa.gov//pub/eph/export/
%
% in the folder C-versions/hoffman. You must compile the tool for your
% system.
%
% Visit http://ssd.jpl.nasa.gov/?planet_eph_export for more information
% about these ephemerides.
%--------------------------------------------------------------------------
%   Form:
%   [X, GM] = InterpolateState( target, time, fileName )
%   status = InterpolateState( [], [], fileName )
%   status = InterpolateState( [] )
%--------------------------------------------------------------------------
%
%   1. Mercury
%   2. Venus
%   3. Earth-Moon Barycenter
%   4. Mars
%   5. Jupiter
%   6. Saturn
%   7. Uranus
%   8. Neptune
%   9. Pluto
%   10. Geocentric Moon
%   11. Sun
%
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   Target    (1,1)       Planet ID
%   Time      (1,1)       Julian date (days)
%   fileName   (:)        Binary file name if not initialized
%
%   -------
%   Outputs
%   -------
%   X         (6,1)       Planetary state vector, Earth mean equatorial frame
%   GM        (1,1)       Corresponding gravitational parameter (km3/s2)
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2006 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Sail SBIR #NNM06AA38C
%-------------------------------------------------------------------------------

persistent Ephemeris_File  T_beg  T_end  T_span  Coeff_Array  R1 GMi

if nargin == 0
  % Demo
  fileName = 'bin2000.405';
  target = 1;
  time = JD2000+365.5;
  X = InterpolateState( target, time, fileName );
  disp('State for Mercury on Jan 1, 2001') 
  disp(X)
  clear X
  return;
end

if (nargin == 3)
  if ~exist(fileName,'file')
    error('PSS:InterpolateState:error',...
      ['Failure find ' fileName ' for initializing InterpolateState']);
  end

  [status, R1, T_beg, T_end, T_span, GMi, Coeff_Array, Ephemeris_File] = Initialize_Ephemeris( fileName );
  if (~status)
    error('PSS:InterpolateState:error',...
      ['Failure to initialize InterpolateState with ' fileName]);
  end
end

% Check if function has been initialized
if isempty(target)
  if isempty(R1)
    X = 0;
  else
    X = 1;
  end
  return;
end

if (nargin < 2 || isempty(time))
  time = Date2JD;
end

if isempty(R1)
  error('PSS:InterpolateState:error',...
    'InterpolateState requires initialization before use, ex. InterpolateState([],[],''bin2000.405'')')
end

offset = 0;
T_seg = 0;
X = [];
printOut = 0;

% This function doesn't "do" nutations or librations.                      
%--------------------------------------------------------------------------
if ( target >= 12 )             % Also protects against weird input errors 
   disp('This function does not compute nutations or librations.');
   return;
end

% Initialize local coefficient array.                                      
%--------------------------------------------------------------------------
A = zeros(1,50);
B = zeros(1,50);

% Determine if a new record needs to be input.                             
%-------------------------------------------------------------------------- 
if (time < T_beg | time > T_end)  
  [T_beg, T_end, T_span, Coeff_Array] = ReadCoefficients(time, T_beg, T_end, T_span, Ephemeris_File);
end

% Read the coefficients from the binary record.                            
%--------------------------------------------------------------------------
C = R1.coeffPtr(target,1);   %    Coeff array entry point 
N = R1.coeffPtr(target,2);     %          Number of coeff's 
G = R1.coeffPtr(target,3);     % Granules in current record 

if ( printOut )
  fprintf('\n  In: Interpolate_State\n\n');
  fprintf('\n  Target = %2d\n',target);
  fprintf('\n  C      = %4d (before)\n',C);
  fprintf('\n  N      = %4d\n',N);
  fprintf('\n  G      = %4d\n\n',G);
end

%  Compute the normalized time, then load the Tchebeyshev coefficients     
%  into array A(). If T_span is covered by a single granule this is easy.  
%  If not, the granule that contains the interpolation time is found, and  
%  an offset from the array entry point for the ephemeris body is used to  
%  load the coefficients.                                                  
%--------------------------------------------------------------------------
if ( G == 1 )
   Tc = 2.0*(time - T_beg) / T_span - 1.0;
   for i = C:(C+3*N-1)
     A(i-C+1) = Coeff_Array(i);
   end
elseif ( G > 1 )
  % Compute subgranule interval
   T_sub = T_span/G;          

   for j = G:-1:1 
     T_break = T_beg + (j-1)*T_sub;
     if ( time >= T_break ) 
        T_seg  = T_break;
        offset = j-1;
        break;
     end
   end

   Tc = 2.0*(time - T_seg)/T_sub - 1.0;
   C  = C + 3*offset*N;

   for i = C:(C+3*N-1) 
     A(i-C+1) = Coeff_Array(i);
   end
else
  % Something has gone terribly wrong
  fprintf('\n Number of granules must be >= 1: check header data.\n\n');
end

if ( printOut )
   fprintf( '\n  C      = %4d (after) \n',C);
   fprintf( '\n  offset = %4d \n',offset);
   fprintf( '\n  Time   = %12.7f \n',time);
   fprintf( '\n  T_sub  = %12.7f \n',T_sub);
   fprintf( '\n  T_seg  = %12.7f \n',T_seg);
   fprintf( '\n  Tc     = %12.7f\n',Tc);
   disp('Array Coefficients:');
   disp(A);
   fprintf('\n\n\n');
end

% Compute the interpolated position & velocity                             
%--------------------------------------------------------------------------
for i = 1:3  
  % Allocate arrays
  Cp = zeros(1,N);
  Up = zeros(1,N);
  % Compute interpolating polynomials
  Cp(1) = 1.0;           
  Cp(2) = Tc;
  Cp(3) = 2.0 * Tc*Tc - 1.0;

  Up(1) = 0.0;
  Up(2) = 1.0;
  Up(3) = 4.0 * Tc;

  for j = 4:N
    Cp(j) = 2.0 * Tc * Cp(j-1) - Cp(j-2);
    Up(j) = 2.0 * Tc * Up(j-1) + 2.0 * Cp(j-1) - Up(j-2);
  end

  P_Sum(i) = 0.0;           % Compute interpolated position & velocity 
  V_Sum(i) = 0.0;

  for ( j = N:-1:1 )  
    P_Sum(i) = P_Sum(i) + A(j+(i-1)*N) * Cp(j); 
  end
  for ( j = N:-1:2 )  
    V_Sum(i) = V_Sum(i) + A(j+(i-1)*N) * Up(j); 
  end

  Position(i,1) = P_Sum(i);
  Velocity(i,1) = V_Sum(i)*2.0*G/(T_span*86400.0);
end

%  Return computed values.                                                 
%--------------------------------------------------------------------------
X = [Position;Velocity];
GM = GMi( target );

%--------------------------------------------------------------------------
%  Find ephemeris data that record contains input time. Note that one, and 
%  only one, of the following conditional statements will be true (if both 
%  were false, this function would not have been called).                  
%--------------------------------------------------------------------------
function [T_beg, T_end, T_span, Coeff_Array] = ReadCoefficients( Time, T_beg, T_end, T_span, Ephemeris_File )

% Assume 405 ephemeris
ARRAY_SIZE = 1018;

T_delta = 0.0;
Offset  =  0 ;

if ( Time < T_beg )                    % Compute backwards location offset 
   T_delta = T_beg - Time;
   Offset  = -ceil(T_delta/T_span); 
end

if ( Time > T_end )                    % Compute forewards location offset 
   T_delta = Time - T_end;
   Offset  = ceil(T_delta/T_span);
end

%  Retrieve ephemeris data from new record.                                
%--------------------------------------------------------------------------
dSize = 8; % 8 bytes and 64 bits
fseek(Ephemeris_File,(Offset-1)*ARRAY_SIZE*dSize,0);
Coeff_Array = fread(Ephemeris_File,ARRAY_SIZE,'double');
  
T_beg  = Coeff_Array(1);
T_end  = Coeff_Array(2);
T_span = T_end - T_beg;

%  Debug print (optional)                                                  
%--------------------------------------------------------------------------
if ( 0 ) 
  fprintf('\n  In: Read_Coefficients \n\n');
  fprintf('\n      ARRAY_SIZE = %4d\n',ARRAY_SIZE);
  fprintf('\n      Offset  = %3d\n',Offset);
  fprintf('\n      T_delta = %7.3f\n',T_delta);
  fprintf('\n      T_Beg   = %7.3f\n',T_beg);
  fprintf('\n      T_End   = %7.3f\n',T_end);
  fprintf('\n      T_Span  = %7.3f\n\n\n',T_span);
end

%--------------------------------------------------------------------------
%  Read header and store data
%--------------------------------------------------------------------------
function [status, R1, T_beg, T_end, T_span, GM, Coeff_Array, Ephemeris_File] = Initialize_Ephemeris( fileName )

% Assume 405 ephemeris
EPHEMERIS = 405;
ARRAY_SIZE = 1018;
headerID = 0;

% Initialize output in case of an error
%--------------------------------------
R1 = [];
T_beg = [];
T_end = [];
T_span = [];
Coeff_Array = [];
  
%  Open ephemeris file.                                                    
%--------------------------------------------------------------------------
Ephemeris_File = fopen(fileName,'r');
[fName, msg, machine_format] = fopen(Ephemeris_File);

%  Read header & first coefficient array, then return status code.         
%--------------------------------------------------------------------------
if ( Ephemeris_File < 0 ) % No need to continue 
  fprintf('\n Unable to open ephemeris file: %s.\n\n',fileName);
  status = 0;
  return;
else 

  %    struct recOneData {
  %          char label(3)(84);
  %          char constName(400)(6);
  %        double timeData(3);
  %      long int numConst;
  %        double AU;
  %        double EMRAT;
  %      long int coeffPtr(12)(3);
  %      long int DENUM;
  %      long int libratPtr(3);
  %      };

  % Read first three header records from ephemeris file
  %----------------------------------------------------
  % Data arrives as one column
  label = fread(Ephemeris_File,3*84,'char');
  R1.label = char(reshape(label,84,3)');
  constName = fread(Ephemeris_File,400*6,'char');
  R1.constName = char(reshape(constName,6,400)');
  R1.timeData = fread(Ephemeris_File,3,'double');
  R1.numConst = fread(Ephemeris_File,1,'long');
  R1.AU = fread(Ephemeris_File,1,'double');
  R1.EMRAT = fread(Ephemeris_File,1,'double');
  coeffPtr = fread(Ephemeris_File,12*3,'long');
  R1.coeffPtr = reshape(coeffPtr,3,12)';
  R1.DENUM = fread(Ephemeris_File,1,'long');
  R1.libratPtr = fread(Ephemeris_File,3,'long');
  % Rewind
  fseek(Ephemeris_File,0,-1);
  ARRAY_SIZE = 1018;
  H1 = fread(Ephemeris_File,ARRAY_SIZE,'double');
  H2 = fread(Ephemeris_File,ARRAY_SIZE,'double');
  Coeff_Array = fread(Ephemeris_File,ARRAY_SIZE,'double');

  % Set current time variables 
  T_beg  = Coeff_Array(1);
  T_end  = Coeff_Array(2);
  T_span = T_end - T_beg;
  
  % Gravity constants, include EMRAT for moon
  GM = [H2(9:17); H2(8); H2(18)];    % au^3/day^2

  % Convert header ephemeris ID to integer 
  headerID = R1.DENUM;

  % Debug Print (optional) 
  if ( 0 ) 
    fprintf('\n  In: Initialize_Ephemeris \n\n');
    fprintf('\n      ARRAY_SIZE = %4d\n',ARRAY_SIZE);
    fprintf('\n      headerID   = %3d\n',headerID);
    fprintf('\n      T_Beg      = %7.3f\n',T_beg);
    fprintf('\n      T_End      = %7.3f\n',T_end);
    fprintf('\n      T_Span     = %7.3f\n\n\n',T_span);
  end

  % Return status code 
  if ( headerID == EPHEMERIS )
   status = 1;
   return;
  else 
    fprintf('\n Opened wrong file: %s\n',fileName);
    fprintf(' for ephemeris: %d.\n\n',EPHEMERIS);
    fprintf(' headerID is %d.\n\n',headerID);
    status = 0;
    return;
  end
end


%--------------------------------------
% $Date: 2020-07-13 15:01:53 -0400 (Mon, 13 Jul 2020) $
% $Revision: 53036 $
