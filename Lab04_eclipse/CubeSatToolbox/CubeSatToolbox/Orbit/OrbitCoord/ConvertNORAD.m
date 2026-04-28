function [x, n, t] = ConvertNORAD( a )

%% Convert NORAD TLE string into a data structure.
%   Can process two or three-line version of elements.
%--------------------------------------------------------------------------
%   Form:
%   x = ConvertNORAD( a )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   a		      (:,1)   Data, file name or string
%
%   -------
%   Outputs
%   -------
%   x            (n)  Data structure
%    .satelliteNumber  Object ID
%    .launchYear       Year (part of international designator)
%    .launchNumber     Launch number
%    .launchpiece      Launch piece
%    .epochYear        Two/one digit epoch year
%    .epochDay         Epoch day number
%    .n0Dot            1st Derivative of the Mean Motion (rad/min^2)
%    .n0DDot           2nd Derivative of the Mean Motion
%    .bStar            Adjusted ballistic coefficient
%    .i0               Inclination (rad)
%    .f0               Right Ascension of Ascending Node (rad)
%    .e0               Eccentricity
%    .w0               Argument of Perigee (rad)
%    .M0               Mean Anomaly (rad)
%    .n0               Mean Motion (rad/min)
%
%   The following fields are computed from the element data.
%    .ballisticCoeff   Ballistic coefficient (m2/kg)
%    .julianDate       Epoch Julian date
%    .fullLaunchYear   Four digit launch year
%    .sma              Semi-major axis (km)
%  
%   n          (1,1)   Number of element sets
%
%   t          (3,n)   Time information if present on second line
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%	  Copyright (c) 1997, 2008 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------

% Open the file using the standard dialog box
%--------------------------------------------
if( nargin < 1 || isempty(a) )
  [file,path] = uigetfile('*.*','NORAD Datafiles');
  if( file == 0 )
    return
  end
  a = fullfile(path,file);
end

% Determine if the input is a file or a string containing the 2 line elements
%----------------------------------------------------------------------------
jCR = findstr( char(10), a );
jLF = findstr( char(13), a );
if( isempty(jCR) && isempty(jLF ) )
  file = a;
  [fid,message] = fopen(file,'rt');
  if( fid == -1 )
    error(message);
  end
  sElement = fread( fid );
else
  sElement = double(a)';
end

kpi      = 3.14159265358979323846;
degToRad = kpi/180;
dayToMin = 1440;
rE       = 6378.135;

% Carriage returns and line feeds
%--------------------------------
kNL = find( sElement == 10 );
kCR = find( sElement == 13 );

% Two or three-line format
%-------------------------
threeLine = 0;
firstNum = str2num(char(sElement(1)));
if isempty(firstNum)
  threeLine = 1;
end

if( isempty(kNL) )
  kLL = [kCR-1;length(sElement)];
  kNL = [1; kCR+1];
elseif( isempty(kCR) )
  kLL = [kNL-1;length(sElement)];
  kNL = [1; kNL+1];
else
  kLL = [min(kNL,kCR)-1;length(sElement)];
  kNL = [1; max(kNL,kCR)+1];
end

if threeLine
  n = length(kNL)/3;
else
  n = length(kNL)/2;
end
% drop an empty line at the end of the file
n = floor(n);
t = zeros(3,n);
x = DefaultStruct( n );
twopi = 2*kpi;

% Constants for mean motion/sma
j2        =    1.082616e-3;
aE        =    1.0;
k2      = 0.5*j2*aE^2;
kE      =    0.743669161e-1;
dayMin2 = dayToMin^2;
dayMin3 = dayToMin^3;

