% Example of how the classes typically work
v = VideoWriter('Data/Video/GOPR5738_Hopping.avi');
v.FrameRate = 2;
open(v);
standard_size = nan;
f = figure('units','pixels','position',[0 0 800 4000]);
for i = 41: 100
    fprintf('producing frame:%d\n', i);
    im1 = imread(sprintf('Data/Sample/Output/GOPR5738_rgb_flow/%04d.png', i));
    im2 = imread(sprintf('Data/Sample/Output/GOPR5738_rgb_residual/%04d.png', i));
    im3 = imread(sprintf('Data/Sample/Output/GOPR5738_rgb_trajectory/%04d.png', i));
    figure(f),
    subplot(2,2, [1 2]);
    image(im1);
    axis off
    subplot(2,2, 3);
    image(im2);
    axis off
    subplot(2,2, 4);
    image(im3);
    axis off
    
    img=getframe(f);
    %{
    im_combine = imfuse(im1, im2, 'montage');
    if (isnan(standard_size))
        standard_size = [size(im_combine,1), size(im_combine, 2)];
    else
        im_combine = imresize(im_combine, standard_size);
    end
%     imshow(im_combine);
    %}
    writeVideo(v,img);
    %waitforbuttonpress;
end
close(v);