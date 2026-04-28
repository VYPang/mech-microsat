function PSSSetPaths( fast )

%------------------------------------------------------------------------
%   Sets up the paths
%------------------------------------------------------------------------
%   Form:
%   PSSSetPaths( fast )
%------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   fast   (1)   Flag for noninteractive version (doesn't save path)
%
%   -------
%   Outputs
%   -------
%   None
%
%------------------------------------------------------------------------

%------------------------------------------------------------------------
%   Copyright 1999-2003 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%------------------------------------------------------------------------

pathToToolbox = fileparts(which(mfilename));

cd( pathToToolbox )

p = cd;
path( fullfile(p,''), path );

s = dir;

np = {};
for k = 1:length(s)
   if( CheckValidDir( s(k) ) )
      z = fullfile( p, s(k).name, '' );
      np = AddDirectoryToPath( z, np );
   end
end

if( ~isempty(np) )
   addpath(np{:});
end

cd( pathToToolbox );


if( nargin > 0 ) % non-interactive version
   disp('Paths Set!');
else
   q1 = 'Save your additions to the MATLAB path?';
   q2 = 'If you save, you will not have to install these paths again.';
   a = questdlg(sprintf('%s\n%s',q1,q2),'Save Path?','Yes','No','Yes');
   switch lower(a)
      case 'yes'
         if( IsVersionAfter(6.5) )
            savepath;
         else
            path2rc;
         end
         disp(sprintf('\nYour path has been updated and saved.'));
      otherwise
         if( IsVersionAfter(6.5) )
            f = 'savepath';
         else
            f = 'path2rc';
         end
         disp(sprintf('Your path has been updated, but has not been saved.\nType "%s" to save your changes to the path.\n',f));
   end
end
         
%------------------------------------------------------------------------
%  Add directory to the path (recursive)
%------------------------------------------------------------------------
function np = AddDirectoryToPath( p, np )

s = dir( p );

np{end+1} = p;
for k = 1:length(s)
   if( CheckValidDir( s(k) ) )
      z = fullfile( p, s(k).name, '' );
      if( isempty(findstr( '@', z )) )
         np = AddDirectoryToPath( z, np );
      end
   end
end

%------------------------------------------------------------------------
%  Check MATLAB version
%------------------------------------------------------------------------
function t = IsVersionAfter( n )

v = version;
if( str2num(v(1:3)) > n )
  t = 1;
else
  t = 0;
end

%------------------------------------------------------------------------
%  Check that directory is valid
%------------------------------------------------------------------------
function isValid = CheckValidDir( s )

if( s.isdir && ...
    ~strcmp( '..', s.name ) && ...
    ~strcmp( '.', s.name ) && ...
    ~strcmpi('.svn',s.name) && ...
    ~strcmp( 'html', s.name ) && ...
    isempty(strfind(s.name,'Headers')) )
  isValid = 1;
else
  isValid = 0;
end



%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2012-08-20 16:47:04 -0400 (Mon, 20 Aug 2012) $
% $Revision: 30687 $
