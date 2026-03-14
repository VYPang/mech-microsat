% "ideal_IMU_DCM_script.m"
% Pokwang Kwan
% 31may17
csv_file = 'output/IMU_from_curve.csv';
% This MATLAB script process the idealized Inertial Measurement Unit (IMU) data
% for dead reckoning.
% Inputs:
% 1,  timestamp [ms]
% 2,  Accelerometer x-axis [m/s^2] (measurement in body frame)
% 3,  Accelerometer y-axis [m/s^2] (measurement in body frame)
% 4,  Accelerometer z-axis [m/s^2] (measurement in body frame)
% 5,  Gyroscope x-axis [rad/s] (measurement in body frame)
% 6,  Gyroscope y-axis [rad/s] (measurement in body frame)
% 7,  Gyroscope z-axis [rad/s] (measurement in body frame)
% Outputs:
% 1,  timestamp [ms] (resampled)
% 2,  Acceleration x-axis in the navigation frame [m/s^2]
% 3,  Acceleration y-axis in the navigation frame [m/s^2]
% 4,  Acceleration z-axis in the navigation frame [m/s^2]
% 5,  Velocity x-axis in the navigation frame [rad/s]
% 6,  Velocity y-axis in the navigation frame [rad/s]
% 7,  Velocity z-axis in the navigation frame [rad/s]
% 9,  Position x-axis in the navigation frame [rad/s]
% 10, Position y-axis in the navigation frame [rad/s]
% 11, Position z-axis in the navigation frame [rad/s]

% This MATLAB script is written based on the following literature:
% Woodman, O. J. (2007) "An introduction to inertial navigation"
% University of Cambridge, Computer Laboratory, Technical Report 696.

% Notation:
% Reference frames:
% LVLH / body frame ("b-frame")
% Navigation frame vertical up +ve ("n-frame")

%------
% Physical constants

g_n = [0, 0, -9.81]';    % [m/s^2]; a column vector


%------
% Read data from tab delimited text file
% data format
% no file header, tab delimited
% Column 1: timestamp [ms]
% Column 2: accelerometer x [m/s^2]
% Column 3: accelerometer y [m/s^2]
% Column 4: accelerometer z [m/s^2]
% Column 5: gyroscope x [rad/s]
% Column 6: gyroscope y [rad/s]
% Column 7: gyroscope z [rad/s]

[time_ms_raw, ...
    accm_b_x_raw, accm_b_y_raw, accm_b_z_raw, ...
    gyro_b_x_raw, gyro_b_y_raw, gyro_b_z_raw] ...
    = textread(csv_file, '%f %f %f %f %f %f %f');
modified_index = 100:103;
modified_values = [1, 1, 1, 1];

accm_b_x_raw_mod = accm_b_x_raw;
accm_b_y_raw_mod = accm_b_y_raw;
accm_b_z_raw_mod = accm_b_z_raw;
gyro_b_x_raw_mod = gyro_b_x_raw;
gyro_b_y_raw_mod = gyro_b_y_raw;
gyro_b_z_raw_mod = gyro_b_z_raw;

accm_b_x_raw_mod(modified_index) = modified_values;
accm_b_y_raw_mod(modified_index) = modified_values;
accm_b_z_raw_mod(modified_index) = modified_values;
gyro_b_x_raw_mod(modified_index) = modified_values;
gyro_b_y_raw_mod(modified_index) = modified_values;
gyro_b_z_raw_mod(modified_index) = modified_values;

traj_original = run_dead_reckoning(...
    time_ms_raw, ...
    accm_b_x_raw, accm_b_y_raw, accm_b_z_raw, ...
    gyro_b_x_raw, gyro_b_y_raw, gyro_b_z_raw, ...
    g_n);

traj_mod_x = run_dead_reckoning(...
    time_ms_raw, ...
    accm_b_x_raw_mod, accm_b_y_raw, accm_b_z_raw, ...
    gyro_b_x_raw, gyro_b_y_raw, gyro_b_z_raw, ...
    g_n);

