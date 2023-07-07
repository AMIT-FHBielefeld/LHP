classdef Forest
    %FOREST Class for forest structure. Very flat version of Digraph.
    %       author: kabdelhak

    properties
        Index;      % Unique index in the population
        Roles;      % Refers to ForestUtils.ROLE_
        Successors; % Actual chromosome containing rake directions
        Ordering;   % [Optional] Raking order. Not saved during simulation.
        Values;     % Starting values of each node
        Acc_Values; % Accumulated values after raking
        Max_Value;  % Maximum allowed value per node
    end

    methods
        %% Constructor
        function forest = Forest(index,roles,successors,acc_values,values,max_value)
            % Basic constructor for forest structure. Initializes a
            % multiple tree structures from successor values. Empty
            % initialization possible.
            % Note: Does not initially test for cycles and max_value.
            if exist('index','var')
                forest.Index = index;
                forest.Roles = roles;
                forest.Successors = successors;
                forest.Ordering = lhp.algo.stochastic.genetic.ForestUtils.ORDER_UNORDERED;
                forest.Acc_Values = acc_values;
                forest.Values = values;
                forest.Max_Value = max_value;
            end
        end

        %% Consistency checks
        function bool = checkForestMutation(forest,node,successor)
            % Checks if proposed mutation of node to successor is possible.
            [bool_loop, hub] = lhp.algo.stochastic.genetic.ForestUtils.checkLoopPrevention(forest,node,successor);
            if bool_loop
                bool = lhp.algo.stochastic.genetic.ForestUtils.checkMaximumCapacity(forest,node,successor,hub);
            else
                bool = false;
            end
        end

        %% Genetic operations
        function forest = mutateForest(forest,node,new_successor)
            % Mutates the forest such that it changes the successor of a node.
            % WARNING: Check with 'checkForestMutation' before using.
            old_successor = forest.Successors(node);
            [forest, skip] = mutateForest1(forest,node,new_successor,old_successor);
            if ~skip
                forest = mutateForest2(forest,node,new_successor);
            end
            forest = updateRoles(forest,node,old_successor,new_successor);
            forest.Successors(node) = new_successor;
        end


        function [forest, skip] = mutateForest1(forest,node,new_successor,old_successor)
           % Traverses from node to node_hub and updates (old way -)
           if ~lhp.algo.stochastic.genetic.ForestUtils.isHub(forest.Roles(node))
               iterator = old_successor;
               while ~lhp.algo.stochastic.genetic.ForestUtils.isHub(forest.Roles(iterator)) && iterator ~= new_successor
                   forest.Acc_Values(iterator) = forest.Acc_Values(iterator) - forest.Acc_Values(node);
                   iterator = forest.Successors(iterator);
               end
               if iterator==new_successor
                   skip = true;
               else
                   forest.Acc_Values(iterator) = forest.Acc_Values(iterator) - forest.Acc_Values(node);
                   skip = false;
               end
           else
               skip = false;
           end
        end


        function forest = mutateForest2(forest,node,new_successor)
            % Traverses from new_successor to new_successor_hub and updates
            % (new way +)
            if node~=new_successor
                iterator = new_successor;
                while ~lhp.algo.stochastic.genetic.ForestUtils.isHub(forest.Roles(iterator))
                    forest.Acc_Values(iterator) = forest.Acc_Values(iterator) + forest.Acc_Values(node);
                    iterator = forest.Successors(iterator);
                end
                forest.Acc_Values(iterator) = forest.Acc_Values(iterator) + forest.Acc_Values(node);
            end
        end

        function forest = injectHub(forest,node)
            % Incjets the Hub node into the forest by reversing the path
            % from node to the current hub in observed tree.
            val = forest.Acc_Values(node);
            iterator = forest.Successors(node);
            predecessor = node;
            forest.Roles(node) = lhp.algo.stochastic.genetic.ForestUtils.ROLE_HUB;
            forest.Successors(node) = node;

            while ~lhp.algo.stochastic.genetic.ForestUtils.isHub(forest.Roles(iterator))
                forest.Acc_Values(iterator) = forest.Acc_Values(iterator) - val;
                val = val + forest.Acc_Values(iterator);
                temp = predecessor;
                predecessor = iterator;
                iterator = forest.Successors(iterator);
                forest.Successors(predecessor) = temp;
            end

            forest.Acc_Values(iterator) = forest.Acc_Values(iterator) - val;
            val = forest.Acc_Values(iterator);

            if forest.Values(iterator) == forest.Acc_Values(iterator)
                forest.Roles(iterator) = lhp.algo.stochastic.genetic.ForestUtils.ROLE_SOURCE;
            else
                forest.Roles(iterator) = lhp.algo.stochastic.genetic.ForestUtils.ROLE_BRIDGE;
            end

            forest.Successors(iterator) = predecessor;
            iterator = forest.Successors(iterator);

            while ~lhp.algo.stochastic.genetic.ForestUtils.isHub(forest.Roles(iterator))
                forest.Acc_Values(iterator) = forest.Acc_Values(iterator) + val;
                val = forest.Acc_Values(iterator);
                iterator = forest.Successors(iterator);
            end

            forest.Acc_Values(iterator) = forest.Acc_Values(iterator) + val;
        end

        %% Update functions
        function forest = updateRoles(forest,node,old_successor,new_successor)
            % Updates the Roles of three given nodes after a mutation.
            if node == new_successor
                forest.Roles(node) = lhp.algo.stochastic.genetic.ForestUtils.makeHub(forest.Roles(node));
            else
                forest.Roles(node) = lhp.algo.stochastic.genetic.ForestUtils.removeHub(forest.Roles(node));
                forest.Roles(new_successor) = lhp.algo.stochastic.genetic.ForestUtils.removeSource(forest.Roles(new_successor));
            end

            if forest.Values(old_successor) == forest.Acc_Values(old_successor)
                forest.Roles(old_successor) = lhp.algo.stochastic.genetic.ForestUtils.makeSource(forest.Roles(old_successor));
            end
        end

        function forests = updateIndices(forests)
            % Updates the index property of all forests.
            for i=1:length(forests)
                forests(i).Index = i;
            end
        end

    end
end


