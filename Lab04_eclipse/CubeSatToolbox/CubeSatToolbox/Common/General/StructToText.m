function StructToText( data, textFileName )

%% Write data structure to a text file or command line display. 
% The fields will be printed in order with the space-separated data starting
% on the next line, as in:
%
%     mass:
%     1.0
%
% Matrices are prepended with the size in rows and columns.
%
%     az (1,8):
%     0 0.785398 1.5708 2.35619 3.14159 3.92699 4.71239 5.49779 
%
% Small column vectors will be displayed as a transpose to save vertical
% space. This function gracefully displays function handles, cell arrays,
% strings, and matrices. For all other object types, disp is called.
%
% Passing in a 1 for textFileName will print the text to the command
% line, and this is the default behavior if no file name or fid is entered.
%-------------------------------------------------------------------------------
%   Form:
%   StructToText( data, textFileName )
%   StructToText( data, fid )
%-------------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   data             (.)   Data structure
%   textFileName     (:)   Name of text file to write to, or fid
%
%   -------
%   Outputs
%   -------
%   none
%
%-------------------------------------------------------------------------------

%-------------------------------------------------------------------------------
%   Copyright (c) 2015 Princeton Satellite Systems, Inc.
%   All rights reserved.
%-------------------------------------------------------------------------------
%   Since 2016.1
%-------------------------------------------------------------------------------
%%
if nargin == 0
  disp('StructToText demo')
  s = struct;
  s.a = 'string';
  s.b = rand(5,5);
  s.c = struct('first','data','second','more data');
  s.d = {'one','two',3};
  s.e = @StructToText;
  StructToText(s);
  return;
end
  
if nargin < 2
  textFileName = 1;
end

b = data;
if ~isstruct(b)
  error('PSS:StructToText','StructToText: input is not a data structure');
end

if ischar(textFileName)
  fid = fopen(textFileName,'wt');
else
  fid = textFileName;
end

prefix = '';
PrintStructure( b, fid, prefix );

fprintf(fid,'\n');

if fid > 2
  fclose(fid);
end

%--------------------------------------------------------------------------
% Print a data structure.
function PrintStructure( b, fid, prefix )

fn = fieldnames(b);

for k = 1:length(fn)
  v = getfield(b,fn{k});
  if isstruct(v)
    if (length(v) == 1)
      fprintf(fid,'%s: STRUCTURE\n',[prefix fn{k}]);
      prefixN = [prefix fn{k} '.'];
      PrintStructure( v, fid, prefixN );
    else
      for j = 1:length(v)
        if (j == 1)
          fprintf(fid,'%s: STRUCTURE ARRAY\n',[prefix fn{k}]);
        end
        prefixN = [prefix fn{k} '(' num2str(j) ').'];
        PrintStructure( v(j), fid, prefixN );
      end
    end
    %fprintf(fid,'%s: STRUCTURE END\n',fn{k});
  elseif iscell(v)
    r = size(v,1);
    c = size(v,2);
    fprintf(fid,'%s {%d,%d}:\n',[prefix fn{k}],r,c);
    for j = 1:r
      for m = 1:c
        PrintVariable([prefix fn{k}],v{j,m},fid);
      end
    end
  else
    PrintVariable([prefix fn{k}],v,fid);
  end
end

%--------------------------------------------------------------------------
% Print a plain variable. Cell arrays are handled externally.
function PrintVariable(name,v,fid)

if ischar(v)
  fprintf(fid,'%s:\n\t''%s''\n',name,v);
elseif isa(v,'function_handle')
  fprintf(fid,'%s:\n\t%s\n',name,func2str(v));    
elseif isnumeric(v)
  % matrix
  r = size(v,1);
  c = size(v,2);
  if (r==1) && (c==1)
    fprintf(fid,'%s:\n\t%g\n',name,v);
  elseif (r==0) || (c==0)
    fprintf(fid,'%s:\n\t[]\n',name);
  else
    fprintf(fid,'%s (%d,%d):\n',name,r,c);
    if (r==1) && c>3
      v = v';
      r = c;
    end
    if (c==1) && r<4
      v = v';
      r = 1;
    end
    for j = 1:r
      fprintf(fid,'\t%f ',v(j,:));
      fprintf(fid,'\n');
    end
  end
else
  % catchall: call disp for anything else
  T = evalc('disp(v)');
  fprintf(1,'%s:\n%s\n',name,T);
end


%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-22 17:28:15 -0400 (Mon, 22 May 2017) $
% $Revision: 44654 $
