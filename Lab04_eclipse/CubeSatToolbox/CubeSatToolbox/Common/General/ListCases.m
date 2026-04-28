function names = ListCases( filename, beQuiet, first )

%% List the switch cases that are included in a given file.
% The default is to print the full set of case names to the command line as
% well as provide an output. To suppress the command line display pass true
% for quiet.
%--------------------------------------------------------------------------
%   Form:
%   names = ListCases( filename, beQuiet, first )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   filename      (:)    String name of file to examine
%   beQuiet       (1)    Flag for quiet operation - no printout
%   first         (1)    Flag to keep only first case for a cell array 
%
%   -------
%   Outputs
%   -------
%   names         {:}   Cell array of case names
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%  Copyright (c) 2005 Princeton Satellite Systems, Inc.
%  All rights reserved.
%--------------------------------------------------------------------------

if( nargin < 1 )
   help(mfilename);
   return;
end
if (nargin <2 || isempty(beQuiet))
  beQuiet = false;
end
if nargin < 3
  first = false;
end

f = which(filename);
if( isempty(f) )
   error('PSS:Common',['"',filename,'" not found.'])
   return;
end

[fid,msg] = fopen(f,'rt');

if( fid == -1 )
   errordlg(sprintf('Attempt to open "%s" to read list of cases failed:\n%s',f,msg));
   return;
end

if (~beQuiet)
  fprintf(1,'\n%s has the following cases:\n',filename);
  fprintf(1,'=========================================================\n');
end

names = {};

while 1
   
   t = fgetl(fid);
   
   % if end of file reached...
   if( ~ischar(t) ), break; end
   
   % if end of the list of cases reached...
   stop = strfind(t,'otherwise');
   if( ~isempty(stop) ) 
      p = strfind(t,'%');
      if( isempty(p) || (~isempty(p) && p(1) > stop(1)) ), break; end
   end
   
   % look for "case"
   k = strfind(t,'case');
   
   % if "case" found
   if( ~isempty(k) )
      
      % look for "%"
      p = strfind(t,'%');
      
      showLine = 1;
      
      % if "%" found
      if( ~isempty(p) )
         % if "%" comes before "case"
         if( p(1) < k(1) )
            showLine = 0;
         end   
      end

      % display action
      if( showLine )
         if( ~isempty(p) )
            actionstr = deblank(t(k+5:p-1));
         else
            actionstr = deblank(t(k+5:end));
         end
         if actionstr(1) == '{'
           % cell array of cases
           action = eval(actionstr);
           if first
             action = action(1);
           end
         else
           action = {actionstr(2:end-1)};
         end
         if ~beQuiet
           fprintf('%s\n',actionstr);
         end
         names = [names action];
      end
      
   end
end
fclose(fid);

if(~beQuiet)
  fprintf('=========================================================\n');
end


%--------------------------------------
% $Date: 2019-12-27 14:31:09 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50728 $
