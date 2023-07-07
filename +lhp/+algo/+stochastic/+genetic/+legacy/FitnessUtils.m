classdef FitnessUtils
    %FITNESSUTILS Class for rating functions.

    properties (Constant)
        STANDARD_MAX_VAL = 25;
        STANDARD_MAX_TRANS = 25;
        STANDARD_RAKE_PARAM = 1;
        STANDARD_UNPROD_PARAM = 1;
        STANDARD_TRANS_PARAM = 1;
    end

    methods (Static)
        %RAKINGWORK Calculate raking work
        %
        % from a given population.
        %
        % Parameters
        % ----------
        % pop: (?)
        %     The population to rate
        % chr: (?)
        %     The set of chromosomes for this population
        %
        % Returns
        % -------
        % RW: (?)
        %     A numeric, scalar value that represents the raking
        %     work.
        function RW = rakingWork(pop,chr)
            Not_Hubs = ~lhp.algo.stochastic.genetic.ForestUtils.isHub(pop.Forests(chr).Roles);
            RW = sum(Not_Hubs.*pop.Forests(chr).Acc_Values);
        end

        function TW = transportWork(pop,chr)
            %TRANSPORTWORK Calculate transportation work
            %
            % from a given population.
            %
            % Parameters
            % ----------
            % pop: (?)
            %     The population to rate
            % chr: (?)
            %     The set of chromosomes for this population
            %
            % Returns
            % -------
            % TW: (?)
            %     A numeric, scalar value that represents the transport
            %     work.
            Hubs = lhp.algo.stochastic.genetic.ForestUtils.getHubs(pop.Forests(chr).Roles,pop.IdxLst);
            TW_lst = ceil(pop.Forests(chr).Acc_Values(Hubs)/pop.Data.Max_Trans) ...
                .* pop.Data.DMatrix(pop.Data.Target,pop.Mapping(Hubs)) * 2;
            TW = sum(TW_lst);
        end

        function UW = unproductiveWorkGreedy(pop,chr)
            %% Simplified calculation of unproductive work
            %
            % Greedy heuristic to compute unproductive work.
            % This is a simplified calculation method to ease the
            % simulation.
            %
            % Parameters
            % ----------
            % pop: (?)
            %     The population to rate
            % chr: (?)
            %     The set of chromosomes for this population
            %
            % Returns
            % -------
            % UW: (?)
            %     A numeric, scalar value that represents the unproductive
            %     work.
            %
            % See Also
            % --------
            % FitnessUtils.unproductiveWorkGreedyDebug();
            chrom = pop.Forests(chr).Successors;
            distances = pop.Data.DMatrix_red;
            delta = lhp.algo.stochastic.genetic.ForestUtils.getInDegree(pop.Forests(chr));
            sources_bin = pop.Forests(chr).Roles == lhp.algo.stochastic.genetic.ForestUtils.ROLE_SOURCE;
            sources = find(sources_bin);
            UW = 0;
            i = 1;
            while ~isempty(sources)
                if i == 1
                    [UWpartial, index] = min(pop.Data.DMatrix(pop.Data.Start,pop.Mapping(sources)));
                else
                    [UWpartial, index] = min(distances(chrom(iterator),sources));
                end
                iterator = sources(index);
                UW = UW + UWpartial;
                sources_bin(iterator) = 0;
                delta(chrom(iterator)) = delta(chrom(iterator)) - 1;
                if delta(chrom(iterator)) == 0
                    sources_bin(chrom(iterator)) = 1;
                end
                i = i + 1;
                sources = find(sources_bin);
            end
            if i~=1
                % Go from last node to the start.
                UW = UW + pop.Data.DMatrix(pop.Mapping(iterator),pop.Data.Start);
            end
            % Go from the start node to the compost and back again.
            UW = UW + 2 * pop.Data.DMatrix(pop.Data.Start, pop.Data.Target);
        end

        function [UW, s] = unproductiveWorkGreedyDebug(pop,chr)
            %% Simplified calculation of unproductive work
            %
            % Greedy heuristic to compute unproductive work.
            % This is a simplified calculation method to ease the
            % simulation.
            %
            % Parameters
            % ----------
            % pop: (?)
            %     The population to rate
            % chr: (?)
            %     The set of chromosomes for this population
            %
            % Returns
            % -------
            % UW: (?)
            %     A numeric, scalar value that represents the unproductive
            %     work.
            % s: (?)
            %     I really do not know what this is...
            %
            % See Also
            % --------
            % FitnessUtils.unproductiveWorkGreedy();
            %
            % Notes
            % -----
            % This function is only for debug purposes and not efficient!
            chrom = pop.Forests(chr).Successors;
            distances = pop.Data.DMatrix_red;
            delta = lhp.algo.stochastic.genetic.ForestUtils.getInDegree(pop.Forests(chr));
            sources_bin = pop.Forests(chr).Roles == lhp.algo.stochastic.genetic.ForestUtils.ROLE_SOURCE;
            sources = find(sources_bin);
            UW = 0;
            s = zeros(floor(numel(sources)/2), 1);
            i = 1;
            while ~isempty(sources)
                if i == 1
                    [UWpartial, index] = min(pop.Data.DMatrix(pop.Data.Start,pop.Mapping(sources)));
                else
                    [UWpartial, index] = min(distances(chrom(iterator),sources));
                end
                iterator = sources(index);
                UW = UW + UWpartial;
                s(i) = iterator;
                sources_bin(iterator) = 0;
                delta(chrom(iterator)) = delta(chrom(iterator)) - 1;
                if delta(chrom(iterator)) == 0
                    sources_bin(chrom(iterator)) = 1;
                end
                i = i + 1;
                sources = find(sources_bin);
            end
            s = [s';chrom(s)];
            if i~=1
                s(:,i) = [iterator,0];
                % Go from last node to the start.
                UW = UW + pop.Data.DMatrix(pop.Mapping(iterator),pop.Data.Start);
            end
            % Go from the start node to the compost and back again.
            UW = UW + 2 * pop.Data.DMatrix(pop.Data.Start, pop.Data.Target);
        end

        function UW = unproductiveWorkExternal(pop,chr)
            %% Calculate unproductive work using external tools
            %
            % Uses ethe xternal function "unproduktive_wege.m" to compute
            % unproductive work.
            %
            % Parameters
            % ----------
            % pop: (?)
            %     The population to rate
            % chr: (?)
            %     The set of chromosomes for this population
            %
            % Returns
            % -------
            % UW: (?)
            %     A numeric, scalar value that represents the unproductive
            %     work.
            idxlst = 1:size(pop.Data.GMatrix,1);

            s = fullMap(pop,chr);

            delta_raw = lhp.algo.stochastic.genetic.ForestUtils.getInDegree(pop.Forests(chr));
            delta_mapped = zeros(1,length(idxlst));
            delta_mapped(pop.Mapping) = delta_raw;
            delta = [idxlst',delta_mapped'];

            Q = pop.Mapping(pop.Forests(chr).Roles == lhp.algo.stochastic.genetic.ForestUtils.ROLE_SOURCE);
            if ~isempty(Q)
                [UW, ~] = unproduktive_wege(s, delta, Q);
            else
                UW = 0;
            end
        end
    end
end

