function videoGen(flow_input, residual_input, traj_input, start_frame, end_frame, step, out_path, frame_rate)
    v = VideoWriter(out_path);
    v.FrameRate = frame_rate;
    open(v);
    f = figure('units','pixels','position',[0 0 800 4000]);
    for i = start_frame+step:step:end_frame
        fprintf('producing frame:%d\n', i);
        im1 = imread(sprintf('%s/%04d.png', flow_input, i));
        im2 = imread(sprintf('%s/%04d.png', residual_input, i));
        im3 = imread(sprintf('%s/%04d.png', traj_input, i));
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
    end
    close(v);
end