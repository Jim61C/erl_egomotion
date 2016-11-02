classdef CostFunction
%CostFunction - Superclass for the residual calculations
%   The basic functions for getting the residual from a given method. All a subclass really
%   need to implement is the getResidual function and the constructor. Takes in a flow
%   (from the FlowClassses folder) and uses the individual flow vectors to compute cost. The methods
%   in this superclass are to help find the minimum and help with visualization
    
    properties
        flow % Optical flow we are using the residual on
        trueT % Must know to do actual error analysis
        % For outlier rejection
        flow_outliers % Flow before outlier rejection (only used if outliers removed)
        inliers % Which flow vectors are inliers?
        verbose % Print out progress
        guessedOmega % the best estimated omega, rotational velocity
        guessedTranslation % the best estimated t, the translational velocity
    end
    
    methods
        % Constructor - all precomputation done here
        function c = CostFunction(flow)
            c.flow = flow;
            c.flow_outliers = flow;
            c.trueT = flow.trueT;
            c.verbose = true;
            c.guessedOmega = NaN;
            c.guessedTranslation = NaN;
        end
        
        % Total residual of a translation in given heading direction
        % Inputs:
        % T - size (3 x 1), norm(T)==1
        function [resid] = getResidual(c,T)
            resid = sum(c.getFlowResiduals(T));
        end
        % Residual for each flow vector for given heading direction T
        % Inputs:
        % T - size (3 x 1), norm(T)==1
        function [flowResids] = getFlowResiduals(c,T)
            flowResids = zeros(c.flow.nPoints,1);
        end
        % Get angular velocity from the flow in given heading direction 
        % Inputs:
        % T - size (3 x 1), norm(T)==1
        function [Omega] = getOmega(c,T)
            Omega = zeros(size(T));
        end
        % Inverse depth for each flow vector for given heading direction 
        % Inputs:
        % T - size (3 x 1), norm(T)==1
        function [rho] = getInverseDepths(c,T,Omega)
            rho = zeros(flow.nPoints,1);
        end
        % Get residuals for each translation on the sphere.
        % Inputs:
        % sphereDensity - positive integer, specifies density of grid on the sphere 
        %                 (optional, default 14)
        function [residuals, translations] = getSphereResiduals(c,sphereDensity)
            if nargin < 2
                sphereDensity = 14;
            end
            [x,y,z] = sphere(sphereDensity);
            xp = x(z>=0);
            yp = y(z>=0);
            zp = z(z>=0);
            translations = unique([xp(:) yp(:) zp(:)],'rows')';

            % Now for each translation compute the Cperp
            residuals = zeros(1,length(translations));
            t0 = CTimeleft(length(translations));
            for t = 1:length(translations)
                if c.verbose; t0.timeleft(); end;
                residuals(t) = c.getResidual(translations(:,t));
            end
        end

        % Get residuals in a polor coordinate grid and compute the associated surface.
        % Inputs:
        % nsamples - positive integer, specifies density of polar grid (optional, default 25)
        function [z,x,y] = getSurfaceResiduals(c,nsamples)
            if nargin < 2
                nsamples = 25;
            end
            theta = linspace(0,2*pi,nsamples);
            r = linspace(0,1,nsamples);
            [TH,R] = meshgrid(theta,r);
            Z = zeros(size(TH)); % z=(x^2)-(y^2)
            [x,y,z] = pol2cart(TH,R,Z);

            % Compute the residuals
            t0 = CTimeleft(length(x(:)));
            for i = 1:length(x(:))
                if c.verbose; t0.timeleft(); end;
                zval = sqrt(1 - (x(i)^2 + y(i)^2));
                if ~isreal(zval); zval = 0; end;
                T = [x(i); y(i); zval];
                z(i) = c.getResidual(T);
            end
        end
        
        % Go to local minima starting at initPos. This can be quite slow, since for now it just
        % uses fmincon.
        % Inputs:
        % initPos - size (3 x 1), norm(initPos)==1, used as starting place for gradient descent
        function [finalPos] = gradientDescent(c,initPos)
            cost = @(T) c.getResidual(T);
            options = optimset('Display','off');
            ceq = @(T) T'*T - 1;
            cineq = @(T) -1;
            finalPos = fmincon(cost, initPos, [],[],[],[],[],[], ...
                                @(T) deal(cineq(T),ceq(T)),options);
        end

        % Give score of flow vectors to remove as outliers - using avg. likelihood
        function [O] = outlierRejection(c)
            nsamples = 11; % Parameters to choose
            theta = linspace(0,2*pi,nsamples);
            r = linspace(0,1,nsamples);
            [TH,R] = meshgrid(theta,r);
            [x,y] = pol2cart(TH,R);
            translations = unique([x(:) y(:) sqrt(abs(1 - (x(:).^2 + y(:).^2)))],'rows')';
            % Build error matrix
            E = zeros(c.flow.nPoints,length(translations));
            for j = 1:length(translations)
                E(:,j) = c.getFlowResiduals(translations(:,j));
            end
            % Renormalize
            E = diag(sqrt(sum(c.flow.uv.^2)))\E;
            % Get mean vector
            M = mean(E)';
            O = sum(exp(-E/diag(M))/diag(M),2);
        end

        % DEPRECATED - Give score of flow vectors to remove as outliers using joint log likelihood
        function [O] = outlierRejectionJoint(c)
            nsamples = 11; % Parameters to choose
            theta = linspace(0,2*pi,nsamples);
            r = linspace(0,1,nsamples);
            [TH,R] = meshgrid(theta,r);
            [x,y] = pol2cart(TH,R);
            translations = unique([x(:) y(:) sqrt(abs(1 - (x(:).^2 + y(:).^2)))],'rows')';
            % Build error matrix
            E = zeros(c.flow.nPoints,length(translations));
            for j = 1:length(translations)
                E(:,j) = c.getFlowResiduals(translations(:,j));
            end
            % Renormalize
            E = spdiags(sqrt(sum(c.flow.uv.^2)),0,c.flow.nPoints,c.flow.nPoints)\E;
            % Get mean vector
            M = mean(E)';
            O = zeros(c.flow.nPoints,1);
            for j = 1:length(translations)
                O = O - E(:,j)/M(j) + log(M(j));
            end
        end
        
        % Get the main pieces of information from the flow - used in batch computations. It returns
        % the true heading direction T, the minimum cost heading direction computed by this class,
        % the associated angular error, as well as the angular velocity (omega) associated with the
        % minimum cost heading and its residual.
        % Inputs:
        % nsamples - positive integer specifying density of polar grid (optional, default 25)
        function [result] = getResults(c,nsamples)
            if nargin < 2; nsamples = 25; end;
            [z, x, y] = c.getSurfaceResiduals(nsamples); 
            [~, mi] = min(z(:));
            initT = [x(mi); y(mi); sqrt(max(0,1 - (x(mi)^2 + y(mi)^2)))];
            finalT = c.gradientDescent(initT);
            angError = acosd(sign(finalT'*c.trueT)*min(abs(finalT'*c.trueT),1));
            
            result.trueT = c.trueT;
            result.angularError = angError;
            result.minimumT = finalT;
            result.minimumOmega = c.getOmega(finalT);
            result.minimumResidual = c.getResidual(finalT);
            result.extraData = {};
        end
        
        % Different plotting functions
        % Plot the residuals on the unit hemisphere as dots, with color specifying cost. True and
        % computed heading direction are highlighted (as well as closest true point on the grid).
        % Inputs:
        % useGradientDescent - boolean, in case you want a more precise plot of the computed heading
        %                      direction (optional, default false)
        % sphereDensity - positive integer specifies how dense the points on the sphere will be 
        %                 plotted (optional, default 14)
        function plotResiduals(c,useGradientDescent,sphereDensity)
            if nargin < 2; useGradientDescent = false; end
            if nargin < 3; sphereDensity = 14; end
            
            % Get our estimate
            [sphereResiduals, translations] = c.getSphereResiduals(sphereDensity);
            [~,t_min_orig] = min(sphereResiduals);
            gridResidualsMinT = translations(:,t_min_orig);

            % Create the plot
            figure;
            hold on;
            scatter3( ...
                translations(1,:),...
                translations(2,:),...
                translations(3,:),...
                500,sphereResiduals,'.');

            colormap('parula')
            axis equal;

            % Plot the true translation
            scatter3(c.trueT(1),c.trueT(2),c.trueT(3),500,...
                c.getResidual(c.trueT),'.');
            scatter3(c.trueT(1),c.trueT(2),c.trueT(3),400,'go')

            % Plot minimum value for computed residuals
            scatter3(gridResidualsMinT(1),gridResidualsMinT(2),gridResidualsMinT(3),500,'ro')
            % Use gradient descent
            if useGradientDescent
                finalT = c.gradientDescent(gridResidualsMinT);
                scatter3(finalT(1),finalT(2),finalT(3), 500, ...
                            c.getResidual(finalT), '.');
                scatter3(finalT(1),finalT(2),finalT(3),500,'co');
            end
            
            colorbar
            xlabel('X')
            ylabel('Y')
            zlabel('Z')
            view(2)
        end

        % Main plotting function used. Uses a polor coordinate grid and computes the residual for
        % each point on the grid, and plots the surface of the resulting values. The true and
        % computed heading directions are plotted as points on the surface
        % Inputs:
        % newFigure - boolean, specifies creating a new matlab figure (optional, default true)
        % useGradientDescent - boolean, specifies whether to plot heading direction using estimate
        %                      gotten from gradient descent (slower, optional, default false)
        % nsamples - positive integer, specifies the courseness of the grid (optional, default 25)
        % givenFigure - figure handler, if provided, draw on the
        % givenFigure rather than create a new one
        function [min_value, modified] = plotResidualsSurface(c,newFigure,useGradientDescent,nsamples, givenFigure)
            if nargin < 2; newFigure = true; end
            if newFigure; figure('units','pixels','position',[0 0 1001 1001]); end;
            if nargin < 3; useGradientDescent = false; end
            if nargin < 4; nsamples = 25; end
            if nargin < 5; givenFigure = gcf; end
            
            [z,x,y] = c.getSurfaceResiduals(nsamples);
            % Plot the residuals
            figure(givenFigure);
            hold on;
            surf(x,y,z)
            colormap('jet')

            alpha(0.4)
            % Get our estimate
            [~,t_min_guess] = min(z(:));

            scatter3(c.trueT(1),c.trueT(2),...
                c.getResidual(c.trueT),600,'g.');
            guessedT = [ x(t_min_guess);
                         y(t_min_guess);
                         sqrt(1 - (x(t_min_guess)^2 + y(t_min_guess)^2))];
            scatter3(x(t_min_guess),y(t_min_guess),...
                c.getResidual(guessedT),600,'k.');
            c.guessedTranslation = guessedT;
            % Use gradient descent
            if useGradientDescent
                finalT = c.gradientDescent(guessedT);
                scatter3(finalT(1),finalT(2),...
                    c.getResidual(finalT),500,'c.');
            end
            
            % get the omega corresponding to the t with minimum sum residual
            c.guessedOmega = c.getOmega(guessedT);
            xlabel('X')
            ylabel('Y')
            zlabel('Residual')
            hold off
            if nargout > 0
                min_value = guessedT;
            end
            
            modified = c;
        end

        % Similar to plotResidualsSurface, except plots the resulting surface as a heatmap
        % Inputs:
        % newFigure - boolean, specifies creating a new matlab figure (optional, default true)
        % useGradientDescent - boolean, specifies whether to plot heading direction using estimate
        %                      gotten from gradient descent (slower, optional, default false)
        % nsamples - positive integer, specifies the courseness of the grid (optional, default 25)
        % nlevels - positive integer, specifies number of levels the heatmap should plot out
        %           (optional, default 30)
        function plotResidualsHeatmap(c,newFigure,useGradientDescent,nsamples,nlevels)
            if nargin < 2
                newFigure = true;
            end
            if nargin < 3
                useGradientDescent = false;
            end
            if nargin < 4
                nsamples = 25;
            end
            if nargin < 5
                nlevels = 30;
            end
            
            [z,x,y] = c.getSurfaceResiduals(nsamples);
            % Plot the residuals
            if newFigure; figure; end;
            hold on;
            contourf(x,y,z,nlevels)
            colormap('jet')

            alpha(0.4)
            % Get our estimate
            [~,t_min_guess] = min(z(:));

            scatter(c.trueT(1),c.trueT(2),600,'g.');
            guessedT = [x(t_min_guess);
                             y(t_min_guess);
                             sqrt(1 - (x(t_min_guess)^2 + y(t_min_guess)^2))];
            scatter(x(t_min_guess),y(t_min_guess),600,'k.');
            % Use gradient descent
            if useGradientDescent
                finalT = c.gradientDescent(guessedT);
                scatter3(finalT(1),finalT(2),500,'c.');
            end
            xlabel('X')
            ylabel('Y')
            zlabel('Residual')
            axis equal
            hold off
        end
    end
end

