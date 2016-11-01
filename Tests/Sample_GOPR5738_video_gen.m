% Example of how the classes typically work
v = VideoWriter('Data/Video/GOPR5738.avi');
v.FrameRate = 2;
open(v);
standard_size = nan;
for i = 2: 520
    fprintf('producing frame:%d\n', i);
    im1 = imread(sprintf('Data/Sample/GOPR5738_flow/%04d.png', i));
    im2 = imread(sprintf('Data/Sample/GOPR5738_residual/%04d.png', i));
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