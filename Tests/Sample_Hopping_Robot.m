% Start ERL and record Output
test_name = 'MinitaurHoppingVideo';
frame_info = importdata('Data/Sample/Input/MinitaurHoppingVideo/rgb.txt', ' ');
input_path = 'Data/Sample/Input/MinitaurHoppingVideo';
load('Data/Sample/Intrinsics/cameraParams.mat');

header_len = 3;
frame_id_to_img_file = Sample_TestDriver(test_name, input_path,frame_info, ...
    cameraParams.IntrinsicMatrix', 1, length(frame_info) - header_len, 1, cameraParams);


%% now load the result and output for visualiser in C++
load(sprintf('Data/Sample/Output/%s/result.mat', test_name));
last_R = eye(3);
N = size(pos, 2);
Rt = zeros(N, 12); % row wise vectorised Rt
% first row is I|0
Rt(1,:) = [reshape(last_R', 1, []), zeros(1,3)]; 
for i = 1: N-1
    this_R = reshape(guessedRs(:,i), 3, 3);
    this_T = guessedTs(:,i);
%     this_abs_R = this_R * last_R;
%     Rt(i+1,:) = [reshape(this_abs_R', 1, []), guessedTs(:,i)']; % row wise vectorise
    last_Rt_3_4_vector = Rt(i, :);
    last_Rt_4_4 = vertcat([reshape(last_Rt_3_4_vector(1:9), 3, 3)',last_Rt_3_4_vector(10:12)'], [0,0,0,1]);
    rel_Rt_4_4 = vertcat([this_R,this_T], [0,0,0,1]);
    this_Rt_4_4 = last_Rt_4_4 * rel_Rt_4_4;
    Rt(i+1, :) = [reshape(this_Rt_4_4(1:3,1:3)', 1, []), this_Rt_4_4(1:3,4)'];
%     last_R = this_abs_R;
end

% write Rt to csv
data_to_write = [(0:N-1)', Rt];
csvwrite(sprintf('Data/Sample/Output/%s/ERL_frames.csv', test_name),data_to_write);
% write frame id to img file name
fileID = fopen(sprintf('Data/Sample/Output/%s/out_info.txt', test_name),'w');
formatSpec = '%d %s\n';
for row = 1:N
    fprintf(fileID,formatSpec,frame_id_to_img_file{row,:});
end
fclose(fileID);

%% Write to Video
result_save_path = createFolderIfNotExist(sprintf('Data/Sample/Output/%s', test_name));
flow_path = createFolderIfNotExist(sprintf('%s/%s_flow', result_save_path, test_name));
residual_path = createFolderIfNotExist(sprintf('%s/%s_residual', result_save_path, test_name));
trajectory_path = createFolderIfNotExist(sprintf('%s/%s_trajectory', result_save_path, test_name));

out_path = sprintf('Data/Video/%s.avi', test_name);
videoGen(flow_path, residual_path, trajectory_path, 1, 200, 2, out_path, 2);