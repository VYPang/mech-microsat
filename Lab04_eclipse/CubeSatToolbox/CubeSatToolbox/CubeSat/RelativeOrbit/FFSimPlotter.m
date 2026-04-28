function FFSimPlotter( d, myDirectory )

%% Plot the results from "FFSim". Finishes by setting up an animation.
%--------------------------------------------------------------------------
%   Usage:
%   FFSimPlotter( d, myDirectory );
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   d             (.)   Data structure output from FFMaintenanceSim
%   myDirectory   (:)   String name of directory to save figures to
%
%   -------
%   Outputs
%   -------
%   none
%   
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2002 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
% Since version 8.
%--------------------------------------------------------------------------

if( nargin < 1 )
   errordlg(sprintf('You must first run FFSim, which returns a data structure "d".\nThen you can pass "d" into this function to plot the results.'));
   return;
end

cd1 = cd;

saveFlag = 0;
if( nargin > 1 )
   if( isfolder(myDirectory) )
      cd(myDirectory);
      saveFlag = 1;
   else
      warndlg('The directory name you supplied was not found in the Matlab path.');
   end
end

c        = 'Time (orbits)';
lw       = 'linewidth';
t        = d.time;

% plot individual axes in Hill's frame
%-------------------------------------

NewFig('Radial Motion'),
plot(t,d.rH(1,:),t,d.rH_des(1,:),t,d.rH_est(1,:)), 
hold on,
title('Radial Motion','fontsize',12,'fontname','Arial');
   set(gca,'fontsize',12,'fontname','Arial');
   ylabel('x_H','fontsize',12,'fontname','Arial','rotation',eps,'horizontalalignment','right');   
   xlabel(c,'fontsize',12,'fontname','Arial');   
grid on, 
zoom on

NewFig('Along-Track Motion'),
plot(t,d.rH(2,:),t,d.rH_des(2,:),t,d.rH_est(2,:)), 
hold on,
title('Along-Track Motion','fontsize',12,'fontname','Arial');
   set(gca,'fontsize',12,'fontname','Arial');
   ylabel('y_H','fontsize',12,'fontname','Arial','rotation',eps,'horizontalalignment','right');   
   xlabel(c,'fontsize',12,'fontname','Arial');   
grid on, 
zoom on

NewFig('Cross-Track Motion'),
plot(t,d.rH(3,:),t,d.rH_des(3,:),t,d.rH_est(3,:)), 
hold on,
title('Cross-Track Motion','fontsize',12,'fontname','Arial');
   set(gca,'fontsize',12,'fontname','Arial');
   ylabel('z_H','fontsize',12,'fontname','Arial','rotation',eps,'horizontalalignment','right');   
   xlabel(c,'fontsize',12,'fontname','Arial');   
grid on, 
zoom on



% Measured                              Desired                                 Error
%-------------------------------------------------------------------------------------------------
mda   = d.dElMean(1,:)*1000;        dda   = d.dElMean_des(1,:)*1000;        eda   = mda   - dda;
mdth  = d.dElMean(2,:);             ddth  = d.dElMean_des(2,:);             edth  = mdth  - ddth;
mdi   = d.dElMean(3,:);             ddi   = d.dElMean_des(3,:);             edi   = mdi   - ddi;
mdq1  = d.dElMean(4,:);             ddq1  = d.dElMean_des(4,:);             edq1  = mdq1  - ddq1;
mdq2  = d.dElMean(5,:);             ddq2  = d.dElMean_des(5,:);             edq2  = mdq2  - ddq2;
mdlan = d.dElMean(6,:);             ddlan = d.dElMean_des(6,:);             edlan = mdlan - ddlan;

% Plot measured vs. desired
%--------------------------
h(1) = NewFig('FFSim'); plot(t,mda,   t,dda,   lw, 2 ); hold on, grid on, zoom on
h(2) = NewFig('FFSim'); plot(t,mdth,  t,ddth,  lw, 2 ); hold on, grid on, zoom on
h(3) = NewFig('FFSim'); plot(t,mdi,   t,ddi,   lw, 2 ); hold on, grid on, zoom on
h(4) = NewFig('FFSim'); plot(t,mdq1,  t,ddq1,  lw, 2 ); hold on, grid on, zoom on
h(5) = NewFig('FFSim'); plot(t,mdq2,  t,ddq2,  lw, 2 ); hold on, grid on, zoom on
h(6) = NewFig('FFSim'); plot(t,mdlan, t,ddlan, lw, 2 ); hold on, grid on, zoom on