traj_mod_y = run_dead_reckoning(...
    time_ms_raw, ...
    accm_b_x_raw, accm_b_y_raw_mod, accm_b_z_raw, ...
    gyro_b_x_raw, gyro_b_y_raw, gyro_b_z_raw, ...
    g_n);

traj_mod_z = run_dead_reckoning(...
    time_ms_raw, ...
    accm_b_x_raw, accm_b_y_raw, accm_b_z_raw_mod, ...
    gyro_b_x_raw, gyro_b_y_raw, gyro_b_z_raw, ...
    g_n);

traj_mod_gyro_x = run_dead_reckoning(...
    time_ms_raw, ...
    accm_b_x_raw, accm_b_y_raw, accm_b_z_raw, ...
    gyro_b_x_raw_mod, gyro_b_y_raw, gyro_b_z_raw, ...
    g_n);

traj_mod_gyro_y = run_dead_reckoning(...
    time_ms_raw, ...
    accm_b_x_raw, accm_b_y_raw, accm_b_z_raw, ...
    gyro_b_x_raw, gyro_b_y_raw_mod, gyro_b_z_raw, ...
    g_n);

traj_mod_gyro_z = run_dead_reckoning(...
    time_ms_raw, ...
    accm_b_x_raw, accm_b_y_raw, accm_b_z_raw, ...
    gyro_b_x_raw, gyro_b_y_raw, gyro_b_z_raw_mod, ...
    g_n);

time_s_resmpl = traj_original.time_s_resmpl;
no_of_time_steps = traj_original.no_of_time_steps;

pos_tr_n_x = traj_original.pos_tr_n_x;
pos_tr_n_y = traj_original.pos_tr_n_y;
pos_tr_n_z = traj_original.pos_tr_n_z;

vel_tr_n_x = traj_original.vel_tr_n_x;
vel_tr_n_y = traj_original.vel_tr_n_y;
vel_tr_n_z = traj_original.vel_tr_n_z;

acc_tr_n_x = traj_original.acc_tr_n_x;
acc_tr_n_y = traj_original.acc_tr_n_y;
acc_tr_n_z = traj_original.acc_tr_n_z;


%------
% Plot

figure(1)
plot3(pos_tr_n_x, pos_tr_n_y, pos_tr_n_z, 'b')
grid on
title('navigation frame - position')
xlabel('x [m]'); ylabel('y [m]'); zlabel('z [m]');
axis equal
% Fix scale so trajectory is visible: use data range with cubic aspect
xr = [min(pos_tr_n_x), max(pos_tr_n_x)];
yr = [min(pos_tr_n_y), max(pos_tr_n_y)];
zr = [min(pos_tr_n_z), max(pos_tr_n_z)];
span = max([diff(xr), diff(yr), diff(zr), 0.2]);
mx = mean(xr); my = mean(yr); mz = mean(zr);
xlim([mx - span/2, mx + span/2])
ylim([my - span/2, my + span/2])
zlim([mz - span/2, mz + span/2])
FigPos3dAxisLimit = axis;

figure(10)
plot(time_s_resmpl, pos_tr_n_x, 'r')
hold on
plot(time_s_resmpl, pos_tr_n_y, 'g')
plot(time_s_resmpl, pos_tr_n_z, 'b')
xlabel('t [s]'); ylabel('distance from origin [m]');
title('navigation frame - coordinate')
legend('x','y','z')

figure(2)
plot(time_s_resmpl, vel_tr_n_x, 'r')
hold on
plot(time_s_resmpl, vel_tr_n_y, 'g')
plot(time_s_resmpl, vel_tr_n_z, 'b')
xlabel('t [s]'); ylabel('v [m/s]');
title('navigation frame - velocity')
legend('x','y','z')

figure(3)
plot(time_s_resmpl, acc_tr_n_x, 'r')
hold on
plot(time_s_resmpl, acc_tr_n_y, 'g')
plot(time_s_resmpl, acc_tr_n_z, 'b')
xlabel('t [s]'); ylabel('a [m/s^2]');
title('navigation frame - acceleration')
legend('x', 'y', 'z')

