function [img_file_names] = Sample_TestDriver(test_name, input_path, frame_info, K, start_frame_index, final_frame_index, step, cameraParams)
    if(nargin < 8)
        need_distort = false;
    else
        need_distort = true;
    end
    
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
    % T, Omega, R are relative, thus N, pos is absolute, thus N + 1
    guessedTs = zeros(3, N);
    guessedOmegas = zeros(3, N);
    guessedRs = zeros(9, N);
    pos = zeros(3, N+1);
    pos(:,1) = zeros(3,1);
    img_file_names = cell(N,2);
    % record img name first frame
    first_frame_cell_splitted = strsplit(frame_info{header_lines +  start_frame_index}, ' ');
    idx = 1;
    img_file_names{idx, 2} = first_frame_cell_splitted{2};
    img_file_names{idx, 1} = idx-1;
    idx = idx + 1;
    
    for i = start_frame_index+step:step: final_frame_index
        
        Im1_frame_name_cell_splitted = strsplit(frame_info{header_lines + i - step}, ' ');
        Im2_frame_name_cell_splitted = strsplit(frame_info{header_lines + i}, ' ');
        Im1 = imread(sprintf('%s/%s', input_path, Im1_frame_name_cell_splitted{2}));
        Im2 = imread(sprintf('%s/%s', input_path, Im2_frame_name_cell_splitted{2}));
        
        % record name
        img_file_names{idx, 2} = Im2_frame_name_cell_splitted{2};
        img_file_names{idx, 1} = idx-1;
        idx = idx + 1;
        
        fprintf(sprintf('cur:%d/%d, %s/%s', i, final_frame_index, ...
            input_path, Im2_frame_name_cell_splitted{2}));
        
        if (size(Im1, 3) ~= 1)
            Im1 = rgb2gray(Im1);
        end
        if (size(Im2,3) ~= 1)
            Im2 = rgb2gray(Im2);
        end

        % remove distortion
        if need_distort
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
        current_pos= inv(R) * (pos(:,ind) - c.guessedTranslation);
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