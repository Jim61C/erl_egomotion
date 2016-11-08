function Sample_GOPR5738()
    close all;clc;clear
    % Example of how the classes typically work
    ld = load('Data/Sample/GOPR5738.mat');
    load('cameraParams.mat');
    createFolderIfNotExist('Data/Sample/GOPR5738_flow');
    createFolderIfNotExist('Data/Sample/GOPR5738_residual');
    createFolderIfNotExist('Data/Sample/GOPR5738_trajectory');
    f_flow = figure;
    f_residual = figure('units','pixels','position',[0 0 521 501]);
    f_trajectory = figure('units','pixels','position',[0 0 501 501]);

    start_frame_index = 2;
    final_frame_index = 520;
    guessedTs = zeros(3, final_frame_index - start_frame_index);
    guessedOmegas = zeros(3, final_frame_index - start_frame_index);
    pos = zeros(3, final_frame_index - start_frame_index);

    for i = start_frame_index+1: final_frame_index
        Im1 = imread(sprintf('Data/Sample/GOPR5738_rgb/%04d.png', i-1));
        Im2 = imread(sprintf('Data/Sample/GOPR5738_rgb/%04d.png', i));
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
        export_fig(f_flow, sprintf('Data/Sample/GOPR5738_flow/%04d.png', i), '-native');
        % pause(0.01);
        
        % Plot T estimation
        clo(f_residual);
        [~, c] =c.plotResidualsSurface(false,true,25, f_residual);   
        export_fig(f_residual, sprintf('Data/Sample/GOPR5738_residual/%04d.png', i), '-native');
        % pause(0.01);
        
        % Estimate current location
        Omega_final = c.guessedOmega;
        if isnan(Omega_final)
            Omega_final=[0;0;0];
        end
        R=estimateR(Omega_final);
        current_pos=R*pos(:,i - start_frame_index)+c.guessedTranslation;
        pos(:,i - start_frame_index+1)=current_pos;
        
        guessedTs(:,i- start_frame_index) = c.guessedTranslation;
        guessedOmegas(:,i - start_frame_index) = c.guessedOmega;
        
        % Plot trajectory
        figure(f_trajectory);
        plot3(pos(1,i - start_frame_index:i - start_frame_index+1),...
            pos(2,i - start_frame_index:i - start_frame_index+1),...
            pos(3,i - start_frame_index:i - start_frame_index+1),'-'),hold on,grid on,
        xlabel('x');
        ylabel('y');
        zlabel('z');
        view(80,-30);
        export_fig(f_trajectory, sprintf('Data/Sample/GOPR5738_trajectory/%04d.png', i), '-native');
        pause(0.01);
        
    %     waitforbuttonpress;
    end
    % pos';
    save trajectory.mat pos
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