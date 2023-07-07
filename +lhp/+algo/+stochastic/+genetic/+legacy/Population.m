classdef Population
    %POPULATION Main class for Populations.
    %       author: kabdelhak

    properties
        Data;       % Problem data and parameters
        Forests;    % Actual chromosomes
        Fitness;    % Rating
        BestIdx;    % Idx of best chromosome
        Best_Val;   % Value of best chromosome
        Best;       % Best chromosome
        Adjacency;  % Neighbourhood in the undirected graph
        Mapping;    % Mapping to original index, skips empty nodes
        IdxLst;     % Gets used often, permanently created for performance
    end

    methods
        %% Constructor
        function pop = Population(data,forests,adjacency,mapping)
            % Constructor for a Population
            pop.Forests = forests;
            pop.Fitness = ones(1,length(forests)) * 1/length(forests);
            pop.Adjacency = adjacency;
            pop.Mapping = mapping;
            pop.Data = addReducedDMatrix(data,pop.Mapping);
            pop.IdxLst = 1:length(mapping);
            [pop,pop.Best_Val] = ratePopulation(pop);
            pop.Best = lhp.algo.stochastic.genetic.ForestUtils.deepCopy(pop.Forests(pop.BestIdx),0);
        end

        %% Mapping functions
        function [x,y] = mapIndex(pop,index)
            % Maps an index of a gene inside a chromosome to the original
            % location inside the grid.
            true_index = pop.Mapping(index);
            x = floor((true_index-1)/size(pop.Data.Garden,2))+1;
            y = mod(true_index-1,size(pop.Data.Garden,2))+1;
        end

        function s = fullMap(pop,chr)
            % Maps a chromosome to the full representation such that each
            % index is mapped to the original index. The fitness of all
            % other points in the grid is equal to -1. Additionally the new
            % index is written in an adjacent array, such that berechnung.m
            % can process it.
            idxlst = 1:size(pop.Data.GMatrix,1);
            chr_mapped = ones(1,length(idxlst)) * -1;
            chr_mapped(pop.Mapping) = pop.Mapping(pop.Forests(chr).Successors);
            s = [idxlst;chr_mapped]';
        end

        function chr = inverseMap(pop,s)
            % Maps a solution to the froest representation such that each
            % index is mapped to the reduced index.
            chr = s(:,2);
            chr = chr(chr~=-1)';
            inv_map = zeros(1,length(s(:,2)));
            inv_map(pop.Mapping) = 1:length(pop.Mapping);
            chr = inv_map(chr);
        end

        function data = getMatrix(pop,chr)
            % Maps a chromosome to the original matrix and adds successors.
            idxlst_hubs = lhp.algo.stochastic.genetic.ForestUtils.getHubs(pop.Forests(chr).Roles,pop.IdxLst);
            data = -1*ones(size(pop.Data.Garden));
            for i=1:length(idxlst_hubs)
                [x,y] = mapIndex(pop,idxlst_hubs(i));
                data(x,y) = pop.Forests(chr).Acc_Values(idxlst_hubs(i));
            end
        end

        %% Mutation functions
        function pop = mutateSources(pop,stag)
            % Mutates a number of random sources equal to a number between
            % one and pop.Data.Mutation_Param, depending on the stagnation
            % count.
            for i=1:pop.Data.Popsize
                sources = lhp.algo.stochastic.genetic.ForestUtils.getSources(pop.Forests(i).Roles,pop.IdxLst);
                num = round((pop.Data.Mutation_Param)^(stag/pop.Data.Stagnation_Param));
                for j=1:num
                    rnd_source = sources(randi(length(sources)));
                    pop = lhp.algo.stochastic.genetic.ForestUtils.mutateRandomNeighbour(pop,i,rnd_source);
                end
            end
        end

        function pop = mutateHubs(pop,stag)
            % Mutates a number of random hubs equal to a number between
            % one and pop.Data.Mutation_Param, depending on the stagnation
            % count.
            for i=1:pop.Data.Popsize
                hubs = lhp.algo.stochastic.genetic.ForestUtils.getHubs(pop.Forests(i).Roles,pop.IdxLst);
                num = round((pop.Data.Mutation_Param)^(stag/pop.Data.Stagnation_Param));
                for j=1:num
                    rnd_hub = sources(randi(length(hubs)));
                    pop = lhp.algo.stochastic.genetic.ForestUtils.mutateRandomNeighbour(pop,i,rnd_hub);
                end
            end
        end

        %% Crossover functions
        function pop = crossHubs(pop, stag)
            % Crosses adjacent cromosomes with a probability between
            % pop.Data.Crossover_Param and one, depending on the stagnation
            % count.
            % NOTE: No random chromosomes are chosen -random placement
            % after selection is mandatory.
            num = pop.Data.Crossover_Param + (1-pop.Data.Crossover_Param)^(1/(pop.Data.Stagnation_Param-stag));
            for i=2:2:pop.Data.Popsize
                if rand() < num
                    [pop.Forests(i-1),pop.Forests(i)] = lhp.algo.stochastic.genetic.ForestUtils.crossForestHubs(pop.Forests(i-1),pop.Forests(i),pop.IdxLst);
                end
            end
        end

        %% Selection functions
        function [pop, best_val] = ratePopulation(pop)
            if pop.Data.Strict
                [pop, best_val] = ratePopulationStrict(pop);
            else
                [pop, best_val] = ratePopulationFast(pop);
            end
        end

        function [pop, best_val] = ratePopulationStrict(pop)
            % Rates each chromosome
            for chr=1:pop.Data.Popsize
                %UW = FitnessUtils.unproductiveWorkExternal(pop,chr);
                UW = lhp.algo.stochastic.genetic.FitnessUtils.unproductiveWorkGreedy(pop,chr);
                RW = lhp.algo.stochastic.genetic.FitnessUtils.rakingWork(pop,chr);
                TW = lhp.algo.stochastic.genetic.FitnessUtils.transportWork(pop,chr);

                cost = pop.Data.Rake_Param * RW + pop.Data.Unprod_Param * UW + pop.Data.Trans_Param * TW;

                pop.Fitness(chr) = 1/cost;
            end
            [best_val, pop.BestIdx] = max(pop.Fitness);
        end

        function [pop, best_val] = ratePopulationFast(pop)
            % Rates each chromosome
            for chr=1:pop.Data.Popsize
                RW = lhp.algo.stochastic.genetic.FitnessUtils.rakingWork(pop,chr);
                TW = lhp.algo.stochastic.genetic.FitnessUtils.transportWork(pop,chr);

                cost = pop.Data.Rake_Param * RW + pop.Data.Trans_Param * TW;

                pop.Fitness(chr) = 1/cost;
            end
            [best_val, pop.BestIdx] = max(pop.Fitness);
        end

        function [pop, improved] = selectPopulationRoulette1(pop)
            % Creates a new random population based on the preceeding one
            % and the probabilities derived from the fitness. This
            % selection method is based on roulette selection with one
            % pointer.
            prob = getAccProbabilities(pop);
            rnd = rand(1,pop.Data.Popsize);
            hits = rnd < prob';

            indices = zeros(1,pop.Data.Popsize);
            for i=1:pop.Data.Popsize
                indices(i) = find(hits(:,i),1,'first');
            end

            new_forests = pop.Forests(indices);
            [pop,new_forests,improved] = updateBestSolution(pop,new_forests);
            pop.Forests = updateIndices(new_forests);
        end

        function [pop, improved] = selectPopulationRouletteN(pop)
            % Creates a new random population based on the preceeding one
            % and the probabilities derived from the fitness. This
            % selection method is based on roulette selection with one
            % pointer.

            prob = getAccProbabilities(pop);
            rnd = rand()/pop.Data.Popsize;
            hits = rnd < prob';

            indices = zeros(1,pop.Data.Popsize);
            j = 1;
            for i=0:pop.Data.Popsize-1
                while rnd + i/pop.Data.Popsize > prob(j)
                    j = j + 1;
                end
                indices(i+1) = j;
            end

            % Randomized permutation for better crossover.
            new_forests = pop.Forests(indices(randperm(pop.Data.Popsize)));
            [pop,new_forests,improved] = updateBestSolution(pop,new_forests);
            pop.Forests = updateIndices(new_forests);
        end

        function prob = getAccProbabilities(pop)
            % Returns the accumulated probability distribution for
            % selection.
            acc = sum(pop.Fitness);
            prob = pop.Fitness(1)/acc.*ones(1,length(pop.Fitness));
            for i=2:pop.Data.Popsize
                prob(i) = pop.Fitness(i)/acc + prob(i-1);
            end
        end

        function [pop, new_forests, improved] = updateBestSolution(pop, new_forests)
            % If the best solution is better than the privious one, update
            % it. Injects it into random position either way.
            [best_val,best_index] = max(pop.Fitness);
            if best_val > pop.Best_Val
                pop.Best_Val = best_val;
                pop.Best = lhp.algo.stochastic.genetic.ForestUtils.deepCopy(pop.Forests(best_index),0);
                improved = true;
            else
                improved = false;
            end
            idx = randi(pop.Data.Popsize);
            new_forests(idx) = lhp.algo.stochastic.genetic.ForestUtils.deepCopy(pop.Best,idx);
        end

        function pop = updateOrder(pop)
            % Updates the order property of all forests.
            for i=1:length(pop.Forests)
                [~,s] = lhp.algo.stochastic.genetic.FitnessUtils.unproductiveWorkGreedyDebug(pop,i);
                pop.Forests(i).Ordering = s(:,1);
            end
        end

        function pop = updateOrderSingle(pop,chr)
            % Updates the order property of a single forest.
            [~,s] = lhp.algo.stochastic.genetic.FitnessUtils.unproductiveWorkGreedyDebug(pop,chr);
            pop.Forests(chr).Ordering = s(:,1);
        end
    end
end