figure(4)
plot(time_ms_raw, accm_b_x_raw, 'r')
hold on
plot(time_ms_raw, accm_b_y_raw, 'g')
plot(time_ms_raw, accm_b_z_raw, 'b')
xlabel('t [s]'); ylabel('a [m/s^2]');
title('body frame - accelerometer, raw')
legend('x', 'y', 'z')

figure(5)
plot(time_ms_raw, gyro_b_x_raw, 'r')
hold on
plot(time_ms_raw, gyro_b_y_raw, 'g')
plot(time_ms_raw, gyro_b_z_raw, 'b')
xlabel('t [s]'); ylabel('gyro rate [rad/s]');
title('body frame - rate gyro, raw')
legend('x', 'y', 'z')

%{
figure(6)
plot(time_s_resmpl, accm_b_x_resmpl, 'r')
hold on
plot(time_s_resmpl, accm_b_y_resmpl, 'g')
plot(time_s_resmpl, accm_b_z_resmpl, 'b')
xlabel('t [s]'); ylabel('a [m/s^2]');
title('body frame - accelerometer, resampled')
legend('x','y','z')

figure(7)
plot(time_s_resmpl, gyro_b_x_resmpl, 'r')
hold on
plot(time_s_resmpl, gyro_b_y_resmpl, 'g')
plot(time_s_resmpl, gyro_b_z_resmpl, 'b')
xlabel('t [s]'); ylabel('gyro rate [rad/s]');
title('body frame - gyro rate, resampled')
legend('x','y','z')
%}


figure(20)
clf

[x_limits_xy, y_limits_xy] = get_axis_limits(...
    traj_original.pos_tr_n_x, traj_original.pos_tr_n_y, ...
    traj_mod_x.pos_tr_n_x, traj_mod_x.pos_tr_n_y);
[x_limits_yz, y_limits_yz] = get_axis_limits(...
    traj_original.pos_tr_n_y, traj_original.pos_tr_n_z, ...
    traj_mod_y.pos_tr_n_y, traj_mod_y.pos_tr_n_z);
[x_limits_xz, y_limits_xz] = get_axis_limits(...
    traj_original.pos_tr_n_x, traj_original.pos_tr_n_z, ...
    traj_mod_z.pos_tr_n_x, traj_mod_z.pos_tr_n_z);

plot_trajectory_subplot(...
    3, 2, 1, ...
    traj_original.pos_tr_n_x, traj_original.pos_tr_n_y, ...
    'x [m]', 'y [m]', 'Original XY trajectory', 'b', ...
    x_limits_xy, y_limits_xy);
plot_trajectory_subplot(...
    3, 2, 2, ...
    traj_mod_x.pos_tr_n_x, traj_mod_x.pos_tr_n_y, ...
    'x [m]', 'y [m]', 'Modified XY trajectory: accelerometer x', 'r', ...
    x_limits_xy, y_limits_xy);

plot_trajectory_subplot(...
    3, 2, 3, ...
    traj_original.pos_tr_n_y, traj_original.pos_tr_n_z, ...
    'y [m]', 'z [m]', 'Original YZ trajectory', 'b', ...
    x_limits_yz, y_limits_yz);
plot_trajectory_subplot(...
    3, 2, 4, ...
    traj_mod_y.pos_tr_n_y, traj_mod_y.pos_tr_n_z, ...
    'y [m]', 'z [m]', 'Modified YZ trajectory: accelerometer y', 'r', ...
    x_limits_yz, y_limits_yz);

plot_trajectory_subplot(...
    3, 2, 5, ...
    traj_original.pos_tr_n_x, traj_original.pos_tr_n_z, ...
    'x [m]', 'z [m]', 'Original XZ trajectory', 'b', ...
    x_limits_xz, y_limits_xz);
