function [style, font, fSI] = PltStyle()

%% Edit this to globally change the plot styles for the plot labels
%--------------------------------------------------------------------------
%   Form:
%   [style, font, fSI] = PltStyle()
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   none
%
%   -------
%   Outputs
%   -------
%   style     Font style
%   font      Font
%   fSI       Font size increase (above default size)
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1995 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

global fontSizeIncrease

style = 'bold';
font  = 'Helvetica';
fSI = fontSizeIncrease;
if( isempty(fSI) )
   fSI = 0;
end

%--------------------------------------
% $Date: 2019-12-27 15:51:53 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50729 $
