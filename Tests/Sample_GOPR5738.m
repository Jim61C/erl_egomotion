% Example of how the classes typically work
ld = load('Data/Sample/GOPR5738.mat');
createFolderIfNotExist('Data/Sample/GOPR5738_flow');
createFolderIfNotExist('Data/Sample/GOPR5738_residual');
f_flow = figure;
f_residual = figure('units','pixels','position',[0 0 1001 1001]);
for i = 2: 520
    Im1 = imread(sprintf('Data/Sample/GOPR5738_rgb/%04d.png', i-1));
    Im2 = imread(sprintf('Data/Sample/GOPR5738_rgb/%04d.png', i));
    
    if (size(Im1, 3) ~= 1)
        Im1 = rgb2gray(Im1);
    end
    if (size(Im2,3) ~= 1)
        Im2 = rgb2gray(Im2);
    end
    
    % Create Flow Objects
    flow = ImageFlow(Im1,Im2,'K',ld.K);

    % Add some noise 

    % Create Cost Function Object
    c = CostFunctionFactory('RobustERL',flow);
    % c = CostFunctionFactory('ZhangTomasi',flow);

    % Plot everything
    flow.plotFlow([], false, f_flow)
    export_fig(f_flow, sprintf('Data/Sample/GOPR5738_flow/%04d.png', i), '-native');
    pause(0.05);
    clo(f_residual);
    c.plotResidualsSurface(false,false,25, f_residual);
    export_fig(f_residual, sprintf('Data/Sample/GOPR5738_residual/%04d.png', i), '-native');
    pause(0.05);
%     waitforbuttonpress;

end