plot_trajectory_subplot(...
    3, 2, 6, ...
    traj_mod_z.pos_tr_n_x, traj_mod_z.pos_tr_n_z, ...
    'x [m]', 'z [m]', 'Modified XZ trajectory: accelerometer z', 'r', ...
    x_limits_xz, y_limits_xz);

sgtitle('Trajectory comparison for accelerometer changes at indices 100:103')

figure(21)
clf

[x_limits_xy_gyro, y_limits_xy_gyro] = get_axis_limits(...
    traj_original.pos_tr_n_x, traj_original.pos_tr_n_y, ...
    traj_mod_gyro_x.pos_tr_n_x, traj_mod_gyro_x.pos_tr_n_y);
[x_limits_yz_gyro, y_limits_yz_gyro] = get_axis_limits(...
    traj_original.pos_tr_n_y, traj_original.pos_tr_n_z, ...
    traj_mod_gyro_y.pos_tr_n_y, traj_mod_gyro_y.pos_tr_n_z);
[x_limits_xz_gyro, y_limits_xz_gyro] = get_axis_limits(...
    traj_original.pos_tr_n_x, traj_original.pos_tr_n_z, ...
    traj_mod_gyro_z.pos_tr_n_x, traj_mod_gyro_z.pos_tr_n_z);

plot_trajectory_subplot(...
    3, 2, 1, ...
    traj_original.pos_tr_n_x, traj_original.pos_tr_n_y, ...
    'x [m]', 'y [m]', 'Original XY trajectory', 'b', ...
    x_limits_xy_gyro, y_limits_xy_gyro);
plot_trajectory_subplot(...
    3, 2, 2, ...
    traj_mod_gyro_x.pos_tr_n_x, traj_mod_gyro_x.pos_tr_n_y, ...
    'x [m]', 'y [m]', 'Modified XY trajectory: gyroscope x', 'r', ...
    x_limits_xy_gyro, y_limits_xy_gyro);

plot_trajectory_subplot(...
    3, 2, 3, ...
    traj_original.pos_tr_n_y, traj_original.pos_tr_n_z, ...
    'y [m]', 'z [m]', 'Original YZ trajectory', 'b', ...
    x_limits_yz_gyro, y_limits_yz_gyro);
plot_trajectory_subplot(...
    3, 2, 4, ...
    traj_mod_gyro_y.pos_tr_n_y, traj_mod_gyro_y.pos_tr_n_z, ...
    'y [m]', 'z [m]', 'Modified YZ trajectory: gyroscope y', 'r', ...
    x_limits_yz_gyro, y_limits_yz_gyro);

plot_trajectory_subplot(...
    3, 2, 5, ...
    traj_original.pos_tr_n_x, traj_original.pos_tr_n_z, ...
    'x [m]', 'z [m]', 'Original XZ trajectory', 'b', ...
    x_limits_xz_gyro, y_limits_xz_gyro);
plot_trajectory_subplot(...
    3, 2, 6, ...
    traj_mod_gyro_z.pos_tr_n_x, traj_mod_gyro_z.pos_tr_n_z, ...
    'x [m]', 'z [m]', 'Modified XZ trajectory: gyroscope z', 'r', ...
    x_limits_xz_gyro, y_limits_xz_gyro);

sgtitle('Trajectory comparison for gyroscope changes at indices 100:103')


function traj = run_dead_reckoning(time_ms_raw, accm_b_x_raw, accm_b_y_raw, accm_b_z_raw, gyro_b_x_raw, gyro_b_y_raw, gyro_b_z_raw, g_n)
% No filtering is applied in this comparison so only the chosen samples differ.
accm_b_x_filt = accm_b_x_raw;
accm_b_y_filt = accm_b_y_raw;
accm_b_z_filt = accm_b_z_raw;
gyro_b_x_filt = gyro_b_x_raw;
gyro_b_y_filt = gyro_b_y_raw;
gyro_b_z_filt = gyro_b_z_raw;

data_pts_to_skip = 3;

time_ms_filt = time_ms_raw(data_pts_to_skip:end);

