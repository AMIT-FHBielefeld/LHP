classdef GeneticPlotter
    %GENETICPLOTTER Class to plot different data structures from the
    % genetic algorithm.
    %       author: kabdelhak

    properties (Constant)
    %% Latex arrows for directional plot, the indices get computed as follows:

    %                  Y
    %          ---------------->
    %            1     2     3
    %          _____ _____ _____
    %    |    |     |     |     |
    %    | 1  |  NW |  N  | NE  |
    %    |    |_____|_____|_____|
    %    |    |     |     |     |
    %  X | 2  |  W  |  H  |  E  |
    %    |    |_____|_____|_____|
    %    |    |     |     |     |
    %    | 3  |  SW |  S  | SE  |
    %    V    |_____|_____|_____|

    % The vector of the node in the middle (2,2) to the node it is
    % supposed to point to gets computed. The X value gets added to three
    % times the Y value so that the sum has a range from -4 to 4.
    % e.g. NE-Position: vec = (-1, 1) -> sum = -1 + 3*1 = 2
    % This sum gets increased by 5 to map the range to [1:10] such that it
    % can be used as indices for the list with corresponding latex arrows.

        % Map values from [-4:5] to [1:10] for indices.
        SIGN_ARROW_N = '$\uparrow$';        % -1 -> 4
        SIGN_ARROW_E = '$\rightarrow$';     %  3 -> 8
        SIGN_ARROW_S = '$\downarrow$';      %  1 -> 6
        SIGN_ARROW_W = '$\leftarrow$';      % -3 -> 2
        SIGN_ARROW_NE = '$\nearrow$';       %  2 -> 7
        SIGN_ARROW_SE = '$\searrow$';       %  4 -> 9
        SIGN_ARROW_SW = '$\swarrow$';       % -2 -> 3
        SIGN_ARROW_NW = '$\nwarrow$';       % -4 -> 1
        SIGN_HUB = '$H$';                   %  0 -> 5
        SIGN_EMPTY = '$X$';                 %  5 -> 10

        SIGNS = {...
            lhp.algo.stochastic.genetic.GeneticPlotter.SIGN_ARROW_NW, ...
            lhp.algo.stochastic.genetic.GeneticPlotter.SIGN_ARROW_W, ...
            lhp.algo.stochastic.genetic.GeneticPlotter.SIGN_ARROW_SW, ...
            lhp.algo.stochastic.genetic.GeneticPlotter.SIGN_ARROW_N, ...
            lhp.algo.stochastic.genetic.GeneticPlotter.SIGN_HUB, ...
            lhp.algo.stochastic.genetic.GeneticPlotter.SIGN_ARROW_S, ...
            lhp.algo.stochastic.genetic.GeneticPlotter.SIGN_ARROW_NE, ...
            lhp.algo.stochastic.genetic.GeneticPlotter.SIGN_ARROW_E, ...
            lhp.algo.stochastic.genetic.GeneticPlotter.SIGN_ARROW_SE, ...
            lhp.algo.stochastic.genetic.GeneticPlotter.SIGN_EMPTY};

        % Define empty position value;
        EMPTY = 5;
    end


    methods (Static)
        %% Plot functions

        function initialPlotGUIDE(mat,start,target)
            axes(target);
            cla;
            mat(start) = -1;

            hold on;
            axis off;
            grid on;
            for i=1:size(mat,1)
            	for j=1:size(mat,2)
                    if mat(i,j) == -1
                        plot(i,j,'x','color','r','Linewidth',2);
                    elseif mat(i,j) == 0
                        plot(i,j,'o','color','r','Linewidth',2);
                    else
                        plot(i,j,'o','color','g','Linewidth',2);
                    end
            	end
            end
        end

        function plotGUIDE(pop,idx,target)
            ax = axes(target);
            % Rotate the plot by 90 degrees
            view(ax, 90, 90);
            cla(ax);
            lhp.algo.stochastic.genetic.GeneticPlotter.plotDirections(pop, idx, ax);
        end

        function plotBest(pop,fig)
            % Plots the original data, heat map of best chromosome and rake
            % directions of best chromosome in figure(fig).
            figure(fig);
            generator = rng;
            sgtitle("Best Value: " + num2str(1/pop.Fitness(pop.BestIdx)) + ", Seed: " + num2str(generator.Seed));
            subplot(221);
            lhp.algo.stochastic.genetic.GeneticPlotter.plotOriginalData(pop);
            subplot(222);
            lhp.algo.stochastic.genetic.GeneticPlotter.plotChromosome(pop,pop.BestIdx);
            subplot(223);
            lhp.algo.stochastic.genetic.GeneticPlotter.plotForest(pop.Forests(pop.BestIdx));
            subplot(224);
            lhp.algo.stochastic.genetic.GeneticPlotter.plotDirections(pop,pop.BestIdx);
        end

        function plotOverview(pop,fig,x,y)
            % Plots the first x*y chromosomes (if existing) into a x by y
            % grid in figure(fig).
            figure(fig);
            for i=1:min(x*y,pop.Data.Popsize)
                subplot(x,y,i);
                lhp.algo.stochastic.genetic.GeneticPlotter.plotChromosome(pop,i);
            end
        end

        function plotDirectionsOverview(pop,fig,x,y)
            % Plots the first x*y chromosomes (if existing) into a x by y
            % grid in figure(fig).
            figure(fig);
            for i=1:min(x*y,pop.Data.Popsize)
                subplot(x,y,i);
                lhp.algo.stochastic.genetic.GeneticPlotter.plotDirections(pop,i);
            end
        end

        function plotForestOverview(pop,fig,x,y)
            % Plots the first x*y forests (if existing) into a x by y grid
            % in figure(fig).
            figure(fig);
            for i=1:min(x*y,pop.Data.Popsize)
                subplot(x,y,i);
                lhp.algo.stochastic.genetic.GeneticPlotter.plotForest(pop.Forests(i));
            end
        end

        function plotOriginalData(pop)
            % Plots the original data.
            imagesc(pop.Data.Garden);
            colormap jet;
            colorbar;
            caxis([-1, pop.Data.Max_Val])
            title('Original Data');
        end

        function plotChromosome(pop,chr)
            % Plots chromosome chr of population pop.
            data = getMatrix(pop,chr);
            imagesc(data);
            colormap jet;
            colorbar;
            caxis([-1, pop.Data.Max_Val]);
            title(['[', num2str(1/pop.Fitness(chr)), '] ', 'Chromosome ', num2str(chr)]);
        end

        function plotForest(forest,rated)
            % Plots the digraph of a forest structure.
            if ~exist('rated','var')
                rated = false;
            end
            idxlst = 1:length(forest.Successors);
            G = digraph(idxlst,forest.Successors,forest.Acc_Values);
            if rated
                plot(G,'Layout','force','EdgeLabel',G.Edges.Weight);
            else
            	plot(G,'Layout','force');
            end
            title(['Forest ', num2str(forest.Index)]);
        end

        function plotDirectionsLatex(pop,chr)
            % Plots the rake directions of chromosome chr from population
            % pop in latex code.
            chromosome = pop.Forests(chr).Successors;

            data = lhp.algo.stochastic.genetic.GeneticPlotter.EMPTY * ones(size(pop.Data.Garden));
            for i=1:length(chromosome)
                % Map to original positions
                [x_s,y_s] = mapIndex(pop,i);
                [x_n,y_n] = mapIndex(pop,chromosome(i));
                % Calculate rake vector
                vec = [x_n - x_s, y_n - y_s];
                % Map vector to correct arrow.
                % Computes to correct values for GeneticValues.SIGN_
                data(x_s,y_s) = vec(1) + vec(2)*3;
            end

            % Map values from [-4:5] to [1:10] for indices.
            data = data + 5;

            % Build latex table
            table = ['\begin{tabular}{', repmat('|c',1,size(pop.Data.Garden,2)), '|} \hline'];
            for i=1:size(data,1)
                for j=1:size(data,2)
                    table = [table,char(GeneticPlotter.SIGNS(data(i,j))),'&'];
                end
                table = table(1:end-1);
                table = [table,'\\ \hline'];
            end
            table = [table, '\end{tabular}'];

            h = get(gcf, 'Position');            hold on;

            camroll(-90);

            axis off;
            grid on;
            text(0, 0.5, {table}, 'Interpreter', 'Latex', 'FontSize', h(4)/25, 'Color', 'k');
            axis off;
        end

        function plotDirections(pop, chr, ax)
            % Plots the rake directions of chromosome chr from population
            % pop. Original algorithm author: pbrune
            if nargin == 2
                ax = gca();
            end

            hold(ax, "on");
            axis(ax, "off");
            grid(ax, "on");

            chromosome = pop.Forests(chr).Successors;

            for i=1:length(chromosome)
                % Map to original positions
                [x_s,y_s] = mapIndex(pop,i);
                if i~=chromosome(i)
                    [x_n,y_n] = mapIndex(pop,chromosome(i));
                    %d = [x_n,y_n]-[s_x,y_s];
                    %quiver(x_s,y_s,d(1),d(2),0);
                	plot(ax, [x_s,x_n],[y_s,y_n],'-','color','b','Linewidth',2);
                    if lhp.algo.stochastic.genetic.ForestUtils.isSource(pop.Forests(chr).Roles(i))
                        plot(ax, x_s,y_s,'*','color','m','Linewidth',2);
                    else
                        plot(ax, x_s,y_s,'o','color','b','Linewidth',2);
                    end
                else
                    if pop.Forests(chr).Acc_Values(i) == 0
                        plot(ax, x_s,y_s,'s','color','r','Linewidth',2);
                    else
                        plot(ax, x_s,y_s,'s','color','g','Linewidth',2);
                    end
                end
            end

            [~,s] = lhp.algo.stochastic.genetic.FitnessUtils.unproductiveWorkGreedyDebug(pop,chr);
            step = 1;

            for i=1:size(s,2)-1
                if s(1,i)~=s(2,i)
                    [x_s,y_s] = mapIndex(pop,s(1,i));
                    [x_n,y_n] = mapIndex(pop,s(2,i));
                    x = x_n/4 + x_s*3/4;
                    y = y_n/4 + y_s*3/4;
                    arrow_idx = (x_n - x_s) + (y_n - y_s) * 3 + 5;
                    halign = 'Center';
                    valign = 'Middle';
                    fsize = 20;
                    switch arrow_idx
                        case 4  %GeneticPlotter.SIGN_ARROW_N
                            valign = 'Bottom';
                        case 8  %GeneticPlotter.SIGN_ARROW_E
                            halign = 'Left';
                        case 6  %GeneticPlotter.SIGN_ARROW_S
                            valign = 'Top';
                        case 2  %GeneticPlotter.SIGN_ARROW_W
                            halign = 'Right';
                        case 7  %SIGN_ARROW_NE
                            valign = 'Bottom';
                            halign = 'Left';
                            fsize = 16;
                        case 9 %SIGN_ARROW_SE
                            valign = 'Top';
                            halign = 'Left';
                            fsize = 16;
                        case 3  %SIGN_ARROW_SW
                            valign = 'Top';
                            halign = 'Right';
                            fsize = 16;
                        case 1  %SIGN_ARROW_NW
                            valign = 'Bottom';
                            halign = 'Right';
                            fsize = 16;
                    end
                    text(ax, x_s,y_s,{char(lhp.algo.stochastic.genetic.GeneticPlotter.SIGNS(arrow_idx))},'Interpreter','Latex','Color','k','HorizontalAlignment',halign,'VerticalAlignment',valign,'FontSize',fsize,'FontWeight','Bold');
                    line(ax, 'XData',x_s,'YData',y_s,'Linestyle','none','Marker','o','Markersize',16,'Markerfacecolor','w');
                    text(ax, x_s,y_s,num2str(step),'HorizontalAlignment','Center','Color','k');
                    step = step + 1;
                end
            end

            x_fields = pop.Data.GMatrix(pop.Data.GMatrix(:,4) < 0,:);

            for i=1:size(x_fields,1)
            	plot(ax, x_fields(i,1),x_fields(i,2),'x','color','r','Linewidth',2);
            end

        end
    end
end

