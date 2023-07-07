function [s, pop] = genetic(data)
%GENETIC Main function for the Genetic Algorithm.
%       author: kabdelhak
% ToDo: Bridge_mutation
%       zeitoptimierung

% Debug params
plot = false;
plotInit = false;
prof = false;

if prof
  profile on;
end
% Initialize population

% Set random seed for repeatability.
% rng(100);

pop = lhp.algo.stochastic.genetic.GeneticUtils.initializePopulation(data,lhp.algo.stochastic.genetic.GeneticUtils.STANDARD_INIT_STRAT);

if plotInit
    GeneticPlotter.plotBest(pop,6);
    GeneticPlotter.plotOverview(pop,7,3,4);
    GeneticPlotter.plotForestOverview(pop,8,3,4);
    GeneticPlotter.plotDirectionsOverview(pop,9,3,4);
end

% Actual algorithm
stagnation_counter = 0;
for i=1:data.T_Max
    pop = lhp.algo.stochastic.genetic.GeneticUtils.mutatePopulation(pop,stagnation_counter);
    pop = lhp.algo.stochastic.genetic.GeneticUtils.crossPopulation(pop,stagnation_counter);
    [pop,improved] = lhp.algo.stochastic.genetic.GeneticUtils.selectPopulation(pop);
    if improved
        stagnation_counter = 0;
    else
        stagnation_counter = stagnation_counter +1;
        if stagnation_counter >= data.Stagnation_Param
%             disp("[genetic.m] The Genetic Algorithm stagnated after " + i + " steps.");
            break;
        end
    end
end
pop = ratePopulation(pop);
% Re-Inject best solution for better plotting.
pop.Forests(pop.BestIdx) = lhp.algo.stochastic.genetic.ForestUtils.deepCopy(pop.Best,pop.BestIdx);
pop.Fitness(pop.BestIdx) = pop.Best_Val;

% Plot results

if prof
    profile viewer
end
if plot
    GeneticPlotter.plotBest(pop,2);
    GeneticPlotter.plotOverview(pop,3,3,4);
    GeneticPlotter.plotForestOverview(pop,4,3,4);
    GeneticPlotter.plotDirectionsOverview(pop,5,3,4);
end

% Return best solution
s = fullMap(pop,pop.BestIdx);
end