accm_b_x_filt = accm_b_x_filt(data_pts_to_skip:end);
accm_b_y_filt = accm_b_y_filt(data_pts_to_skip:end);
accm_b_z_filt = accm_b_z_filt(data_pts_to_skip:end);

gyro_b_x_filt = gyro_b_x_filt(data_pts_to_skip:end);
gyro_b_y_filt = gyro_b_y_filt(data_pts_to_skip:end);
gyro_b_z_filt = gyro_b_z_filt(data_pts_to_skip:end);

data_pts_for_zeroing = 20;

accm_b_x_offset = mean(accm_b_x_filt(1:data_pts_for_zeroing));
accm_b_y_offset = mean(accm_b_y_filt(1:data_pts_for_zeroing));
accm_b_z_offset = mean(accm_b_z_filt(1:data_pts_for_zeroing)) - g_n(3,1);
accm_b_x_filt = accm_b_x_filt - accm_b_x_offset;
accm_b_y_filt = accm_b_y_filt - accm_b_y_offset;
accm_b_z_filt = accm_b_z_filt - accm_b_z_offset;

gyro_b_x_offset = mean(gyro_b_x_filt(1:data_pts_for_zeroing));
gyro_b_y_offset = mean(gyro_b_y_filt(1:data_pts_for_zeroing));
gyro_b_z_offset = mean(gyro_b_z_filt(1:data_pts_for_zeroing));
gyro_b_x_filt = gyro_b_x_filt - gyro_b_x_offset;
gyro_b_y_filt = gyro_b_y_filt - gyro_b_y_offset;
gyro_b_z_filt = gyro_b_z_filt - gyro_b_z_offset;

time_ms_resmpl_intvl = 10;
time_ms_filt = time_ms_filt - time_ms_filt(1);
time_ms_elapsed = time_ms_filt(end) - time_ms_filt(1);
time_ms_resmpl = 0:time_ms_resmpl_intvl:time_ms_elapsed;

accm_b_x_resmpl = interp1(time_ms_filt, accm_b_x_filt, time_ms_resmpl, 'linear');
accm_b_y_resmpl = interp1(time_ms_filt, accm_b_y_filt, time_ms_resmpl, 'linear');
accm_b_z_resmpl = interp1(time_ms_filt, accm_b_z_filt, time_ms_resmpl, 'linear');

gyro_b_x_resmpl = interp1(time_ms_filt, gyro_b_x_filt, time_ms_resmpl, 'linear');
gyro_b_y_resmpl = interp1(time_ms_filt, gyro_b_y_filt, time_ms_resmpl, 'linear');
gyro_b_z_resmpl = interp1(time_ms_filt, gyro_b_z_filt, time_ms_resmpl, 'linear');

time_s_resmpl = time_ms_resmpl/1000;
time_s_intvl = time_ms_resmpl_intvl/1000;

no_of_time_steps = length(time_s_resmpl);

attitude_dcm = zeros(3,3,no_of_time_steps);
attitude_dcm(1,1,:) = 1;
attitude_dcm(2,2,:) = 1;
attitude_dcm(3,3,:) = 1;

turnrate_dcm = zeros(3,3,no_of_time_steps);
turnrate_dcm(1,2,:) = -gyro_b_z_resmpl;
turnrate_dcm(1,3,:) = gyro_b_y_resmpl;
turnrate_dcm(2,1,:) = gyro_b_z_resmpl;
turnrate_dcm(2,3,:) = -gyro_b_x_resmpl;
turnrate_dcm(3,1,:) = -gyro_b_y_resmpl;
turnrate_dcm(3,2,:) = gyro_b_x_resmpl;

delturn_dcm = turnrate_dcm*time_s_intvl;

accm_b = zeros(3,1,no_of_time_steps);
accm_b(1,1,:) = accm_b_x_resmpl;
accm_b(2,1,:) = accm_b_y_resmpl;
accm_b(3,1,:) = accm_b_z_resmpl;

