function Sample_iphone7()
    close all;clc;clear
    % Example of how the classes typically work
    test_name = 'iphone7';
    input_path = sprintf('Data/Sample/Input/%s_rgb', test_name);
    
    load('cameraParams_iphone7.mat');
    ld.K = cameraParams.IntrinsicMatrix';
    flow_path = createFolderIfNotExist(sprintf('Data/Sample/Output/%s_flow', test_name));
    residual_path = createFolderIfNotExist(sprintf('Data/Sample/Output/%s_residual', test_name));
    trajectory_path = createFolderIfNotExist(sprintf('Data/Sample/Output/%s_trajectory', test_name));
    f_flow = figure;
    f_residual = figure('units','pixels','position',[0 0 521 501]);
    f_trajectory = figure('units','pixels','position',[0 0 501 501]);
    
    
    start_frame_index = 40;
    final_frame_index = 419;
    step = 10;
    N= int64((final_frame_index - start_frame_index)/step);
    guessedTs = zeros(3, N);
    guessedOmegas = zeros(3, N);
    guessedRs = zeros(9, N);
    pos = zeros(3, N);
    for i = start_frame_index+step:step: final_frame_index
        Im1 = imread(sprintf('%s/%04d.png', input_path, i-step));
        Im2 = imread(sprintf('%s/%04d.png', input_path, i));
        fprintf(sprintf('cur: %s/%04d.png\n', input_path, i));
        
        if (size(Im1, 3) ~= 1)
            Im1 = rgb2gray(Im1);
        end
        if (size(Im2,3) ~= 1)
            Im2 = rgb2gray(Im2);
        end

        % remove distortion
        Im1_corrected = undistortImage(Im1,cameraParams);
        Im2_corrected = undistortImage(Im2,cameraParams);
        % figure; imshowpair(Im1,Im1_corrected,'montage');
        % title('Original Image (left) vs. Corrected Image (right)');
        % Im2_corrected = undistortImage(Im1,cameraParams,'OutputView','full');
        % ld.K=[1,0,0; 0,1,0; 0,0,1];

        % Create Flow Objects
        flow = ImageFlow(Im1_corrected,Im2_corrected,'K',ld.K);

        % Add some noise 

        % Create Cost Function Object
        c = CostFunctionFactory('RobustERL',flow);
        % c = CostFunctionFactory('ZhangTomasi',flow);

        % Plot optical flow
        flow.plotFlow([], false, f_flow)
        export_fig(f_flow, sprintf('%s/%04d.png', flow_path, i), '-native');
        % pause(0.01);
        
        % Plot T estimation
        clo(f_residual);
        [~, c] =c.plotResidualsSurface(false,true,25, f_residual);   
        export_fig(f_residual, sprintf('%s/%04d.png', residual_path, i), '-native');
        % pause(0.01);
        
        % Estimate current location
        Omega_final = c.guessedOmega;
        if isnan(Omega_final)
            Omega_final=[0;0;0];
        end
        R=estimateR(Omega_final);
        ind=(i - start_frame_index)/step;
        current_pos=pos(:,ind)+c.guessedTranslation;
        pos(:,ind+1)=current_pos;
        
        guessedTs(:,ind) = c.guessedTranslation;
        guessedRs(:, ind) = reshape(R, [1 9]);
        guessedOmegas(:,ind) = c.guessedOmega;
        
        % Plot trajectory
        figure(f_trajectory);
        plot3(pos(1,ind:ind+1),...
            pos(2,ind:ind+1),...
            pos(3,ind:ind+1),'-'),hold on,grid on,
        xlabel('x');
        ylabel('y');
        zlabel('z');
        view(80,-30);
        export_fig(f_trajectory, sprintf('%s/%04d.png', trajectory_path, i), '-native');
        pause(0.01);    
    %     waitforbuttonpress;
    end
    save trajectory_iphone7.mat pos
end


function R=estimateR(w)
    R=zeros(3,3);
    R(1,1)=cos(w(1))*cos(w(3));
    R(1,2)=cos(w(1))*sin(w(3));
    R(1,3)=-sin(w(1));
    
    R(2,1)=sin(w(2))*sin(w(1))*cos(w(3))-cos(w(2))*sin(w(3));
    R(2,2)=sin(w(2))*sin(w(1))*sin(w(3))+cos(w(2))*cos(w(3));
    R(2,3)=sin(w(2))*cos(w(1));
    
    R(3,1)=cos(w(2))*sin(w(1))*cos(w(3))+sin(w(2))*sin(w(3));
    R(3,2)=cos(w(2))*sin(w(1))*sin(w(3))-sin(w(2))*cos(w(3));
    R(3,3)=cos(w(2))*cos(w(1));
end