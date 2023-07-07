function s = random_s(pdata)
%%RANDOM_S Generate a randomized successor function.
%
%   Given a problem definition, this function creates a completely random
%   solution for it. It is inteded to be useful to bio-inspired algorithms that
%   work with populations and may thus require the generation of random
%   solutions (individuals).
%
%   Parameters
%   ----------
%   pdata: ProblemData
%       An object of type ProblemData that describes the problem to solve.
%
%   Returns
%   -------
%   s: vector of double
%       A successor function.
    arguments
        pdata (1, 1) lhp.ProblemData
    end

    candidates = find(pdata.Garden' >= 0);
    blockades  = (pdata.Garden' <  0);

    % Successor function.
    % We add a third row to keep track of the cluster ID that any given node is
    % in. Refer to the code below for more information.
    s = zeros(numel(pdata.Garden), 3);
    s(:, 1) = (1:size(s, 1));
    s(blockades, 2) = -1;

    % For housekeeping.
    cluster_leaves = zeros(size(s, 1), 1);  % Amount of leaves per cluster
    highest_cluster = 0;                    % Highest cluster index to date

    while ~isempty(candidates)
        % 1. Choose a random node of the ones we haven't introspected yet.
        node = candidates(randi(numel(candidates), 1));
        % Get the nodes amount of leaves.
        node_leaves = pdata.GMatrix(node, 4);
        % Check if the node is part of a cluster already
        node_cluster = s(node, 3);

        % 2. Get all possible neighbors we may move to.
        %   The node itself is a viable option too (Creates "sinks").
        neighbors = find(pdata.Adjacency(node, :));

        while 1
            % 3. Pick a neighbor to move to.
            possible_neighbor = neighbors(randi(numel(neighbors), 1));
            % And remove the neighbor from the list so we don't pick doubles.
            neighbors = neighbors(neighbors ~= possible_neighbor);

            % If we chose ourselves we can skip the code below, because we
            % create a sink. That is always valid.
            if (possible_neighbor == node)
                if (~node_cluster)
                    % Node wasn't part of any cluster yet.
                    % Create a new cluster for that node.
                    highest_cluster = highest_cluster + 1;
                    s(node, 3) = highest_cluster;
                    cluster_leaves(highest_cluster) = node_leaves;
                end

                s(node, 2) = node;
                break;
            end

            neighbor_cluster = s(possible_neighbor, 3);
            if (node_cluster == neighbor_cluster)
                if (node_cluster == 0)
                    % Both nodes aren't part of any cluster yet.
                    % Create a new cluster for them.
                    % Check if they violate the maximum amount of leaves.
                    cum_leaves = node_leaves + pdata.GMatrix(possible_neighbor, 4);
                    if (cum_leaves > pdata.Max_Val)
                        % Too much leaves, pick new neighbor.
                        continue;
                    end

                    % Create a new cluster
                    highest_cluster = highest_cluster + 1;
                    s(node, 3) = highest_cluster;
                    s(possible_neighbor, 3) = highest_cluster;
                    cluster_leaves(highest_cluster) = cum_leaves;

                    s(node, 2) = possible_neighbor;
                    break;
                else
                    % Both nodes are part of the same cluster already!
                    % We mustn't make a connection then, otherwise we create a
                    % cycle!!
                    % Pick a new neighbor.
                    continue;
                end
            elseif ((node_cluster == 0) && (neighbor_cluster ~= 0))
                % Selected node isn't part of any cluster.
                % Check if it can fit into the cluster of the neighbor
                if cluster_leaves(neighbor_cluster) > ...
                        (pdata.Max_Val - node_leaves)
                    % Overflow. Pick a new neighbor
                    continue;
                else
                    s(node, 3) = neighbor_cluster;
                    cluster_leaves(neighbor_cluster) = ...
                        cluster_leaves(neighbor_cluster) + node_leaves;

                    % Add to s
                    s(node, 2) = possible_neighbor;
                    break;
                end
            elseif ((node_cluster ~= 0) && (neighbor_cluster ~= 0))
                % This is a corner case.
                % WE MUST ONLY ASSUME THAT THE NODE_CLUSTER DOESN'T HAVE A SINK
                % YET! THIS IS NOT NECESSARILY TRUE FOR THE NEIGHBOR CLUSTER!
                if (cluster_leaves(node_cluster) + ...
                        cluster_leaves(neighbor_cluster) > pdata.Max_Val)
                    % Overflow, pick a new neighbor
                    continue;
                else
                    s(s(:, 3) == node_cluster, 3) = neighbor_cluster;
                    cluster_leaves(neighbor_cluster) = ...
                        cluster_leaves(neighbor_cluster) + ...
                        cluster_leaves(node_cluster);

                    s(node, 2) = possible_neighbor;
                end
            elseif ((node_cluster ~= 0) && (neighbor_cluster == 0))
                % Add the neighbor to our cluster
                s(possible_neighbor, 3) = node_cluster;
                cluster_leaves(node_cluster) = ...
                    cluster_leaves(node_cluster) + ...
                    pdata.GMatrix(possible_neighbor, 4);

                s(node, 2) = possible_neighbor;
            end
        end

        candidates(candidates == node) = [];
    end

    % Third col that keeps track of the clusters isn't meant for return to the
    % user!
    s(:, 3) = [];
end