% variable names and units
%-------------------------
names = {'Semi-major axis', 'Argument of latitude', 'Inclination', '\deltaq_1', '\deltaq_2', 'Longitude of ascending node'};
vars  = {'a',               '\theta',               'i',           'q_1', 'q_2', '\Omega'};
units = {'[m]',             '[rad]',                '[rad]',       '',    '',    '[rad]'};
tag   = {'a',               'theta'                 'inc'          'q1'   'q2'   'lan'};

% Apply formatting and save as metafiles
%---------------------------------------
for i=1:6 
   figure(h(i));
   y = [' \delta', vars{i},  '\newline', units{i}];
   set(gca,'fontsize',12,'fontname','Arial');
   xlabel(c,'fontsize',12,'fontname','Arial');
   ylabel(y,'fontsize',12,'fontname','Arial','rotation',eps,'horizontalalignment','right');
   title(names{i},'fontsize',12,'fontname','Arial');
   if saveFlag, saveas(h(i),[name,'_',tag{i}],'emf'); end
end

% Plot error
%-----------
m(1) = NewFig('FFSim');
subplot(211), plot(t,eda,      'linewidth', 2 ), hold on, grid on, zoom on,            ylabel('\Delta a [m]','rotation',eps),        title('Error between Measured and Desired')
subplot(212), plot(t,edth,     'linewidth', 2 ), hold on, grid on, zoom on, xlabel(c), ylabel('\Delta \theta [rad]','rotation',eps)
m(2) = NewFig('FFSim');
subplot(211), plot(t,edq1,     'linewidth', 2 ), hold on, grid on, zoom on,            ylabel('\Delta q1','rotation',eps),           title('Error between Measured and Desired')
subplot(212), plot(t,edq2,     'linewidth', 2 ), hold on, grid on, zoom on, xlabel(c), ylabel('\Delta q2','rotation',eps)
m(3) = NewFig('FFSim');
subplot(211), plot(t,edi,      'linewidth', 2 ), hold on, grid on, zoom on,            ylabel('\Delta i [rad]','rotation',eps),      title('Error between Measured and Desired')
subplot(212), plot(t,edlan,    'linewidth', 2 ), hold on, grid on, zoom on, xlabel(c), ylabel('\Delta \Omega [rad]','rotation',eps)

% variable names and units
% -------------------------
vars  = {'\Delta a',  '\Delta \theta', '\Delta q_1', '\Delta q_2', '\Delta i', '\Delta \Omega'};
units = {'[m]',       '[rad]',         '',           '',           '[rad]',    '[rad]'};
tag   = {'error1',                     'error2'                    'error3'};

% Apply formatting and save as metafiles
%---------------------------------------
for i=1:3 
   figure(m(i));
   subplot(211);
   y = ['  ', vars{2*i-1},  '\newline', units{2*i-1}];
   set(gca,'fontsize',12,'fontname','Arial');
   ylabel(y,'fontsize',12,'fontname','Arial','rotation',eps,'horizontalalignment','right');
   title('Error between Measured and Desired','fontsize',12,'fontname','Arial');
   subplot(212);
   y = [' ', vars{2*i},  '\newline', units{2*i}];
   set(gca,'fontsize',12,'fontname','Arial');
   ylabel(y,'fontsize',12,'fontname','Arial','rotation',eps,'horizontalalignment','right');   
   xlabel(c,'fontsize',12,'fontname','Arial');   
   if saveFlag, saveas(m(i),[name,'_',tag{i}],'emf'); end
end

% Set up animation
%-----------------
sc.r    = d.rH;
sc.t    = t;
scDes.r = d.rH_des;
scDes.t = t;
AnimationGUI('initialize',sc,scDes);

cd(cd1);

%--------------------------------------
% $Date: 2019-09-06 11:24:45 -0400 (Fri, 06 Sep 2019) $
% $Revision: 49727 $