gyro_b = zeros(3,1,no_of_time_steps);
gyro_b(1,1,:) = gyro_b_x_resmpl;
gyro_b(2,1,:) = gyro_b_y_resmpl;
gyro_b(3,1,:) = gyro_b_z_resmpl;

acc_tr_n = zeros(3,1,no_of_time_steps);
vel_tr_n = zeros(3,1,no_of_time_steps);
pos_tr_n = zeros(3,1,no_of_time_steps);

sigma = zeros(no_of_time_steps,1);
coeff_delturn_dcm = ones(no_of_time_steps,1);
coeff_delturn_dcm_sqrt = 0.5*ones(no_of_time_steps,1);
exp_delturn_dcm_dt = zeros(3,3,no_of_time_steps);

for t = 1:no_of_time_steps-1
    acc_tr_n(:,1,t) = attitude_dcm(:,:,t)*accm_b(:,1,t) - g_n;

    vel_tr_n(:,1,t+1) = vel_tr_n(:,1,t) + time_s_intvl*acc_tr_n(:,1,t);
    pos_tr_n(:,1,t+1) = pos_tr_n(:,1,t) + time_s_intvl*vel_tr_n(:,1,t);

    sigma(t) = norm(gyro_b(:,1,t))*time_s_intvl;

    small_angle_limit = 10^-6;
    if sigma(t) >= small_angle_limit
        coeff_delturn_dcm(t) = sin(sigma(t))/sigma(t);
        coeff_delturn_dcm_sqrt(t) = (1-cos(sigma(t)))/(sigma(t)^2);
    end

    exp_delturn_dcm_dt(:,:,t) = ...
        eye(3,3) ...
        + coeff_delturn_dcm(t)*delturn_dcm(:,:,t) ...
        + coeff_delturn_dcm_sqrt(t)*delturn_dcm(:,:,t)*delturn_dcm(:,:,t);
    attitude_dcm(:,:,t+1) = attitude_dcm(:,:,t)*exp_delturn_dcm_dt(:,:,t);
end

traj.time_s_resmpl = time_s_resmpl;
traj.no_of_time_steps = no_of_time_steps;
traj.pos_tr_n_x = reshape(pos_tr_n(1,1,:), [no_of_time_steps, 1]);
traj.pos_tr_n_y = reshape(pos_tr_n(2,1,:), [no_of_time_steps, 1]);
traj.pos_tr_n_z = reshape(pos_tr_n(3,1,:), [no_of_time_steps, 1]);
traj.vel_tr_n_x = reshape(vel_tr_n(1,1,:), [no_of_time_steps, 1]);
traj.vel_tr_n_y = reshape(vel_tr_n(2,1,:), [no_of_time_steps, 1]);
traj.vel_tr_n_z = reshape(vel_tr_n(3,1,:), [no_of_time_steps, 1]);
traj.acc_tr_n_x = reshape(acc_tr_n(1,1,:), [no_of_time_steps, 1]);
traj.acc_tr_n_y = reshape(acc_tr_n(2,1,:), [no_of_time_steps, 1]);
traj.acc_tr_n_z = reshape(acc_tr_n(3,1,:), [no_of_time_steps, 1]);
end


function [x_limits, y_limits] = get_axis_limits(original_axis_1, original_axis_2, modified_axis_1, modified_axis_2)
combined_axis_1 = [original_axis_1; modified_axis_1];
combined_axis_2 = [original_axis_2; modified_axis_2];

x_limits = [min(combined_axis_1), max(combined_axis_1)];
y_limits = [min(combined_axis_2), max(combined_axis_2)];
end


function plot_trajectory_subplot(n_rows, n_cols, plot_index, axis_1, axis_2, x_label_text, y_label_text, title_text, line_color, x_limits, y_limits)
subplot(n_rows, n_cols, plot_index)
plot(axis_1, axis_2, line_color, 'LineWidth', 1.5)
grid on
axis equal
xlim(x_limits)
ylim(y_limits)
xlabel(x_label_text)
ylabel(y_label_text)
title(title_text)
end