for k = 1:n
  if threeLine
    l1 = kNL(3*k-2);
    l2 = kNL(3*k-1);
    l3 = kNL(3*k);
    e1 = kLL(3*k-2);
    e2 = kLL(3*k-1);
    e3 = kLL(3*k);
    x(k).name = char(sElement(l1:e1)');
    a2        = char(sElement(l2:e2)');
    a3        = char(sElement(l3:e3)');
  else
    l2 = kNL(2*k-1);
    l3 = kNL(2*k);
    e2 = kLL(2*k-1);
    e3 = kLL(2*k);
    a2        = char(sElement(l2:e2)');
    a3        = char(sElement(l3:e3)');
    x(k).name = '';
  end
  
  % Line 1
  %-------
  x(k).satelliteNumber  = str2double(a2( 3: 7));
  x(k).launchYear       = str2double(a2(10:11));
  x(k).launchNumber     = str2double(a2(12:14));
  x(k).launchpiece      = a2(15:17);
  x(k).epochYear        = str2double(a2(19:20));
  x(k).epochDay         = str2double(a2(21:32));
  x(k).n0Dot            = str2double(a2(34:43))*twopi/dayMin2;
  x(k).n0DDot           = Str2NumE(a2(45:52))*twopi/dayMin3/1e5;
  x(k).bStar            = Str2NumE(a2(54:61))/1e5;
  x(k).elementNum       = 1;
  if length(a2) >= 68
    x(k).elementNum       = str2double(a2(65:68));
  end

  % Line 2
  %-------
  x(k).i0             =  str2double(a3(9:16))*degToRad; % 9 tp 16
  x(k).f0             =  str2double(a3(18:25))*degToRad; % 18 to 25
  x(k).e0             =  str2double(a3(27:33))/1e7; % 27 to 33
  x(k).w0             =  str2double(a3(35:42))*degToRad; % 35 to 42
  x(k).M0             =  str2double(a3(44:51))*degToRad; % 44 to 51
  x(k).n0             =  str2double(a3(53:63))*twopi/dayToMin; % 53 tp 63
  x(k).orbitRev       =  1;
  if length(a3) >= 68
    x(k).orbitRev       =  str2double(a3(64:68)); % 64-68
  end
  
  if length(a3) > 70
    % get time in Vallado format at end of line 2
    [tt,a3]               =  strtok(a3(70:end));
    t(1,k)                =  str2double(tt);
    [tt,a3]               =  strtok(a3);
    t(2,k)                =  str2double(tt);
    t(3,k)                =  str2double(strtok(a3));
  end
  
  % Computed values
  %----------------
  % add ballistic = bStar*2/rho0
  % rho0 = 2.461 x 10 -5  XKMPER kg/m2 /Earth radii
  x(k).ballisticCoeff = x(k).bStar*2/2.461e-5/rE;
  % Have to assume a century
  if x(k).launchYear < 50
    year = 2000 + x(k).launchYear;
  else
    year = 1900 + x(k).launchYear;
  end
  x(k).fullLaunchYear = year;
  % semi-major axis (unkozai)
  %x(k).sma = ( muEarth/(x(k).n0/60)^2 )^(1/3);
  cI0     = cos(x(k).i0);
  e0Sq    = x(k).e0^2;
  beta0   = sqrt(1 - e0Sq);
  a1      = (kE/x(k).n0)^(2/3);
  z       = (3*cI0^2 - 1)/beta0^3;
  d1      = 1.5*(k2/a1^2)*z;
  a0      = a1*(1 - d1/3 - d1^2 - (134/81)*d1^3);
  x(k).sma = a0*rE;
  
  if x(k).epochYear < 50
    year = 2000 + x(k).epochYear;
  else
    year = 1900 + x(k).epochYear;
  end
  x(k).julianDate = Date2JD(year) + x(k).epochDay - 1;

end

%-------------------------------------------------------------------------------
%   Convert input data in the form +NNNNN-N to a double precision number
%-------------------------------------------------------------------------------
%   Form:
%   x = Str2NumE( s )
%-------------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   s		      (1,8)   Data
%
%   -------
%   Outputs
%   -------
%   x         (1,1)   Number
%
%-------------------------------------------------------------------------------
function x = Str2NumE( s )

x  = str2double(s(1:6));
xE = str2double(s(7:8));

x  = x*10^xE;

%-------------------------------------------------------------------------------
%   Allocate default structure for speed
%-------------------------------------------------------------------------------
function x = DefaultStruct( n )

x = struct( ...
  'name'           , cell(1,n), ... % Object name
  'satelliteNumber', cell(1,n), ... % Object ID
  'launchYear'     , cell(1,n), ... % Year (part of international designator)
  'launchNumber'   , cell(1,n), ... % Launch number
  'launchpiece'    , cell(1,n), ... % Launch piece
  'epochYear'      , cell(1,n), ... % Two/one digit epoch year
  'epochDay'       , cell(1,n), ... % Epoch day number
  'n0Dot'          , cell(1,n), ... % 1st Derivative of the Mean Motion (rad/min^2)
  'n0DDot'         , cell(1,n), ... % 2nd Derivative of the Mean Motion
  'bStar'          , cell(1,n), ... % Adjusted ballistic coefficient
  'elementNum'     , cell(1,n), ... % element number
  'i0'             , cell(1,n), ... % Inclination (rad)
  'f0'             , cell(1,n), ... % Right Ascension of Ascending Node (rad)
  'e0'             , cell(1,n), ... % Eccentricity
  'w0'             , cell(1,n), ... % Argument of Perigee (rad)
  'M0'             , cell(1,n), ... % Mean Anomaly (rad)
  'n0'             , cell(1,n), ... % Mean Motion (rad/min)
  'orbitRev'       , cell(1,n), ... % Orbit revolution
  'ballisticCoeff' , cell(1,n), ... % Ballistic coefficient (m2/kg)
  'julianDate'     , cell(1,n), ... % Epoch Julian date
  'fullLaunchYear' , cell(1,n), ... % Four digit launch year
  'sma'            , cell(1,n) ); % Semi-major axis (km)

%--------------------------------------
% $Date: 2019-01-28 09:18:59 -0500 (Mon, 28 Jan 2019) $
% $Revision: 17946 $
