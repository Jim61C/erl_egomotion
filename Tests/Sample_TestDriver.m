function Sample_TestDriver(test_name, input_path, frame_info, K, start_frame_index, final_frame_index, step, cameraParams)
 
    ld.K = K;
  
    % Header in frame_info
    header_lines = 3;
    
    % create the folder for saving results
    result_save_path = createFolderIfNotExist(sprintf('Data/Sample/Output/%s', test_name));
    flow_path = createFolderIfNotExist(sprintf('%s/%s_flow', result_save_path, test_name));
    residual_path = createFolderIfNotExist(sprintf('%s/%s_residual', result_save_path, test_name));
    trajectory_path = createFolderIfNotExist(sprintf('%s/%s_trajectory', result_save_path, test_name));
    
    f_flow = figure;
    f_residual = figure('units','pixels','position',[0 0 521 501]);
    f_trajectory = figure('units','pixels','position',[0 0 501 501]);
   
    % N is total number of frames to record
    N= int64((final_frame_index - start_frame_index)/step);
    % variable to hold R, T, position
    guessedTs = zeros(3, N);
    guessedOmegas = zeros(3, N);
    guessedRs = zeros(9, N);
    pos = zeros(3, N);
    
    for i = start_frame_index+step:step: final_frame_index
        
        Im1_frame_name_cell_splitted = strsplit(frame_info{header_lines + i - step}, ' ');
        Im2_frame_name_cell_splitted = strsplit(frame_info{header_lines + i}, ' ');
        Im1 = imread(sprintf('%s/%s.png', input_path, Im1_frame_name_cell_splitted{1}));
        Im2 = imread(sprintf('%s/%s.png', input_path, Im2_frame_name_cell_splitted{1}));
        
        fprintf(sprintf('cur:%d/%d, %s/%s.png', i, final_frame_index, ...
            input_path, Im2_frame_name_cell_splitted{1}));
        
        if (size(Im1, 3) ~= 1)
            Im1 = rgb2gray(Im1);
        end
        if (size(Im2,3) ~= 1)
            Im2 = rgb2gray(Im2);
        end

        % remove distortion
        if ~isnan(cameraParams)
            Im1 = undistortImage(Im1,cameraParams);
            Im2 = undistortImage(Im2,cameraParams);
        end
        
        % figure; imshowpair(Im1,Im1_corrected,'montage');
        % title('Original Image (left) vs. Corrected Image (right)');
        % Im2_corrected = undistortImage(Im1,cameraParams,'OutputView','full');
        % ld.K=[1,0,0; 0,1,0; 0,0,1];

        % Create Flow Objects
        flow = ImageFlow(Im1,Im2,'K',ld.K);

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
    save (sprintf('%s/result.mat', result_save_path), 'pos', 'guessedTs', 'guessedOmegas', 'guessedRs');
end