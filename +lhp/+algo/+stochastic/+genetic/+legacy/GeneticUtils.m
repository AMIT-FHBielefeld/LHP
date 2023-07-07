classdef GeneticUtils
    %GENETICUTILS Main util class for the genetic algorithm.
    %       author: kabdelhak


    properties (Constant)
        %% Constant values to control algorithm behaviour
        var = import("lhp.algo.stochastic.genetic.*");

        a = import("lhp.algo.stochastic.genetic.GeneticUtils");
        b = import("lhp.algo.stochastic.genetic.FitnessUtils");
        c = import("lhp.algo.stochastic.genetic.Forest");
        d = import("lhp.algo.stochastic.genetic.ForestUtils");
        e = import("lhp.algo.stochastic.genetic.GeneticPlotter");
        f = import("lhp.algo.stochastic.genetic.Population");

        INIT_STRAT_MIXED = 0;
        INIT_STRAT_IDENTITY = 1;
        INIT_STRAT_PATHS = 2;
        INIT_STRAT_CLUSTER = 3;

        MUTATION_STRAT_SOURCES = 10;
        MUTATION_STRAT_HUBS = 11;

        CROSSOVER_STRAT_HUBS = 20;

        SELECTION_STRAT_ROULETTE_1 = 30;
        SELECTION_STRAT_ROULETTE_N = 31;

        MEAN_DEVIATION_WORST_CASE = 2*pi;

        %% Standard parameter and standard strategy constants
        STANDARD_INIT_STRAT = lhp.algo.stochastic.genetic.GeneticUtils.INIT_STRAT_MIXED;
        STANDARD_MUTATION_STRAT = lhp.algo.stochastic.genetic.GeneticUtils.MUTATION_STRAT_SOURCES;
        STANDARD_CROSSOVER_STRAT = lhp.algo.stochastic.genetic.GeneticUtils.CROSSOVER_STRAT_HUBS;
        STANDARD_SELECTION_STRAT = lhp.algo.stochastic.genetic.GeneticUtils.SELECTION_STRAT_ROULETTE_N;

        STANDARD_STRICT = true;
        STANDARD_STAGNATION_PARAM = 50;
        STANDARD_MUTATION_PARAM = 3;
        STANDARD_CROSSOVER_PARAM = 0.5;
    end

    methods (Static)
        %% Static functions with strategy switches for each genetic operation
        function pop = initializePopulation(data,init_strat)
            % Initializes a Population with given strategy.
            if ~exist('init_strat','var')
                init_strat = lhp.algo.stochastic.genetic.GeneticUtils.STANDARD_INIT_STRAT;
            end
            adjacency = data.Adjacency;
            adjacency(data.GMatrix(:,4)' < 0,:) = [];
            adjacency(:,data.GMatrix(:,4)' < 0) = [];
            adjacency = sparse(adjacency);

            mapping = 1:size(data.GMatrix,1);
            mapping(data.GMatrix(:,4)' < 0) = [];

            values = data.GMatrix(:,4)';
            values = values(values >= 0);

            forests = lhp.algo.stochastic.genetic.ForestUtils.emptyForestArray(values,data.Max_Val,data.Popsize);
            pop = lhp.algo.stochastic.genetic.Population(data,forests,adjacency,mapping);

            % Switch strategy
            switch init_strat
                case lhp.algo.stochastic.genetic.GeneticUtils.INIT_STRAT_MIXED
                    % Randomly select initialization methods from below for
                    % each chromosome/forest.
                    for i=1:pop.Data.Popsize
                        switch randi(3)
                            case lhp.algo.stochastic.genetic.GeneticUtils.INIT_STRAT_IDENTITY
                                % Do nothing with this forest/chromosome.
                            case lhp.algo.stochastic.genetic.GeneticUtils.INIT_STRAT_PATHS
                                pop = lhp.algo.stochastic.genetic.ForestUtils.pathOrClusterInitialization(pop,i,true);
                            case lhp.algo.stochastic.genetic.GeneticUtils.INIT_STRAT_CLUSTER
                                pop = lhp.algo.stochastic.genetic.ForestUtils.pathOrClusterInitialization(pop,i,false);
                        end
                    end
                case lhp.algo.stochastic.genetic.GeneticUtils.INIT_STRAT_IDENTITY
                    % Initialize every node as hub. Actually do nothing.
                case lhp.algo.stochastic.genetic.GeneticUtils.INIT_STRAT_PATHS
                    % Try to find random paths.
                    for i=1:pop.Data.Popsize
                        pop = lhp.algo.stochastic.genetic.ForestUtils.pathOrClusterInitialization(pop,i,true);
                    end
                case lhp.algo.stochastic.genetic.GeneticUtils.INIT_STRAT_CLUSTER
                    % Try to find random clusters.
                    for i=1:pop.Data.Popsize
                        pop = lhp.algo.stochastic.genetic.ForestUtils.pathOrClusterInitialization(pop,i,false);
                    end

                otherwise
                    warning(['[initializePopulation] Initialisation strategy with index ', init_strat, ' not known.']);
            end
        end

        function pop = mutatePopulation(pop, stag, mutate_strat)
            % Mutates a Population with given strategy.
            if ~exist('mutate_strat','var')
                mutate_strat = lhp.algo.stochastic.genetic.GeneticUtils.STANDARD_MUTATION_STRAT;
            end

            switch mutate_strat
                case lhp.algo.stochastic.genetic.GeneticUtils.MUTATION_STRAT_SOURCES
                    pop = mutateSources(pop, stag);
                case lhp.algo.stochastic.genetic.GeneticUtils.MUTATION_STRAT_HUBS
                    pop = mutateHubs(pop, stag);
                otherwise
                    error("[mutatePopulation] Mutation strategie with index " + num2str(mutate_strat) + " not known. Please use GeneticUtils.MUTATION_STRAT_ variables.");
            end
        end

        function pop = crossPopulation(pop, stag, crossover_strat)
            % Crosses a Population with given strategy.
          	if ~exist('crossover_strat','var')
                crossover_strat = lhp.algo.stochastic.genetic.GeneticUtils.STANDARD_CROSSOVER_STRAT;
            end
            switch crossover_strat
                case lhp.algo.stochastic.genetic.GeneticUtils.CROSSOVER_STRAT_HUBS
                    pop = crossHubs(pop, stag);
                otherwise
                    error("[crossPopulation] Crossover strategie with index " + num2str(crossover_strat) + " not known. Please use GeneticUtils.CROSSOVER_STRAT_ variables.");
            end
        end

        function [pop, improved] = selectPopulation(pop, selection_strat)
            % Generates a new Population with given strategy.
            if ~exist('selection_strat','var')
                selection_strat = lhp.algo.stochastic.genetic.GeneticUtils.STANDARD_SELECTION_STRAT;
            end

            pop = ratePopulation(pop);
            switch selection_strat
                case lhp.algo.stochastic.genetic.GeneticUtils.SELECTION_STRAT_ROULETTE_1
                    [pop, improved] = selectPopulationRoulette1(pop);
                case lhp.algo.stochastic.genetic.GeneticUtils.SELECTION_STRAT_ROULETTE_N
                    [pop, improved] = selectPopulationRouletteN(pop);
                otherwise
                    error("[selectPopulation] Selection strategie with index " + num2str(selection_strat) + " not known. Please use GeneticUtils.SELECTION_STRAT_ variables.");
            end
        end

        %% Additional constructors
        function pop = popFromSolution(data,s)
            % Constructor for a population with a single forest constructed
            % from a solution. Used for plotting solutions from other
            % heuristics.
            adjacency = data.Adjacency;
            adjacency(data.GMatrix(:,4)' < 0,:) = [];
            adjacency(:,data.GMatrix(:,4)' < 0) = [];
            adjacency = sparse(adjacency);

            mapping = 1:size(data.GMatrix,1);
            mapping(data.GMatrix(:,4)' < 0) = [];

            values = data.GMatrix(:,4)';
            values = values(values >= 0);

            forests = lhp.algo.stochastic.genetic.ForestUtils.emptyForest(-1,values,data.Max_Val);
            pop = lhp.algo.stochastic.genetic.Population(data,forests,adjacency,mapping);

            chr = inverseMap(pop,s);
            pop.Forests = lhp.algo.stochastic.genetic.ForestUtils.forestFromSolution(forests,chr);
        end

        function pop = popFromOrderedSolution(data,s)
            % Constructor for a population with a single forest constructed
            % from an ordered solution. Used for plotting solutions from
            % other heuristics.
            pop = lhp.algo.stochastic.genetic.GeneticUtils.popFromSolution(data,s);
            pop.Forests(1).Ordering = s(:,1);
        end

    end
end

