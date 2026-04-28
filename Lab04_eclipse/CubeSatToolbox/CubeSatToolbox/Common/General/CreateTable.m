function CreateTable( x, fileName, fString, sep )

%% Creates a table from x for displaying to the command line. 
%   x may be a two dimensional cell array or a matrix.
%   Based on CreateLatexTable and CreateHTMLTable but without the tags.
%--------------------------------------------------------------------------
%   Forms:
%   CreateTable( x )
%   CreateTable( x, fileName, fString )
%   CreateTable( x, fId, fString, sep )
%--------------------------------------------------------------------------

%
%   ------
%   Inputs
%   ------
%   x               {:,:} or (:,:) Cell array or matrix
%   fileName or fId (:)            File name or file id, default is 1
%   fString         (1,:)          Number format string
%   sep             (1,1)          Separation character, '-'
%
%   -------
%   Outputs
%   -------
%   None
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2003 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

if( nargin < 2 )
  fileName = 1;
end

if( nargin < 3 )
  fString = [];
end

if( nargin < 4 )
  sep = '-';
end

if( nargin < 1 )
  x     = {'Force', 12.4, 'N';'Torque', 29.33, 'Nm'};
  title = 'Disturbances';
  fileName = 'Test';
  CreateTable( x, fileName, [], title );
  return
end

if( ischar(fileName) )
  if( strfind(fileName,'.txt') )
    fId = fopen(fileName,'wt' );
  else
	fId = fopen([fileName '.txt'],'wt' );
  end
else
  fId = fileName;
end

if( isempty(fString) )
  fString = '%12.4g';
end

sz = ColumnSizeCellArray(x,12);

if( iscell(x) )
  for j = 1:size(x,1)
    % Row
    for k = 1:size(x,2)
      % Column
      wd = num2str(sz(k));
      if( ischar( x{j,k}) )
        y = x{j,k};
      else
        y = sprintf(fString,x{j,k});
      end
      if( k == 1 )
        fprintf(fId,['%' wd 's'],y);
      else
        fprintf(fId,[' ' sep ' %' wd 's '],y);
      end
    end
    fprintf(fId,'\n');
  end
else
  % Numeric matrix
  for j = 1:size(x,1)
    % Row
	  for k = 1:size(x,2)
      % Column
      wd = num2str(sz(k));
	    y = sprintf(fString,x(j,k));
      if( k == 1 )
	      fprintf(fId,['%' wd 's'],y);
      else
	      fprintf(fId,[' ' sep ' %' wd 's '],y);
      end
	  end
	  fprintf(fId,'\n');
  end
end

if( ischar(fileName) )
  fclose(fId);
end


%--------------------------------------
% $Date: 2019-11-06 22:17:12 -0500 (Wed, 06 Nov 2019) $
% $Revision: 50237 $
