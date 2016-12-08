% Start ERL and record Output
test_name = 'f1';
frame_info = importdata('Data/Sample/Input/f1/rgb.txt', ' ');
input_path = 'Data/Sample/Input/f1'; % the overall dir containing rgb.txt and rgb/ actual image folder
load('Data/Sample/Intrinsics/f1_intrinsic.mat');

Sample_TestDriver(test_name, input_path,frame_info, ...
    K, 1, 200, 2);


%% now load the result and output for visualiser in C++
load('Data/Sample/Output/f1/result.mat');
last_R = eye(3);
N = size(pos, 2);
Rt = zeros(N, 12); % row wise vectorised Rt
for i = 1: N
    this_abs_T = pos(:,i);
    this_R = reshape(guessedRs(:,i), 3, 3);
    this_abs_R = this_R * last_R;
    Rt(i,:) = [reshape(this_abs_R', 1, []), this_abs_T']; % row wise vectorise
    
    last_R = this_abs_R;
end

% write Rt to csv
data_to_write = [(0:N-1)', Rt];
csvwrite('Data/Sample/Output/f1/ERL_frames.csv',data_to_write);


%% Write to Video
result_save_path = createFolderIfNotExist(sprintf('Data/Sample/Output/%s', test_name));
flow_path = createFolderIfNotExist(sprintf('%s/%s_flow', result_save_path, test_name));
residual_path = createFolderIfNotExist(sprintf('%s/%s_residual', result_save_path, test_name));
trajectory_path = createFolderIfNotExist(sprintf('%s/%s_trajectory', result_save_path, test_name));

out_path = 'Data/Video/f1.mp4';
videoGen(flow_path, residual_path, trajectory_path, 1, 200, 2, out_path, 2);