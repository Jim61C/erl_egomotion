% specify input folders
flow_input = 'Data/Sample/rgbd_dataset_freiburg1_desk2_secret_flow';
residual_input = 'Data/Sample/rgbd_dataset_freiburg1_desk2_secret_residual';
sequence_name = 'rgbd_dataset_freiburg1_desk2_secret';
frame_info = importdata(sprintf('%s.txt', sequence_name), ' ');
start_frame_index = 4;

v = VideoWriter(sprintf('Data/Video/%s.avi', sequence_name));
v.FrameRate = 2;
open(v);
standard_size = nan;
% for i = start_frame_index : size(frame_info,1)
for i = start_frame_index : 137
    fprintf('producing frame:%d\n', i);
    
    im_frame_name_cell_splitted = strsplit(frame_info{i}, ' ');
    im1 = imread(sprintf('%s/%s.png', flow_input, im_frame_name_cell_splitted{1}));
    im2 = imread(sprintf('%s/%s.png', residual_input, im_frame_name_cell_splitted{1}));
    im_combine = imfuse(im1, im2, 'montage');
    if (isnan(standard_size))
        standard_size = [size(im_combine,1), size(im_combine, 2)];
    else
        im_combine = imresize(im_combine, standard_size);
    end
%     imshow(im_combine);
    writeVideo(v,im_combine);
%     waitforbuttonpress;
end
close(v);