classdef ForestUtils
    %FORESTUTILS Util class for forest handling.
    %       author: kabdelhak

    properties (Constant)
        INDEX_EXTERNAL = -1;

        ROLE_BRIDGE = 0;
        ROLE_SOURCE = 1;
        ROLE_HUB = 2;
        ROLE_SINGLE = 3;

        ORDER_UNORDERED = -1;
    end

    methods (Static)
        %% Additional constructors
        function forest = emptyForest(idx,values,max_value)
            % Creates an empty forest with all hubs.
            if exist('values','var')
                roles = ones(1,length(values)) * lhp.algo.stochastic.genetic.ForestUtils.ROLE_SINGLE;
                successors = 1:length(values);
                forest = lhp.algo.stochastic.genetic.Forest(idx,roles,successors,values,values,max_value);
            else
                forest = lhp.algo.stochastic.genetic.Forest;
            end
        end

        function forests = emptyForestArray(values,max_value,popsize)
            % Creates an array of empty forests with all hubs.
            forests(popsize) = lhp.algo.stochastic.genetic.ForestUtils.emptyForest(popsize,values,max_value);
            for i=1:popsize-1
                forests(i) = lhp.algo.stochastic.genetic.ForestUtils.emptyForest(i,values,max_value);
            end
        end

        function forest = forestFromSolution(forest,chr)
            % Constructor for a forest constructed from a solution. Used
            % for plotting solutions from other heuristics.
            for i=1:length(chr)
                forest = mutateForest(forest,i,chr(i));
            end
        end

        function pop = pathOrClusterInitialization(pop,i,path)
            % Initializes an emptyForest with path or cluster
            % initialization. Input path is boolean and states wether or
            % not path initialization is chosen.
            check_bin = zeros(1,length(pop.Forests(i).Successors));
            check_list = 1:length(pop.Forests(i).Successors);
            while ~isempty(check_list)
                node = check_list(randi(length(check_list)));
                closed_nodes = find(check_bin);
                [pop,closed_nodes] = lhp.algo.stochastic.genetic.ForestUtils.mutatePathOrCluster(pop,i,node,closed_nodes,path);
                check_bin(closed_nodes) = true;
                check_list = find(~check_bin);
            end
        end

        function forestOut = deepCopy(forest,idx)
            % Copys the primitive data instead of the struct.
            forestOut = lhp.algo.stochastic.genetic.ForestUtils.emptyForest(idx,forest.Values,forest.Max_Value);
            forestOut.Roles = forest.Roles;
            forestOut.Successors = forest.Successors;
            forestOut.Acc_Values = forest.Acc_Values;
        end

        %% Deep consistancy checks
        function [bool, hub] = checkLoopPrevention(forest,node,successor)
            % Checks if proposed mutation does not produce a loop.
            bool = true;
            if successor == forest.Successors(successor) || successor == node
                hub = successor;
            elseif node == forest.Successors(successor)
                bool = false;
                hub = -1;
            else
                if lhp.algo.stochastic.genetic.ForestUtils.has_loops(forest, node, successor)
                    bool = false;
                    hub = -1;
                else
                    % Get the hub then.
                    iterator = forest.Successors(successor);
                    while forest.Successors(iterator)~=iterator
                        iterator = forest.Successors(iterator);
                    end
                    hub = iterator;
                end
            end
        end

        function bool = checkMaximumCapacity(forest,node,successor,hub_successor)
            % Checks if proposed mutation does not exceed the maximum
            % capacity in all nodes.
            if node == forest.Successors(node)
                bool_same_cluster = false;
            else
                iterator = forest.Successors(node);
                while iterator~=successor && forest.Successors(iterator)~=iterator
                    iterator=forest.Successors(iterator);
                    if iterator == node
                        disp(['[ForestUtils][checkMaximumCapacity][Forest #', num2str(forest.Index), ']: There is a loop in the system. An error already occured somewhere else.']);
                        break;
                    end
                end
                bool_same_cluster = (iterator==successor) + (iterator==hub_successor);
            end
            if bool_same_cluster
                bool = true;
            else
                bool = (forest.Acc_Values(node) + forest.Acc_Values(hub_successor) <= forest.Max_Value);
            end
        end

        %% Genetic operations
        function [pop, neighbour] = mutateRandomNeighbour(pop,i,node)
            % Trys to mutate a node to any of its neigbours, randomly
            % chosen. Forward mutation.
            neighbour = 0;
            neighbours = find(pop.Adjacency(node,:));
            neighbours = neighbours(neighbours~=pop.Forests(i).Successors(node));
            neighbours = neighbours(randperm(length(neighbours)));
            for k=1:length(neighbours)
                if checkForestMutation(pop.Forests(i),node,neighbours(k))
                    pop.Forests(i) = mutateForest(pop.Forests(i),node,neighbours(k));
                    neighbour = neighbours(k);
                    break;
                end
            end
        end

        function [pop, neighbour] = mutateRandomNeighbourReverse(pop,i,node)
            % Trys to mutate a node to any of its neigbours, randomly
            % chosen. Backward mutation.
            neighbour = 0;
            neighbours = find(pop.Adjacency(node,:));
            neighbours = neighbours(neighbours~=pop.Forests(i).Successors(node));
            neighbours = neighbours(randperm(length(neighbours)));
            for k=1:length(neighbours)
                if checkForestMutation(pop.Forests(i),neighbours(k),node)
                    pop.Forests(i) = mutateForest(pop.Forests(i),neighbours(k),node);
                    neighbour = neighbours(k);
                    break;
                end
            end
        end

        function [pop, closed_nodes] = mutatePathOrCluster(pop,i,node,closed_nodes,path)
            % Creates one path or cluster from mutation strategies. Input
            % path is boolean and states whether or not path initialization
            % is chosen.
            closed_nodes = [closed_nodes, node];
            neighbours = find(pop.Adjacency(node,:));
            neighbours = setdiff(neighbours,closed_nodes);
            neighbours = neighbours(randperm(length(neighbours)));
            neighbour_lst = [];
            for k=1:length(neighbours)
                if checkForestMutation(pop.Forests(i),neighbours(k),node)
                    pop.Forests(i) = mutateForest(pop.Forests(i),neighbours(k),node);
                    neighbour_lst = [neighbour_lst, neighbours(k)];
                    if path
                        break;
                    end
                end
            end
            if ~isempty(neighbour_lst)
                closed_nodes = [closed_nodes, neighbour_lst];
                for k=1:length(neighbour_lst)
                	[pop, closed_nodes] = lhp.algo.stochastic.genetic.ForestUtils.mutatePathOrCluster(pop,i,neighbour_lst(k),closed_nodes,path);
                end
            end
        end

        function [forest1, forest2] = crossForestHubs(forest1, forest2, idxLst)
            % Crosses two forests by exchanging a random hub.
            hubs1 = lhp.algo.stochastic.genetic.ForestUtils.getHubs(forest1.Roles,idxLst);
            hubs2 = lhp.algo.stochastic.genetic.ForestUtils.getHubs(forest2.Roles,idxLst);
            xhubs1 = setdiff(hubs1,hubs2);
            xhubs2 = setdiff(hubs2,hubs1);

            if ~isempty(xhubs1)
                rnd_hub1 = xhubs1(randi(length(xhubs1)));
                forest2 = injectHub(forest2,rnd_hub1);
            end

            if ~isempty(xhubs2)
                rnd_hub2 = xhubs2(randi(length(xhubs2)));
                forest1 = injectHub(forest1,rnd_hub2);
            end
        end

        function [delta, delta_mat] = getInDegree(forest)
            delta_mat = forest.Successors' == [1:length(forest.Successors)];
            delta_mat = delta_mat - diag(lhp.algo.stochastic.genetic.ForestUtils.isHub(forest.Roles));
            delta = sum(delta_mat);
            delta_mat = sparse(delta_mat);
        end

        %% Role manipulation functions
        function bool_arr = isSource(roles)
            bool_arr = (roles == lhp.algo.stochastic.genetic.ForestUtils.ROLE_SOURCE);
            bool_arr = bool_arr + (roles == lhp.algo.stochastic.genetic.ForestUtils.ROLE_SINGLE);
        end

        function bool_arr = isHub(roles)
            bool_arr = (roles == lhp.algo.stochastic.genetic.ForestUtils.ROLE_HUB);
            bool_arr = bool_arr + (roles == lhp.algo.stochastic.genetic.ForestUtils.ROLE_SINGLE);
        end

        function idx = getSources(roles, idxlst)
            idx_1 = idxlst(roles==lhp.algo.stochastic.genetic.ForestUtils.ROLE_SOURCE);
            idx_2 = idxlst(roles==lhp.algo.stochastic.genetic.ForestUtils.ROLE_SINGLE);
            idx = [idx_1,idx_2];
        end

        function idx = getHubs(roles, idxlst)
            idx_1 = idxlst(roles==lhp.algo.stochastic.genetic.ForestUtils.ROLE_HUB);
            idx_2 = idxlst(roles==lhp.algo.stochastic.genetic.ForestUtils.ROLE_SINGLE);
            idx = [idx_1,idx_2];
        end

        function idx = getSingles(roles, idxlst)
            idx = idxlst(roles==lhp.algo.stochastic.genetic.ForestUtils.ROLE_SINGLE);
        end

        function idx = getBridges(roles, idxlst)
            idx = idxlst(roles==lhp.algo.stochastic.genetic.ForestUtils.ROLE_BRIDGE);
        end

        function role = makeHub(role)
            switch role
                case lhp.algo.stochastic.genetic.ForestUtils.ROLE_BRIDGE
                    role = lhp.algo.stochastic.genetic.ForestUtils.ROLE_HUB;
                case lhp.algo.stochastic.genetic.ForestUtils.ROLE_SOURCE
                    role = lhp.algo.stochastic.genetic.ForestUtils.ROLE_SINGLE;
            end
        end

        function role = removeHub(role)
            switch role
                case lhp.algo.stochastic.genetic.ForestUtils.ROLE_HUB
                    role = lhp.algo.stochastic.genetic.ForestUtils.ROLE_BRIDGE;
                case lhp.algo.stochastic.genetic.ForestUtils.ROLE_SINGLE
                    role = lhp.algo.stochastic.genetic.ForestUtils.ROLE_SOURCE;
            end
        end

        function role = makeSource(role)
            switch role
                case lhp.algo.stochastic.genetic.ForestUtils.ROLE_BRIDGE
                    role = lhp.algo.stochastic.genetic.ForestUtils.ROLE_SOURCE;
                case lhp.algo.stochastic.genetic.ForestUtils.ROLE_HUB
                    role = lhp.algo.stochastic.genetic.ForestUtils.ROLE_SINGLE;
            end
        end

        function role = removeSource(role)
            switch role
                case lhp.algo.stochastic.genetic.ForestUtils.ROLE_SOURCE
                    role = lhp.algo.stochastic.genetic.ForestUtils.ROLE_BRIDGE;
                case lhp.algo.stochastic.genetic.ForestUtils.ROLE_SINGLE
                    role = lhp.algo.stochastic.genetic.ForestUtils.ROLE_HUB;
            end
        end

        function true_false = has_loops(forest, node, successor)
            % Return true if forest has any loops.
            s = forest.Successors;
            s(node) = successor;

            processed = zeros(1, numel(s));

            for start = 1:numel(s)
                onstack = zeros(1, numel(s));
                % Process only nodes we haven't visited before
                if (processed(start) == 0)
                    iterator = start;
                    while (true)
                        processed(iterator) = 1;
                        onstack(iterator) = 1;
                        my_other_successor = s(iterator);

                        if iterator == my_other_successor
                            % Ok.
                            break;
                        end

                        if onstack(my_other_successor) == 1
%                             strace = dbstack(1);
%
%                             warning("Loop detected! Node %d was visited twice!" ...
%                                 + " Occured in %s\n", ...
%                                 my_other_successor, strace(1).name);
                            true_false = true;
                            return;
                        end

                        iterator = my_other_successor;
                        continue;
                    end
                end
            end
            true_false = false;
            return;
        end

    end
end

