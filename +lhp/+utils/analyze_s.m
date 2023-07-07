function [hubs, sources, clusters] = analyze_s(s)
    %% Extract Hubs and Clusters from a Successorfunction s
    %
    % Parameters
    % ----------
    % s: vector
    %     A successorfunction s, calculated by some algorithm.
    %
    % Returns
    % -------
    % hubs: vector (row)
    %     A row vector containing the indices of the hubs in the
    %     successorfunction.
    % sources: vector(row)
    %     A row vector of all the sources in the given successorfunction. These
    %     aren't in any structured order. To find out whether a given source
    %     belongs to a certain cluster, look for the nodes ID in that cluster.
    % clusters: Matrix
    %     A matrix of all the clusters that were found in the
    %     successorfunction. Every column of the matrix is a cluster. In
    %     other words: This Matrix must be read column-wise!!
    %     Values of 0 denote the respective cluster vector.
    hubs = find(s(:, 1) == s(:, 2))';

    if (nargout >= 2)
        % NOTE: This function may seem inefficient for small gardens, but it's very
        % efficient for larger gardens! So please don't touch it unless you plan on
        % thoroughly profiling the results.
        % This is faster for small gardens only:
        %   s_pos = (s(:, 2) > 0);
        %   s_pos_sub = s(s_pos, :);
        %   sources = s_pos_sub(~any(bsxfun(@eq, s(s_pos, 1), s(s_pos, 2)'), 2), 1);
        sources = setdiff(s(s(:, 2) >= 0, 1), s(:, 2));
    end

    % Oftentimes, the calling functions of analyze_s don't ask for the clusters.
    % In these cases there is no need to extract the clusters from the successor
    % function. This saves a lot of execution time.
    if (nargout == 3)
        clusters = zeros(1);

        for hub = hubs
            neighbors = find(s(:, 2) == hub)';
            this_cluster = neighbors;
            while ~isempty(neighbors)
                % Get all nodes that rake to the current neighbors
                tmp = find(any(bsxfun(@eq, s(:, 2), neighbors), 2))';
                % Just take new elements
                idx = ~any(bsxfun(@eq, tmp, this_cluster'), 1);
                tmp = tmp(idx);
                % Append them to the vector of elements to search
                neighbors = tmp;
                % And to the vector of all neighbors in this cluster
                this_cluster = [this_cluster, tmp];
            end
            % Sort the elements in the vector.
            this_cluster = sort(this_cluster);

            % Extend the matrices/vectors to allow us to concatenate them.
            c_size = size(clusters, 1);
            tc_size = size(this_cluster, 2);
            if c_size < tc_size
                dummy = zeros(tc_size - c_size, size(clusters, 2));
                clusters = [clusters; dummy];
            elseif tc_size < c_size
                dummy = zeros(1, c_size - tc_size);
                this_cluster = [this_cluster, dummy];
            end
            clusters = [clusters, this_cluster'];
        end

        clusters(:, 1) = [];
    end
end
