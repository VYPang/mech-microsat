function z = TrnsZero( a, b, c, d )

%% Computes the transmission zeros of a plant
%
%   For continuous time systems.
%
%--------------------------------------------------------------------------
%   Form: z = TrnsZero( a, b, c, d )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   a                   Plant matrix
%   b                   Input matrix
%   c                   Measurement matrix
%   d                   Input feedthrough matrix
%
%   -------
%   Outputs
%   -------
%   z                   Transmission zeros
%
%--------------------------------------------------------------------------
%   References:   Maciejowski, J.M., Multivariable Feedback Design, 
%                 Addison-Wesley, 1989, pp. 386-389.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

% Check the dimensions of a, b, c and d for consistency

if ( SizeABCD(a,b,c,d)==0 )
  return;
end

% Create a value for rank tests

epsrank = 100*eps*norm([a,b;c,d]); 

% Create the system matrix

for i = 1:2

% First pass row compress, second pass column compress (dual)

if ( i==1 )
  ak = a;
  bk = b;
  ck = c;
  dk = d;
else
  ak = ak';
  bt = bk; 
  bk = ck'; 
  ck = bt'; 
  dk = dk'; 
end

% Need the number of inputs

p=size(bk,2); 

while (1)

  rdk = size(dk,1);

  abcd = [ak,bk;ck,dk]; 

  if ( rank(dk) == rdk || IsZero(ck) == 0 )
    break
  end

% Compute the svd of d and the svd of c0

if ( IsZero(dk) == 0 )
  c0        = ck;
  rcc = size(ck,1); 
  uh        = eye(rcc);
else
  [dh,uh]   = RowCompU(dk);  
  rdh       = size(dh,1); 
  rdk       = size(dk,1);
  cc        = uh*ck; 
  c0        = cc(rdh+1:rdk,:); 
end

[s1,q] = ColCompR(c0); 
if ( norm(s1) < epsrank )
  break
end 
 
cc0       = size(c0,2);
[rs1,cs1] = size(s1);
ia        = cc0 - cs1;

[rh,ch]   = size(uh);
[rq,cq]   = size(q);

pm        = [q',zeros(cq,rh);zeros(ch,rq),uh];  
am        = [q,zeros(rq,p);zeros(p,cq),eye(p)];  

abcd      = (pm*abcd)*am;   

[r,c]     = size(abcd);

ak        = abcd(  1:ia,1:ia);   
bk        = abcd(  1:ia,c-p+1:c);   
ck        = abcd(ia+1:r-rs1,1:ia);   
dk        = abcd(ia+1:r-rs1,c-p+1:c);   

end

end

arc = ak';   
brc = ck';  
crc = bk';   
drc = dk';

[rd,cd]=size(drc);

z = [];

if ( rd == cd && rd == 1 )
  if( drc ~= 0 )
  	z = eig(arc-brc*crc/drc); 
  end
else

% Row compress [brc;drc]

  x=svd([brc;drc]);  

% Reverse the ordering

  xh  = fliplr(x)'; 

  ra=size(arc,1);
  cs = size(abcd,2);

  xha = xh(1:ra,1:ra); 
  xhb = xh(1:ra,ra+1:cs);

  z   = eig(xha*arc+xhb*crc,xha);

end

%--------------------------------------
% $Date: 2017-05-02 12:34:43 -0400 (Tue, 02 May 2017) $
% $Revision: 44452 $
