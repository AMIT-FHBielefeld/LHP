function s_new = hz(problem_data, s, method, kvargs)
%HZ Zentriere die Hubs einer Nachfolgerfunktion.
%
%   Diese Funktion erhaelt als Parameter eine berechnete Nachfolgerfunktion
%   und veraendert, unter Beibehaltung der gebildeten Cluster, die
%   Harkausrichtung. Die Wahl des neuen Hubs in einem Cluster kann vom Nutzer
%   bestimmt werden.
%
%   Parameters
%   ----------
%   problem_data: ProblemData
%       Eine Beschreibung des aktuellen Problems.
%   s: vector
%       Eine gueltige, bereits berechnete Nachfolgerfunktion. Kann leer sein,
%       wenn die Zentrierung auf Basis von Cluster statt einer existierenden
%       Nachfolgerfunktion erfolgt. (Siehe unten)
%   method: string
%       Eine Vorschrift, nach der der neue Hub im Cluster ausgesucht wird.
%       Kann eine der folgenden Moeglichkeiten sein:
%
%       - 'MaxLaub': Knoten mit groesster Laubmenge wird zum Hub
%       - 'MinLaub': Knoten mit geringster Laubmenge wird zum Hub
%       - 'Median': Knoten mit geringster gewichteter Entfernung wird zum Hub.
%         Zur Gewichtung wird die Laubmenge verwendet. (default)
%       - 'MinKompost': Knoten mit geringster Entfernung zum Kompost wird zum
%         neuen Hub
%       - 'SmallestIndex': Knoten mit kleinstem Index (Nord-West) wird zum neuen
%         Hub
%       - 'KeepHubs': Behalte die Hubs und generiere eine effiziente
%         Hark-Vorschrift für die zugehörigen Cluster
%
%   Keyword Arguments
%   -----------------
%   'Cluster': matrix of double
%       A matrix representation of clusters. Alternative way of supplying the
%       clusters to this function. If this option is present, any successor
%       function "s" will be ignored, and the clusters here will be used
%       instead.
%       The matrix must be organized as follows:
%
%       - Each column contains a valid cluster
%       - Clusters that contain less nodes than the matrix has rows are filled
%         up with zeroes
%
%   Returns
%   -------
%   s: vector
%       Eine Hubzentrierte Nachfolgerfunktion.
    arguments
        problem_data (1, 1) lhp.ProblemData
        s (:, 2) double
        method (1, 1) string {mustBeMember(method, ["MaxLaub", "MinLaub", ...
            "Median", "MinKompost", "SmallestIndex", "KeepHubs"])} = "Median";
        kvargs.Cluster (:, :) double
    end

    if ~isfield(kvargs, "Cluster")
        [~, ~, clusters] = lhp.utils.analyze_s(s);
    else
        clusters = kvargs.Cluster;
    end

    s_new = zeros(numel(problem_data.Garden), 2);
    s_new(:, 1) = 1:numel(problem_data.Garden);

    weighted_adjacency = problem_data.Adjacency;
    % Apply diagonal weights to adjacency matrix
    % Consider the weights for diagonal connections
    % Diagonals are located at:
    %     (-w) - 1
    %     (-w) + 1
    %       w  - 1
    %       w  + 1
    % where w = garden width
    % Get garden width
    width = size(problem_data.Garden, 2);
    n = size(weighted_adjacency, 1);
    % Select fields that must be weighted
    diag_cells = diag(ones(n - width - 1, 1), - width - 1) + ...
                 diag(ones(n - width + 1, 1), - width + 1) + ...
                 diag(ones(n - width + 1, 1), + width - 1) + ...
                 diag(ones(n - width - 1, 1), + width + 1);
    % Unselect fields that don't exist in Adjacency
    diag_cells = diag_cells & weighted_adjacency;
    % Apply the weights
    weighted_adjacency(diag_cells) = problem_data.DiagonalWeight;

    % Betrachte die Cluster
    for tmp_clust = clusters

        % Entferne die Nullen am Ende
        cluster = tmp_clust(tmp_clust > 0);
        gr = graph(weighted_adjacency(cluster, cluster));

        switch (method)
            case "MaxLaub"
                [~, new_hub_idx] = max(problem_data.GMatrix(cluster, 4));
            case "MinLaub"
                [~, new_hub_idx] = min(problem_data.GMatrix(cluster, 4));
            case "Median"
                % We use the cluster-local distance matrix for correctness
                % We weight the distance from each node to each other node using
                % the amount of leaves per cell. We utilize the fact that the
                % distance of a cell to itself is 0: This way, we can easily
                % break the determination of the hub node into simple matrix
                % operations. The GMatrix subset we use is a column vector where
                % each row is the number of leaves of the node in the rows of
                % the distance matrix. The element-wise multiplication applies
                % the row vector of GMatrix to each row of the distance matrix.
                % Thus we must sum in the first dimension (along the rows) to
                % get the correct results.
                [~, new_hub_idx] = min(sum(...
                    gr.distances() .* problem_data.GMatrix(cluster, 4), 1));
            case "MinKompost"
                [~, new_hub_idx] = min(problem_data.DMatrix(...
                    cluster, problem_data.Target));
            case "SmallestIndex"
                new_hub_idx = find(cluster == min(cluster));
            case "KeepHubs"
                new_hub_idx = find(s(cluster,1) == s(cluster,2));
            otherwise
                error("Method %s not implemented!", method);
        end

        for idx = 1:numel(cluster)
            path = gr.shortestpath(new_hub_idx, idx);
            if numel(path) > 1
                s_new(cluster(path(end)), 2) = cluster(path(end-1));
            else
                % Current node is the hub
                s_new(cluster(path(1)), 2) = cluster(path(1));
            end
        end
    end

    s_new(s_new(:, 2) == 0, 2) = -1;
    return;
end
