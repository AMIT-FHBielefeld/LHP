%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%                   GENETIC ALGORITHM         %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [s, pop] = geneticAlgorithm(pdata, genparams)
    arguments
        pdata (1, 1) lhp.ProblemData
        genparams (1, 1) lhp.algo.stochastic.genetic.GeneticParameters
    end

    debug = false;

    % predefinitions
    useHeuristics = any(genparams.InitializationAlgorithms ~= 0);
    pop_size = genparams.Popsize;
    half_pop_size = floor(pop_size/2);

    mutationP = genparams.Mutation_Param;
    crossoverP = genparams.Crossover_Param;
    stagnationP = genparams.Stagnation_Param;
    reinitP = genparams.Reinit_Param;
    T_Max = genparams.T_Max;

    pop{pop_size} = [];
    tmp_pop{pop_size} = [];
    pop_K = zeros(1,pop_size);

    % create rating function handle
    if genparams.Strict
        rate = @calc_costs;
    else
        rate = @calc_costs_cheap;
    end

    % iteration variables
    t = 0;
    stagnation = 0;

    % Heuristics
    if useHeuristics
        verfahren = lhp.algo.DeterministicWrapper.gather("StoreResults", false, ...
            "Range", genparams.InitializationAlgorithms);
    else
        verfahren = [];
    end

    %1) Initializing the Chromosomes
    for i=1:pop_size
        if i>size(genparams.InitializationAlgorithms,2) || genparams.InitializationAlgorithms == 0
            useHeuristics = false;
            verfahren = [];
            hdata = lhp.algo.stochastic.HarkData.initialHarkData(verfahren, pdata, useHeuristics);
        else
            hdata = lhp.algo.stochastic.HarkData.initialHarkData(verfahren(i), pdata, useHeuristics);
        end
        % recompute costs with cheap algorithm for comparison
        if genparams.Strict
            pop{i} = hdata;
        else
            pop{i} = hdata.chop_costs();
        end
        pop_K(i) = hdata.costs(4);
    end

    % find first minimum
    [~, idx] = min(pop_K);
    best = pop{idx};

    if debug
        fprintf("%d.) Beste Lösung: HA = %d,  WA = %d, TA = %d, K = %d.\n", t, best.costs(1), best.costs(2), best.costs(3), best.costs(4));
    end

    % main routine
    while t < T_Max + 1
        t = t+1;

        % Selection
        probabilities = pop_K/sum(pop_K);
        p = rand(pop_size-1,1);
        indices = randsample(1:pop_size,pop_size-1,true,probabilities);
        tmp_pop{1} = best;
        for i=2:pop_size
            if p(i-1) < reinitP
                tmp_pop{i} = lhp.algo.stochastic.HarkData.initialHarkData(...
                    verfahren, pdata, useHeuristics);
            else
                tmp_pop{i} = pop{indices(i-1)};
            end
        end
        pop = tmp_pop;

        % Crossover
        p = rand(half_pop_size,1);
        for i=1:2:pop_size-1
            if p((i+1)/2) < crossoverP
                %disp("[c] t: " + t + " i: " + i);
                [pop{i}, pop{i+1}] = cross_hubs(pop{i}, pop{i+1}, pdata);
            end
        end
        % Bridge Mutation
        p = rand(pop_size,1);
        for i=1:pop_size
            if p(i) < mutationP
                %disp("[m] t: " + t + " i: " + i);
                pop{i} = pop{i}.neighbor_swap(pdata);
            end
        end

        % Rate Population
        for i=1:pop_size
            pop{i} = rate(pop{i}, pdata);
            pop_K(i) = pop{i}.costs(4);
        end

        % overwrite worst with best from previous
        [~, idx] = max(pop_K);
        pop{idx(1)} = best;
        pop_K(idx(1)) = best.costs(4);

        % find and save minimum
        [~, idx] = min(pop_K);
        old_Best = best.costs(4);
        best = pop{idx(1)};

        if debug && rem(t,1)==0
            fprintf("%d.) Beste Lösung: HA = %d,  WA = %d, TA = %d, K = %d.\n", t, best.costs(1), best.costs(2), best.costs(3), best.costs(4));
        end

        if best.costs(4) < old_Best
            stagnation = 0;
        else
            stagnation = stagnation + 1;
            if stagnation > stagnationP
                break;
            end
        end
    end
    
%     % center hubs and calculate costs
    for i=1:pop_size
        % normalize structure and recompute costs
        s = pop{i}.s;
        s1 = lhp.utils.hz(pdata,s,'Median');
        [~, ~, ~, K1] = lhp.rating.get_costs(s1, pdata);
        s2 = lhp.utils.hz(pdata,s,'MaxLaub');
        [~, ~, ~, K2] = lhp.rating.get_costs(s2, pdata);
        s3 = lhp.utils.hz(pdata,s,'MinKompost');
        [~, ~, ~, K3] = lhp.rating.get_costs(s3, pdata);
        if (K1<K2) && (K1<K3)
            pop{i}.s = s1;
            pop_K(i) = K1;
        elseif (K2<K1) && (K2<K3)
            pop{i}.s = s2;
            pop_K(i) = K2;
        else
            pop{i}.s = s3;
            pop_K(i) = K3;
        end
    end
    
%     % center hubs and calculate costs
%     for i=1:pop_size
%         % normalize structure and recompute costs
%         pop{i} = lhp.algo.stochastic.HarkData(pop{i}.s, pdata);
%         for indCluster = 1:length(pop{i}.Cluster)
%             pop{i} = pop{i}.find_best_hub_in_cluster(pop{i}.Cluster{indCluster}, indCluster, pdata);
%         end
%         pop{i} = rate(pop{i}, pdata);
%         pop_K(i) = pop{i}.costs(4);
%     end
    [~, idx] = min(pop_K);
    if pop_K(idx) < best.costs(4)
        best = pop{idx};
    end
    s = lhp.utils.skip_zero_hubs(pdata, best.s);
end
