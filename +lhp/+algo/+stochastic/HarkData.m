classdef HarkData
    %HARKDATA Defines a raking rule and determines the associated meta-data
    %   - foliage per node
    %   - foliage per cluster
    %   - predecessor and successor nodes
    %   - costs
    %   - sources and sinks
    %Call:
    %   >> HarkData([], pdata)
    %   generates a random rake rule including the meta-data
    %
    %   >> HarkData(s, pdata)
    %   generates for a given successor regulation the corresponding
    %   meta-data

    properties
        s;                          % Successor regulation
        Cluster;                    % Cluster nodes (Cell data structure)
        Hubs;                       % Hubs per Cluster with respect to s
        Sources;                    % Sources with respect to s
        FoliagePerCluster;          % Foliage per cluster with respect to s
        FoliagePerNode;             % Max. foliage on node with respect to s
        PredecessorOfNode;          % predecessor nodes of a node
        SuccessorOfNodes;           % successor nodes of a node
        ClusterOfNode;              % Cluster index of a node
        costs;                      % Costs with respect to s
        NodeToClusterProbability;   % Probability if node is added to a cluster
    end

    methods
        %% Constructors
        function self = HarkData(s, pdata, kvargs)
            %   >> HarkData([], pdata)
            %   generates a random rake rule including the meta-data
            %
            %   >> HarkData(s, pdata)
            %   generates for a given successor regulation the corresponding
            %   meta-data
            %   Optional Key-Value Parameters
            %   -----------------------------
            %   'NodeToClusterProbability'   : int, default: 25
            %       The maximum amount of leaves that one garden cell can carry
            arguments
                s (:, 2) double;
                pdata (1, 1) lhp.ProblemData;
                kvargs.NodeToClusterProbability (1, 1) double {mustBeNonnegative} = 0.1;
            end

            self.NodeToClusterProbability = kvargs.NodeToClusterProbability;

            if isempty(s)
                %  generate a random rake rule including the meta-data
                self = self.initial_clusters(pdata);
            else
                % generate the meta-data for a given successor regulation
                self.s = s;
                % determine hubs, sources, and clusters
                [hubs, sources, clusters] = lhp.utils.analyze_s(self.s);
                self.Sources = sources;
                self.Hubs = hubs;
                % calculate for each cluster the meta-data of the nodes
                for i=1:size(clusters,2)
                    nodes = clusters(clusters(:,i)~=0,i);
                    self = self.set_cluster_info(nodes, i, pdata);
                end
            end
            % get the different costs of the successor regulation
            self = self.calc_costs(pdata);
        end

        function [self] = initial_clusters(self, pdata)
            arguments
                self (1, 1) lhp.algo.stochastic.HarkData;
                pdata (1, 1) lhp.ProblemData;
            end

            % determine the number of nodes of the garden
            AnzElem = size(pdata.GMatrix, 1);

            % allocate memory
            self.s = [[1:AnzElem]', zeros(AnzElem,1)];
            self.Cluster = cell(1,AnzElem);
            self.Hubs = zeros(1,AnzElem);
            self.FoliagePerCluster = zeros(1,AnzElem);
            self.FoliagePerNode = zeros(1,AnzElem);
            self.PredecessorOfNode = cell(1,AnzElem);
            self.SuccessorOfNodes = cell(1,AnzElem);
            self.ClusterOfNode = zeros(1,AnzElem);

            % tabu list for selecting the nodes of a cluster
            tabu=zeros(1,AnzElem);

            indTabu = pdata.GMatrix(:,4) < 0;
            tabu(indTabu) = 1;
            self.s(indTabu,2)= -1;


            % count cluster
            indCluster = 0;

            % loop until tabu list is empty
            while 1
                % randomly select a node
                indices = find(tabu==0);
                if isempty(indices), break; end
                ind = randi(length(indices));
                node = indices(ind);

                % mark this node as visited in the tabu list
                tabu(node) = 1;
                laub = pdata.GMatrix(node,4);

                if laub == 0
                    % count cluster
                    indCluster = indCluster + 1;

                    % set meta-data to the cluster
                    self.s(node,2)= node;
                    self.Cluster{indCluster} = node;
                    self.Hubs(indCluster) = node;
                    self.FoliagePerCluster(indCluster) = laub;
                    self.FoliagePerNode(node) = laub;
                    self.SuccessorOfNodes{node} = node;
                    self.PredecessorOfNode{node} = node;
                    self.ClusterOfNode(node) = indCluster;
                else
                    % count cluster
                    indCluster = indCluster + 1;

                    % find nodes of the cluster
                    nodes = node;
                    [nodes,tabu] =  self.find_neighbor_node(node, nodes, tabu, laub, pdata);

                    % set the hub in the cluster
                    self = self.find_best_hub_in_cluster(nodes, indCluster, pdata);

                    % set meta-data in the cluster
                    self = self.set_cluster_info(nodes, indCluster, pdata);
                end
            end
            % reduce cells and arrays
            % self.Cluster = {self.Cluster{1,1:indCluster}};
            self.Cluster = self.Cluster(1,1:indCluster);
            self.Hubs = self.Hubs(1,1:indCluster);
            self.FoliagePerCluster = self.FoliagePerCluster(1,1:indCluster);

            % find the sources of the rake regulation
            self.Sources = setdiff(self.s(self.s(:, 2) >= 0, 1), self.s(:, 2));
        end

        function eq = compare(hdata1, hdata2)
            hubs1 = sort(hdata1.Hubs);
            hubs2 = sort(hdata2.Hubs);
            cluster1 = hdata1.ClusterOfNode(hubs1);
            cluster2 = hdata2.ClusterOfNode(hubs2);

            eq1 = lhp.algo.stochastic.HarkData.diff_array(hdata1.s(:,2), hdata2.s(:,2), "s");
            eq2 = lhp.algo.stochastic.HarkData.diff_cells(hdata1.Cluster(cluster1), hdata2.Cluster(cluster2), "Cluster");
            eq3 = lhp.algo.stochastic.HarkData.diff_array(hubs1, hubs2, "Hubs");
            eq4 = lhp.algo.stochastic.HarkData.diff_array(sort(hdata1.Sources), sort(hdata2.Sources), "Sources");
            eq5 = lhp.algo.stochastic.HarkData.diff_array(hdata1.FoliagePerCluster(cluster1), hdata2.FoliagePerCluster(cluster2), "FoliagePerCluster");
            eq6 = lhp.algo.stochastic.HarkData.diff_array(hdata1.FoliagePerNode, hdata2.FoliagePerNode, "FoliagePerNode");
            eq7 = lhp.algo.stochastic.HarkData.diff_cells(hdata1.PredecessorOfNode, hdata2.PredecessorOfNode, "PredecessorOfNode");
            eq8 = lhp.algo.stochastic.HarkData.diff_cells(hdata1.SuccessorOfNodes, hdata2.SuccessorOfNodes, "SuccessorOfNodes");
            %eq9 = lhp.algo.stochastic.HarkData.diff_array(hdata1.ClusterOfNode, hdata2.ClusterOfNode, "ClusterOfNode");
            %eq10 = HarkData.diff_array(hdata1.costs, hdata2.costs);
            eq = eq1 && eq2 && eq3 && eq4 && eq5 && eq6 && eq7 && eq8;% & eq9;
        end

        function [nodes,tabu] = find_neighbor_node(self, node, nodes, tabu, laub, pdata)
            arguments
                self (1, 1) lhp.algo.stochastic.HarkData;
                node (1, 1) double;
                nodes (:, :) double;
                tabu (:, :) double;
                laub (1, 1) double;
                pdata (1, 1) lhp.ProblemData;
            end
            % find neighboring node not yet visited
            N = lhp.algo.stochastic.bee.neighbors(node, pdata);
            N = N(tabu(N)~=1);

            if isempty(N)
                return;
            else
                % choose random neighboring node and determine amount of foliage
                ind = randi(length(N));
                nextnode = N(ind);
                nextLaub = pdata.GMatrix(nextnode,4);

                % add node to cluster if foliage quantity matches
                % (with probability 90)
                if (laub + nextLaub > pdata.Max_Val) || (rand() < self.NodeToClusterProbability) || (nextLaub == 0)
                    return;
                else
                    % update the foliage and cluster set as well as the tabu list
                    laub = laub + pdata.GMatrix(nextnode,4);
                    nodes = [nodes; nextnode];
                    tabu(nextnode) = 1;
                    % find more nodes of the cluster
                    [nodes, tabu] = self.find_neighbor_node(nextnode, nodes, tabu, laub, pdata);
                end
            end
        end

        function [self] = set_cluster_info(self, nodes, i, pdata)
            arguments
                self (1, 1) lhp.algo.stochastic.HarkData;
                nodes (:, :) double;
                i (1, 1) double;
                pdata (1, 1) lhp.ProblemData;
            end
            % set links: cluster <-> nodes
            self.ClusterOfNode(nodes) = i;
            self.Cluster{i} = nodes;
            % determine total foliage of the cluster
            self.FoliagePerCluster(i) = sum(pdata.GMatrix(nodes,4));
            % calculate successor of each node
            for node = nodes'
                self.SuccessorOfNodes{node} = self.get_successor_of_nodes(node);
            end
            % calculate predecessor of each node
            self = self.set_predecessor_of_nodes_in_cluster(nodes);
            % determine total foliage of each node during raking
            for node = nodes'
                self.FoliagePerNode(node) = sum(pdata.GMatrix(self.PredecessorOfNode{node},4));
            end
        end

        function [indices] = get_successor_of_nodes(self, node)
            arguments
                self (1, 1) lhp.algo.stochastic.HarkData;
                node (1, 1) double;
            end
            % define empty list
            indices = [];
            % special case if node is not rakable
            if self.s(node,2)<0, return; end
            % run through the raking regulation from starting node and collect
            % all visited nodes
            indices = [node];
            while self.s(node,2)~=node
                node = self.s(node,2);
                indices = [indices; node];
            end
        end

        function [self] = set_predecessor_of_nodes_in_cluster(self, nodes)
            arguments
                self  (1, 1) lhp.algo.stochastic.HarkData;
                nodes (:, :) double;
            end
            % initialize all cells with an empty array
            for i=1:length(nodes)
                self.PredecessorOfNode{nodes(i)} = [];
            end
            % run through all nodes and collect the predecessor
            for i=1:length(nodes)
                liste = [];
                nachfolger = self.SuccessorOfNodes{nodes(i)};
                % run through each successor node and collect the predecessor only,
                % if they have not yet been considered
                for j=1:size(nachfolger,1)
                    node = nachfolger(j);
                    if isempty(self.PredecessorOfNode{node})
                        liste = nachfolger(1:j);
                    end
                    self.PredecessorOfNode{node} = vertcat(self.PredecessorOfNode{node}, liste);
                end
            end
        end

        function [self] = find_best_hub_in_cluster(self, nodes, indCluster, pdata)
            arguments
                self (1, 1) lhp.algo.stochastic.HarkData;
                nodes (:, :) double;
                indCluster (1, 1) double;
                pdata (1, 1) lhp.ProblemData;
            end
            gr = graph(pdata.WAdjacency(nodes, nodes));
            [~, new_hub_idx] = min(sum(...
                    gr.distances() .* pdata.GMatrix(nodes, 4), 1));
            for idx = 1:numel(nodes)
                path = gr.shortestpath(new_hub_idx, idx);
                if numel(path) > 1
                    self.s(nodes(path(end)), 2) = nodes(path(end-1));
                else
                    % Current node is the hub
                    self.s(nodes(path(1)), 2) = nodes(path(1));
                end
            end
            self.Hubs(indCluster) = nodes(new_hub_idx);
            self = self.set_cluster_info(nodes, indCluster, pdata);
        end
        
        function [self] = find_best_hub_in_cluster2(self, nodes, indCluster, pdata)
            arguments
                self (1, 1) lhp.algo.stochastic.HarkData;
                nodes (:, :) double;
                indCluster (1, 1) double;
                pdata (1, 1) lhp.ProblemData;
            end
            % place hub on a node with maximum amount of foliage
            [self, flag] = self.set_hub_in_cluster(nodes, indCluster, pdata, 1);
            self = self.set_cluster_info(nodes, indCluster, pdata);
            K1 = self.calc_reduced_costs_of_cluster(indCluster, pdata);
            if flag
                % place hub on a node with minimum distance to the compost (if
                % this is not the same as the one with maximum amount of foliage)
                self2 = self.set_hub_in_cluster(nodes, indCluster, pdata,2);
                self2 = self2.set_cluster_info(nodes, indCluster, pdata);
                K2 = self2.calc_reduced_costs_of_cluster(indCluster, pdata);
                % make decision depending on the reduced costs (without walking
                % costs)
                if K2<K1
                    self = self2;
                end
            end
        end

        function [self,flag] = set_hub_in_cluster(self, nodes, indCluster, pdata, variante)
            arguments
                self (1, 1) lhp.algo.stochastic.HarkData;
                nodes (:, :) double;
                indCluster (1, 1) double;
                pdata (1, 1) lhp.ProblemData;
                variante (1,1) double;
            end
            % place hub either on a node with maximum amount of foliage or
            % on a node with minimum distance to the compost
            [~,ind1] = max(pdata.GMatrix(nodes,4));
            [~,ind2] = min(pdata.DMatrix(pdata.Target,nodes));
            % determine, if these are the same nodes
            if ind1 == ind2, flag=0; else flag=1; end
            if variante==1, ind = ind1; else, ind = ind2; end
            hub = nodes(ind);
            self.s(hub,2) = hub;
            self.Hubs(indCluster) = hub;
            % recursively set the raking regulation
            nodes = nodes(nodes~=hub);
            [self, ~] = self.set_hark_neighbor(hub, nodes, pdata);
        end

        function [self, nodes] = set_hark_neighbor(self, node, nodes, pdata)
            arguments
                self (1, 1) lhp.algo.stochastic.HarkData;
                node (1, 1) double;
                nodes (:, :) double;
                pdata (1, 1) lhp.ProblemData;
            end
            % determine all neighbor nodes
            allNeighbor = lhp.algo.stochastic.bee.neighbors(node, pdata);
            allNeighbor = allNeighbor(allNeighbor~=node);

            % set the nodes to be processed recrusively
            next_nodes = [];
            for i = 1:size(allNeighbor,1)
                nachbar = allNeighbor(i);
                % determine the nodes that are raked to "node" and remove them
                % from the cluster
                if ismember(nachbar, nodes)
                    self.s(nachbar,2) = node;
                    next_nodes = [next_nodes, nachbar];
                    nodes = nodes(nodes~=nachbar);
                    if isempty(nodes), return; end
                end
            end
            % apply the routine to the remaining nodes
            for i=1:size(next_nodes,2)
                [self, nodes] = self.set_hark_neighbor(next_nodes(i), nodes, pdata);
                if isempty(nodes), return; end
            end
        end

        function [self] = combine_cluster2(self, pdata)
            arguments
                self (1, 1) lhp.algo.stochastic.HarkData;
                pdata (1, 1) lhp.ProblemData;
            end
            % find clusters to consider
            indices = find((self.FoliagePerCluster>0) &  (self.FoliagePerCluster < pdata.Max_Val));

            while ~isempty(indices)
                % random selection from it and reduction of the array
                ind = randi(length(indices));
                ind1 = indices(ind);
                laub1 = self.FoliagePerCluster(ind1);
                indices = indices(indices~=ind1);

                % determine neighbor clusters over the neighbors of the
                % nodes
                nodes = self.Cluster{ind1};
                for i=randperm(size(nodes,1))
                    % determine neighbors of the current node
                    node = nodes(i);
                    nachbar = lhp.algo.stochastic.bee.neighbors(node, pdata);
                    nachbar = nachbar(nachbar~=node);
                    for j=randperm(length(nachbar))
                        % search for a neighbor from another cluster with
                        % matching foliage quantity
                        ind2 = self.ClusterOfNode(nachbar(j));
                        laub2 = self.FoliagePerNode(nachbar(j));
                        if ind1 ~= ind2 &&  laub2 > 0 && laub1 + laub2 <= pdata.Max_Val
                            % save the cluster to the smaller index
                            if ind1>ind2, indh = ind1; ind1=ind2; ind2=indh; end
                            % combine the nodes and set new hub
                            self.Cluster{ind1} = [self.Cluster{ind1}; self.Cluster{ind2}];
                            self.FoliagePerCluster(ind1) = laub1 + laub2;
                            self = self.find_best_hub_in_cluster(self.Cluster{ind1}, ind1, pdata);

                            % remove the second cluster from the set
                            anzCluster = size(self.Cluster,2);
                            self.Cluster = {self.Cluster{1:anzCluster~=ind2}};
                            self.FoliagePerCluster = self.FoliagePerCluster(1:anzCluster~=ind2);
                            self.Hubs = self.Hubs(1:anzCluster~=ind2);
                            anzCluster = anzCluster-1;

                            % update the cluster info of the nodes
                            for ii=ind1+1:anzCluster
                                nodes = self.Cluster{ii};
                                for jj=1:length(nodes)
                                    self.ClusterOfNode(nodes(jj))=ii;
                                end
                            end

                            % find the sources
                            self.Sources = setdiff(self.s(self.s(:, 2) >= 0, 1), self.s(:, 2));
                            return;
                        end
                    end
                end
            end
        end

        
        function [self] = combine_cluster(self, pdata)
            arguments
                self (1, 1) lhp.algo.stochastic.HarkData;
                pdata (1, 1) lhp.ProblemData;
            end
            % find clusters to consider
            indices = find((self.FoliagePerCluster>0) &  (self.FoliagePerCluster < pdata.Max_Val));

            while ~isempty(indices)
                % random selection from it and reduction of the array
                ind = randi(length(indices));
                ind1 = indices(ind);
                laub1 = self.FoliagePerCluster(ind1);
                indices = indices(indices~=ind1);

                % determine neighbor clusters over the neighbors of the
                % nodes
                nodes = self.Cluster{ind1};
                for i=randperm(size(nodes,1))
                    % determine neighbors of the current node
                    node = nodes(i);
                    nachbar = lhp.algo.stochastic.bee.neighbors(node, pdata);
                    nachbar = nachbar(nachbar~=node);
                    for j=randperm(length(nachbar))
                        % search for a neighbor from another cluster with
                        % matching foliage quantity
                        nnode = nachbar(j);
                        ind2 = self.ClusterOfNode(nnode);
                        laub2 = self.FoliagePerCluster(ind2);
                        if ind1 ~= ind2 &&  laub2 > 0 && laub1 + laub2 <= pdata.Max_Val
                            % combine/shift the nodes and set new hub/hubs
                            if self.s(nnode,1)==self.s(nnode,2) 
                                % save the cluster to the smaller index
                                if ind1>ind2, indh = ind1; ind1=ind2; ind2=indh; end
                                self.Cluster{ind1} = [self.Cluster{ind1}; self.Cluster{ind2}];
                                self.FoliagePerCluster(ind1) = laub1 + laub2;
                                self = self.find_best_hub_in_cluster(self.Cluster{ind1}, ind1, pdata);

                                % remove the second cluster from the set
                                anzCluster = size(self.Cluster,2);
                                self.Cluster = {self.Cluster{1:anzCluster~=ind2}};
                                self.FoliagePerCluster = self.FoliagePerCluster(1:anzCluster~=ind2);
                                self.Hubs = self.Hubs(1:anzCluster~=ind2);
                                anzCluster = anzCluster-1;

                            % update the cluster info of the nodes
                                for ii=ind1+1:anzCluster
                                    nodes = self.Cluster{ii};
                                    for jj=1:length(nodes)
                                        self.ClusterOfNode(nodes(jj))=ii;
                                    end
                                end

                                % find the sources
                                self.Sources = setdiff(self.s(self.s(:, 2) >= 0, 1), self.s(:, 2));
                                return;
                            else
                                shift_nodes = self.PredecessorOfNode{nnode};
                                clusternodes = self.Cluster{ind2};
                                for shift_node=shift_nodes'
                                    clusternodes = clusternodes(clusternodes~=shift_node);
                                end
                                self.Cluster{ind2} = clusternodes;
                                self.FoliagePerCluster(ind2) = self.FoliagePerCluster(ind2) - laub2;
                                self = self.find_best_hub_in_cluster(self.Cluster{ind2}, ind2, pdata);

                                self.Cluster{ind1} = [self.Cluster{ind1}; shift_nodes];
                                self.FoliagePerCluster(ind1) = laub1 + laub2;
                                self = self.find_best_hub_in_cluster(self.Cluster{ind1}, ind1, pdata);

                                % find the sources
                                self.Sources = setdiff(self.s(self.s(:, 2) >= 0, 1), self.s(:, 2));
                                return;
                            end
                        end
                    end
                end
            end
        end

        function [self] = separate_cluster(self, pdata)
            arguments
                self (1, 1) lhp.algo.stochastic.HarkData;
                pdata (1, 1) lhp.ProblemData;
            end
            % randomly determine a cluster with at least 2 nodes and generate two clusters from it
            for ind=randperm(size(self.s,1))
                if (self.s(ind,1)~=self.s(ind,2)) && (self.s(ind,2)>0)  && pdata.GMatrix(self.s(ind,1),4)>0
                    % Replace the previous cluster with one of the newly created cluster
                    indCluster1 = self.ClusterOfNode(self.s(ind,1));

                    % determine all previous nodes of the current cluster
                    nodes2 = self.Cluster{indCluster1};

                    % determine the predecessors of the separator node for the one cluster
                    self.Cluster{indCluster1} = self.PredecessorOfNode{self.s(ind,1)};
                    [self] = self.find_best_hub_in_cluster(self.Cluster{indCluster1}, indCluster1, pdata);

                    % create another cluster and determine the remaining nodes
                    indCluster2 = size(self.Cluster,2) + 1;
                    nodes1 = self.Cluster{indCluster1};
                    for i=1:size(self.Cluster{indCluster1},1)
                        nodes2 = nodes2(nodes2~=nodes1(i));
                    end
                    self.Cluster{indCluster2} = nodes2;
                    self = self.find_best_hub_in_cluster(self.Cluster{indCluster2}, indCluster2, pdata);

%                     % update the cluster information or meta data of the
%                     % new cluster
%                     self = self.set_cluster_info(self.Cluster{indCluster1}, indCluster1, pdata);
%                     self = self.set_cluster_info(self.Cluster{indCluster2}, indCluster2, pdata);

                    % find the sources
                    self.Sources = setdiff(self.s(self.s(:, 2) >= 0, 1), self.s(:, 2));

                    return;
                end
            end
        end

        function [self] = find_neighbor(self, pdata)
            arguments
                self (1, 1) lhp.algo.stochastic.HarkData;
                pdata (1, 1) lhp.ProblemData;
            end
			s1 = self.s;
            % selection of a neighborhood solution
            zufall = randi(3);
            switch zufall
                case 1
                    % if possible, merge two clusters together
                    self = self.combine_cluster(pdata);
                case 2
                    % split a cluster into two clusters
                    self = self.separate_cluster(pdata);
                case 3
                    % divide a cluster into two and merge two additional together
                    self = self.separate_cluster(pdata);
                    self = self.combine_cluster(pdata);
            end
            % determine the costs
			if sum(sum(s1-self.s))==0
			  % disp(sprintf("No neighbour detected:%d\n", zufall));
              self = self.separate_cluster(pdata);
            end
            self = self.calc_costs(pdata);
        end

        %% CROSSOVER AND MUTATION
        function [hdata1, hdata2] = cross_hubs(hdata1, hdata2, pdata)
            % get random hubs
            H1_idx = randsample(1:length(hdata1.Hubs), 1);
            H2_idx = randsample(1:length(hdata2.Hubs), 1);
            H1 = hdata1.Hubs(H1_idx);
            H2 = hdata2.Hubs(H2_idx);
            hdata1 = inject_hub(hdata1, H2, pdata);
            hdata2 = inject_hub(hdata2, H1, pdata);
        end

        function hdata = inject_hub(hdata, hub, pdata)
            if ~ismember(hub, hdata.Hubs)
                path_to_hub = hdata.SuccessorOfNodes{hub};
                hdata = reverse_path(hdata, path_to_hub);

                %eq = compare(hdata, lhp.algo.stochastic.HarkData(hdata.s, pdata));
            end
        end

        function self = reverse_path(self, path)
            % subtract previous raking work
            self.SuccessorOfNodes{path(1)} = [path(1)];
            for j=self.PredecessorOfNode{path(1)}'
                if j~=path(1)
                    self.SuccessorOfNodes{j} = self.SuccessorOfNodes{j}(1:find(self.SuccessorOfNodes{j} == path(1)));
                end
            end
            curr_Laub = self.FoliagePerNode(path(1));
            new_successors = [path(1)];
            remove_predecessors = self.PredecessorOfNode{path(1)};
            for i=2:length(path)
                buffer = self.FoliagePerNode(path(i));
                self.FoliagePerNode(path(i)) = self.FoliagePerNode(path(i)) - curr_Laub;
                curr_Laub = buffer;
                % update predecessors and successors
                self.PredecessorOfNode{path(i)} = setdiff(self.PredecessorOfNode{path(i)}, remove_predecessors);
                remove_predecessors = [self.PredecessorOfNode{path(i)}; remove_predecessors];
                new_successors = [path(i); new_successors]; % does it belong to its own successors?
                self.SuccessorOfNodes{path(i)} = new_successors;
                % also add all new successors to the predecessors
                for j=self.PredecessorOfNode{path(i)}'
                    if j~=path(i)
                        self.SuccessorOfNodes{j} = [self.SuccessorOfNodes{j}(1:find(self.SuccessorOfNodes{j} == path(i))) ; new_successors(2:end)];
                    end
                end
            end

            % add new raking work
            curr_Laub = self.FoliagePerNode(path(end));
            new_predecessors = self.PredecessorOfNode{path(end)};
            for i=length(path)-1:-1:1
                self.FoliagePerNode(path(i)) = self.FoliagePerNode(path(i)) + curr_Laub;
                curr_Laub = self.FoliagePerNode(path(i));
                % add new predecessors
                new_predecessors = [self.PredecessorOfNode{path(i)}; new_predecessors];
                self.PredecessorOfNode{path(i)} = new_predecessors;
            end

            % reverse path
            self.s(path(1),2) = path(1);
            for i=2:1:length(path)
                self.s(path(i),2) = path(i-1);
            end

            % update hubs and sources
            self.Hubs(self.Hubs == path(end)) = path(1);
            self.Sources = self.Sources(self.Sources ~= path(1));
            if ~any(self.s(:, 2) == path(end))
                self.Sources = [self.Sources; path(end)];
            end
        end

        function self = neighbor_swap(self, pdata)
            % changes either the predecessor or successor of a random node
            % if possible.
            ind = find(self.s(:,2)>=0);
            index = ind(randi(length(ind)));
            self = neighbor_swap_single(self, pdata, index, randi(2));
            %eq = compare(self, lhp.algo.stochastic.HarkData(self.s, pdata));
        end

        function self = neighbor_swap_single(self, pdata, node, mode)
            % changes either the predecessor(mode=1) or successor(mode=2)
            % of a certain node if possible.
            N = lhp.algo.stochastic.bee.neighbors(node, pdata);
            N = N(randperm(length(N)));

            switch mode
                case 1
                    for i = 1:length(N)
                        if (self.s(N(i),2) ~= node) && check_neighbor_swap(self, pdata, N(i), node)
                            self = fix_path_neighbor_swap(self, N(i), node);
                            return;
                        end
                    end
                case 2
                    for i = 1:length(N)
                        if (self.s(node,2) ~= N(i)) && check_neighbor_swap(self, pdata, node, N(i))
                            self = fix_path_neighbor_swap(self, node, N(i));
                            return;
                        end
                    end
            end
        end

        function b = check_neighbor_swap(self, pdata, from, to)
            % checks if the directed edge (from -> to) breaks either
            % the cycle or capacity rule.

            if from == to
                % making a hub is always valid
                b = true;
            elseif self.ClusterOfNode(from) == self.ClusterOfNode(to)
                % cycle rule
                b = false;
            elseif self.FoliagePerNode(from) + self.FoliagePerNode(self.SuccessorOfNodes{to}(end)) > pdata.Max_Val
                % capacity rule
                b = false;
            else
                b = true;
            end
        end

        function self = fix_path_neighbor_swap(self, from, to)
            % switch depending if it was a hub and will be a hub
            isHub = self.s(from, 2) == from;
            willBeHub = from == to;
            if isHub && willBeHub
                % if it was a hub and will be a hub nothing happens
                return;
            elseif isHub && ~willBeHub
                % remove hub status and cluster
                self.Hubs = self.Hubs(self.Hubs ~= from);
                cluster = self.ClusterOfNode(from);
                self.Cluster{cluster} = [];
                self.FoliagePerCluster(cluster) = -1;
            elseif ~isHub && willBeHub
                % add to hubs, remove from sources and create new cluster
                self.Hubs = [self.Hubs, from];
                self.Sources = self.Sources(self.Sources ~= from);
                cluster = lhp.algo.stochastic.HarkData.find_first_empty_cluster(self.Cluster);
                self.Cluster{cluster} = self.PredecessorOfNode{from};
                self.FoliagePerCluster(cluster) = self.FoliagePerNode(from);
                self.ClusterOfNode(from) = cluster;
            end

            predecessors = self.PredecessorOfNode{from};
            value = self.FoliagePerNode(from);

            % remove value and predecessors from old path
            if ~isHub
                successor = from;
                while successor ~= self.s(successor,2)
                    successor = self.s(successor,2);
                    self.FoliagePerNode(successor) = self.FoliagePerNode(successor) - value;
                    self.PredecessorOfNode{successor} = setdiff(self.PredecessorOfNode{successor}, predecessors);
                end
                % remove value and predecessors from cluster
                cluster = self.ClusterOfNode(successor);
                self.FoliagePerCluster(cluster) = self.FoliagePerCluster(cluster) - value;
                self.Cluster{cluster} = setdiff(self.Cluster{cluster}, predecessors);
            end

            % change successor
            old_successor = self.s(from,2);
            self.s(from,2) = to;
            self.Sources = self.Sources(self.Sources~=to);
            if ~any(self.s(:, 2) == old_successor)
                self.Sources = [self.Sources; old_successor];
            end

            % add value and predecessors to new path
            new_successors = [];
            if ~willBeHub
                successor = from;
                while successor ~= self.s(successor,2)
                    successor = self.s(successor,2);
                    new_successors = [new_successors; successor];
                    self.FoliagePerNode(successor) = self.FoliagePerNode(successor) + value;
                    self.PredecessorOfNode{successor} = [self.PredecessorOfNode{successor}; predecessors];
                end
                % add value and predecessors to cluster
                cluster = self.ClusterOfNode(successor);
                self.FoliagePerCluster(cluster) = self.FoliagePerCluster(cluster) + value;
                self.Cluster{cluster} = [self.Cluster{cluster}; predecessors];
            else
                cluster = self.ClusterOfNode(from);
            end
            % add new successors to 'from' and all predecessors of it
            for i=self.PredecessorOfNode{from}'
                self.ClusterOfNode(i) = cluster;
                self.SuccessorOfNodes{i} = [self.SuccessorOfNodes{i}(1:find(self.SuccessorOfNodes{i} == from)); new_successors];
            end
        end

        %% COST FUNCTIONS
        function [K] = calc_reduced_costs_of_cluster(self, indCluster, pdata)
            arguments
                self (1, 1) lhp.algo.stochastic.HarkData;
                indCluster (1, 1) double;
                pdata (1, 1) lhp.ProblemData;
            end
            nodes  = self.Cluster{indCluster};
            H = sum(self.FoliagePerNode(nodes)'.*diag(pdata.DMatrix(self.s(nodes,1),self.s(nodes,2))))*pdata.Rake_Param;

            dist = 2*pdata.DMatrix(pdata.Target,self.Hubs(indCluster));
            anz = ceil(self.FoliagePerCluster(indCluster)/pdata.Max_Trans);
            T = dist*anz'*pdata.Trans_Param;

            K = H + T;
        end

        function [self] = calc_costs(self, pdata)
            arguments
                self (1, 1) lhp.algo.stochastic.HarkData;
                pdata (1, 1) lhp.ProblemData;
            end
            self = self.calc_hark_costs(pdata); %1
            self = self.calc_route_costs(pdata); %2
            self = self.calc_transport_costs(pdata); %3
            self.costs(4) = sum(self.costs(1:3));
        end

        function [self] = calc_costs_cheap(self, pdata)
            arguments
                self (1, 1) lhp.algo.stochastic.HarkData;
                pdata (1, 1) lhp.ProblemData;
            end
            self = self.calc_hark_costs(pdata);
            self.costs(2) = 0;
            self = self.calc_transport_costs(pdata);
            self.costs(4) = sum(self.costs(1:3));
        end

        function [self] = chop_costs(self)
            arguments
                self (1, 1) lhp.algo.stochastic.HarkData;
            end
            self.costs(2) = 0;
            self.costs(4) = sum(self.costs(1:3));
        end

        function [self] = calc_hark_costs(self, pdata)
            arguments
                self (1, 1) lhp.algo.stochastic.HarkData;
                pdata (1, 1) lhp.ProblemData;
            end
            ind = find(self.s(:,2)>=0 & self.s(:,2)~=self.s(:,1));
            self.costs(1) = sum(self.FoliagePerNode(ind)'.*diag(pdata.DMatrix(self.s(ind,1),self.s(ind,2))))*pdata.Rake_Param;
        end

        function [self] = calc_transport_costs(self, pdata)
            arguments
                self (1, 1) lhp.algo.stochastic.HarkData;
                pdata (1, 1) lhp.ProblemData;
            end
            dist = 2*pdata.DMatrix(pdata.Target,self.Hubs);
            clusters = self.ClusterOfNode(self.Hubs);
            anz = ceil(self.FoliagePerCluster(clusters)/pdata.Max_Trans);
            self.costs(3) = dist*anz'*pdata.Trans_Param;
        end

        function [self] = calc_route_costs(self, pdata)
            arguments
                self (1, 1) lhp.algo.stochastic.HarkData;
                pdata (1, 1) lhp.ProblemData;
            end
            sources = self.Sources;
            if isempty(sources)
                % if there are no sources there is no route cost
                % this prevents empty multiplication leading to errors
                self.costs(2) = 0;
                return;
            end
            sub_hubs = zeros(size(self.s,1),1);
            for i=1:size(self.s,1)
                if (self.s(i,2) ~= -1 && self.s(i,2) ~= self.s(i,1))
                    sub_hubs(self.s(i,2)) = sub_hubs(self.s(i,2))+1;
                else
                    sub_hubs(self.s(i,1)) = -Inf;
                end
            end

            [dist, goto_ind] = min(pdata.DMatrix(pdata.Start, sources));
            WA = dist;
            node =sources(goto_ind);
            while ~isempty(sources)
                sources = sources(sources~=node);
                while self.s(node,1) ~= self.s(node,2)
                    dist = pdata.DMatrix(node, self.s(node,2));
                    WA = WA + dist;
                    node = self.s(node,2);
                    if sub_hubs(node)>1
                        sub_hubs(node) = sub_hubs(node) - 1;
                        break;
                    end
                end
                if isempty(sources), break; end
                [dist, goto_ind] = min(pdata.DMatrix(node, sources));
                node =sources(goto_ind);
                WA = WA + dist;
            end
            WA = WA + pdata.DMatrix(node, pdata.Start);
            WA = WA + 2*pdata.DMatrix(pdata.Start, pdata.Target);
            self.costs(2) = WA*pdata.Unprod_Param;
        end

        function plot(self, pdata, ax)
            arguments
                self (1, 1) lhp.algo.stochastic.HarkData
                pdata (1, 1) lhp.ProblemData
                ax (1, 1) matlab.graphics.axis.Axes = axes();
            end
            lhp.utils.cluster_plot(pdata, self.s, ax);
        end
    end

    methods (Access=private)

    end

    methods (Static)

        function hdata = initialHarkData(verfahren, pdata, useHeuristics)
            % randomly initialize a HarkData object using certain
            % heuristics
            if useHeuristics
%                 [~, result] = verfahren(randi([1, length(verfahren)])).add_new_data(...
%                     pdata);
%                 hdata = lhp.algo.stochastic.HarkData(result.s, pdata);
                [~, result] = verfahren.add_new_data(pdata);
                s = lhp.utils.skip_zero_hubs(pdata, result.s);
                s = lhp.utils.hz(pdata,s,'Median');
                s = lhp.utils.skip_zero_hubs(pdata, s);
                hdata = lhp.algo.stochastic.HarkData(s, pdata);
            else
                hdata = lhp.algo.stochastic.HarkData([], pdata);
            end
        end

        function index = find_first_empty_cluster(clusters)
            index = 1;
            while index <= length(clusters)
                if isempty(clusters{index})
                    return;
                end
                index = index + 1;
            end
        end

        function eq = diff_array(arr1, arr2, name)
            arr1 = lhp.algo.stochastic.HarkData.arr_remove_last_zeros(arr1);
            if size(arr1) == size(arr2)
                diff = ~(arr1==arr2);
                if any(diff)
                    eq = false;
                    ind = find(diff);
                    disp(name + " not equal!");
                    disp("different indices: " + ind);
                    disp("1(ind): " + arr1(ind));
                    disp("2(ind): " + arr2(ind));
                else
                    eq = true;
                end
            else
                eq = false;
                disp(name + " not equal length!")
                disp("1: " + arr1);
                disp("2: " + arr2);
            end
        end

        function eq = diff_cells(carr1, carr2, name)
            carr1 = lhp.algo.stochastic.HarkData.carr_remove_last_zeros(carr1);
            if size(carr1) == size(carr2)
                eq = true;
                for i=1:length(carr1)
                    eq = eq && lhp.algo.stochastic.HarkData.diff_array(sort(carr1{i}), sort(carr2{i}), name + "{"+i+"}");
                end
            else
                eq = false;
                disp(name + " not equal length!")
                for i=1:min(length(carr1),length(carr2))
                    lhp.algo.stochastic.HarkData.diff_array(sort(carr1{i}), sort(carr2{i}), name + "{"+i+"}");
                end
                if length(carr1) > length(carr2)
                    disp(name + "1 extra elements:")
                    carr = carr1;
                else
                    disp(name + "2 extra elements:")
                    carr = carr2;
                end
                for i=min(length(carr1),length(carr2))+1:max(length(carr1),length(carr2))
                    disp(name + "{i}: " + carr{i});
                end
            end
        end

        function arr = arr_remove_last_zeros(arr)
            for i=length(arr):-1:1
                if arr(i) == 0
                    arr(i) = [];
                else
                    return;
                end
            end
        end

        function carr = carr_remove_last_zeros(carr)
            for i=length(carr):-1:1
                if isempty(carr{i})
                    carr(i) = [];
                else
                    return;
                end
            end
        end
    end
end

