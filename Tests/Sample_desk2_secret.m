% Example of how the classes typically work
ld = load('Data/Sample/TUM1.mat');
sequence_input = 'Data/Sample/rgbd_dataset_freiburg1_desk2_secret/';
sequence_name = 'rgbd_dataset_freiburg1_desk2_secret';
createFolderIfNotExist(strcat('Data/Sample/', sequence_name, '_flow'));
createFolderIfNotExist(strcat('Data/Sample/', sequence_name, '_residual'));

f_flow = figure;
f_residual = figure('units','pixels','position',[0 0 1001 1001]);
frame_info = importdata('rgbd_dataset_freiburg1_desk2_secret.txt', ' ');

start_frame_index = 4;
guessedTs = zeros(3, size(frame_info, 1) - start_frame_index);
guessedOmegas = zeros(3, size(frame_info, 1) - start_frame_index);

for i = start_frame_index + 1 : size(frame_info,1)
    im1_frame_name_cell_splitted = strsplit(frame_info{i - 1}, ' ');
    im2_frame_name_cell_splitted = strsplit(frame_info{i}, ' ');
    im1 = imread(strcat(sequence_input, im1_frame_name_cell_splitted{1}, '.png'));
    im2 = imread(strcat(sequence_input, im2_frame_name_cell_splitted{1}, '.png'));
    if (size(im1, 3) ~= 1)
        im1 = rgb2gray(im1);
    end
    if (size(im2,3) ~= 1)
        im2 = rgb2gray(im2);
    end
    
    % Create Flow Objects
    flow = ImageFlow(im1,im2,'K',ld.K);

    % Create Cost Function Object
    c = CostFunctionFactory('RobustERL',flow);
    % c = CostFunctionFactory('ZhangTomasi',flow);

    % Plot everything
    flow.plotFlow([], false, f_flow)
    export_fig(f_flow, sprintf('Data/Sample/%s/%s', ...
        strcat(sequence_name,'_flow'), ...
        strcat(im1_frame_name_cell_splitted{1}, '.png')), '-native');
    pause(0.05);
    clo(f_residual);
    [~, c] = c.plotResidualsSurface(false,false,25, f_residual);
    export_fig(f_residual, sprintf('Data/Sample/%s/%s', ...
        strcat(sequence_name,'_residual'), ...
        strcat(im1_frame_name_cell_splitted{1}, '.png')), '-native');
    pause(0.05);
%     waitforbuttonpress;
    % save the estimated R and T
    guessedTs(:,i- start_frame_index) = c.guessedTranslation;
    guessedOmegas(:,i - start_frame_index) = c.guessedOmega;
end

save(sprintf('Data/Sample/%s_guessedTs.mat', sequence_name), 'guessedTs');
save(sprintf('Data/Sample/%s_guessedOmegas.mat', sequence_name), 'guessedOmegas');


