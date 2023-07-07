function [ax, cluster] = cluster_plot(pdata, s, ax, kvargs)
    %% Make a plot of all clusters of a solution s.
    %
    %   This function takes a solution (successor-function) `s`, along with the
    %   respective problem description `pdata`. From this data it creates a
    %   visualization of the solution, which includes coloring the individual
    %   node clusters, drawing arrows that show the raking along with the
    %   order in which the fields are raked (optional).
    %
    %   Fields that have 0 leaves on them and don't belong to any cluster (i.e.
    %   they're their own cluster) are ignored and thus won't be colored.
    %
    %   Arguments
    %   ---------
    %   pdata: lhp.ProblemData
    %       The problem for which `s` was created.
    %   s: 2-column vector of double
    %       A valid successorfunction that fits the Problem (`pdata`).
    %   ax: matlab.graphics.axis.Axes
    %       A figure axes to draw the plot to. All previous contents on the axes
    %       are cleared before drawing this plot.
    %
    %   Keyword Arguments
    %   -----------------
    %   'ShowOrder': logical, default: false
    %       If set to true, adds a number (as italic text) to every cell that
    %       leaves are raked *from*. These numbers signal the order in which all
    %       raking takes place. This means that raking starts after walking to
    %       the field marked as "1", continues at "2", etc. Fields are traversed
    %       strictly in order!
    %   'ShowFinalSizes': logical, default: false
    %       If set to true, displays the final amount of leaves of a given
    %       cluster in its hub (as bold text).
    %
    %   Returns
    %   -------
    %   ax: axis handle
    %       A handle to the axis that was used.
    %   cluster: array of struct
    %       An array of structs, where each struct contains additional
    %       information about the clusters in the garden. The clusters fields
    %       are:
    %
    %       - 'nodes': The nodes that are part of this cluster.
    %       - 'neighbors': The numbers of clusters that are adjacent
    %         (horizontally, vertically, or diagonally) to this cluster. For
    %         reasons of computation, all clusters are considered neighbors of
    %         themselves.
    %       - 'color': The color that this cluster has been given.
    arguments
        pdata (1, 1) lhp.ProblemData
        s (:, 2) double {mustBeInteger}
        ax (1, 1) matlab.graphics.axis.Axes = axes();
        kvargs.ShowOrder (1, 1) logical = false;
        kvargs.ShowFinalSizes (1, 1) logical = false;
    end

    %% Start!

    % Prepare the plots
    cla(ax);
    % Switch plot coordinate system to matrix view/style
    axis(ax, "ij");
    hold(ax, "on");
    % Fix spacing around the plot
    xlim(ax, [0.5, size(pdata.Garden, 1) + 0.5]);
    ylim(ax, [0.5, size(pdata.Garden, 2) + 0.5]);

    % Get the directions of the raking processes from s
    % Discard all rows containing blocked cells
    non_blocked = (s(:, 2) >= 0);
    new_s = s(non_blocked, :);
    % Indexes of the non-blocked fields
    non_blocked_indexes = find(non_blocked);

    % Convert to coordinates, (ROW, COLUMN)
    start_coords = [floor((new_s(:, 1) - 1) ./ pdata.Garden.size(2)) + 1, ...
                    mod(new_s(:, 1) - 1, pdata.Garden.size(2)) + 1];
    target_coords = [floor((new_s(:, 2) - 1) ./ pdata.Garden.size(2)) + 1, ...
                     mod(new_s(:, 2) - 1, pdata.Garden.size(2)) + 1];

    coord_diffs = (target_coords - start_coords);

    % Convert coordinates differences directly to Quiver positions
    quiver_directions = [coord_diffs(:, 2), coord_diffs(:, 1)];


    %% Plot blocked garden cells
    %
    % We get all special cells that this garden has, and plot them one by one,
    % as specified there. We recognize special cells as properties of the
    % `pdata.Garden` object whose fieldnames begin with 'CELL_' (i.e. they match
    % the regex '^CELL_'). At the time of writing this includes trees, the
    % garden shed and the compost. This interface allows it to be seamlessly
    % extended to other fields.
    cell_names = fieldnames(pdata.Garden);

    cand = regexp(cell_names, '^CELL_');
    special_fields = string(cell_names(~cellfun(@isempty, cand)));

    for sf = special_fields'
        field_type = lhp.Garden.(sf);

        % Get field coordinates
        field_coords = pdata.GMatrix((pdata.Garden' == field_type.value), 1:2);

        % Draw colored patches for coordinates
        % Get the color to draw the patch in from the respective pdata.Garden
        % property
        for fc = field_coords'
            x_corners = [fc(1) + 0.5; fc(1) + 0.5; fc(1) - 0.5; fc(1) - 0.5];
            y_corners = [fc(2) + 0.5; fc(2) - 0.5; fc(2) - 0.5; fc(2) + 0.5];
            patch(ax, y_corners, x_corners, field_type.color, ...
                "FaceAlpha", 0.8);
        end

        % Write text into patches
        field_name_char = char(field_type.description);
        text(ax, field_coords(:, 2), field_coords(:, 1), field_name_char(1), ...
            "HorizontalAlignment", "center", "FontWeight", "bold");
    end

    % Get meta-information
    [hubs, ~, clusters] = lhp.utils.analyze_s(s);


    %% ------------------------------------------------------------------------
    % Determine the colors for the clusters.
    % This also determines how many colors are needed to color the cluster
    % properly.
    [cluster, num_colors] = colorize_clusters(pdata, clusters);

    % Make the plots
    for c_idx = 1:numel(cluster)
        cluster(c_idx).color = hsv2rgb([cluster(c_idx).color / num_colors, 1, 1]);

        node_indices = false(size(s, 1), 1);
        node_indices(cluster(c_idx).nodes) = true;
        node_indices(~non_blocked) = [];

        % Skip over clusters with only one node that don't contain leaves
        if numel(cluster(c_idx).nodes) == 1
            if pdata.GMatrix(cluster(c_idx).nodes, 4) == 0
                continue;
            end
        end

        [fields, lines] = get_cluster_outline(flip(start_coords(node_indices, :), 2));

        line(ax, [lines(:, 1), lines(:, 3)]', [lines(:, 2), lines(:, 4)]', ...
            "Color", "black", ...
            "LineWidth", 2);

        for field = fields'
            patch(ax, 'Faces', [1, 2, 3, 4], ...
                'Vertices', reshape(field, 2, [])', ...
                "LineStyle", "none", ...
                "FaceColor", cluster(c_idx).color, ...
                "FaceAlpha", 0.6);
        end

        if kvargs.ShowFinalSizes
            cluster_hub = (hubs(c_idx) == non_blocked_indexes);
            leaves = sum(pdata.GMatrix(cluster(c_idx).nodes, 4));
            text(ax, start_coords(cluster_hub, 2), ...
                start_coords(cluster_hub, 1), ...
                num2str(leaves), ...
                "HorizontalAlignment", "center", ...
                "FontWeight", "bold", ...
                "FontSize", 12);
        end
    end

    if kvargs.ShowOrder
        order = get_raking_order(s, pdata);
        order = order(non_blocked);
        sel = (order > 0);

        text(ax, start_coords(sel, 2), start_coords(sel, 1), ...
            num2str(order(sel)), ...
            "HorizontalAlignment", "center", ...
            "FontAngle", "italic", ...
            "FontSize", 8);
    end

    % Plot the quivers last so they're on top of the plot!
    quiver(ax, start_coords(:, 2), ...
        start_coords(:, 1), ...
        quiver_directions(:, 1), ...
        quiver_directions(:, 2), ...
        0.7, ...
        "Color", "black", ...
        "LineWidth", 2.0, ...
        "MaxHeadSize", 1.0, ...
        "AutoScale", "off");

    return;
end


function [fields, lines] = get_cluster_outline(node_coords)
    %% Obtain information for "painting" the clusters.
    %
    %   This function extracts the corner coordinates of each node in a cluster
    %   as well as all edges that mark the circumference (the cluster
    %   boundary/border).
    %
    %   Parameters
    %   ----------
    %   node_coords: 2-column vector of double
    %       Coordinates of the nodes in the cluster to inspect, given as a
    %       vector of [x, y] coordinates.
    %
    %   Returns
    %   -------
    %   fields: m x 8 matrix of double
    %       A matrix with 8 columns and as many rows as there are in
    %       `node_coords`. This matrix contains the coordinates of the corners
    %       of each of the nodes that are given to this function, in the same
    %       order as the input nodes were. The coordinates in one row describe
    %       the border of the cell, starting from the bottom-left corner,
    %       walking clockwise around the cell.
    %       One row contains the coordinates as [x, y, x, y, x, y, x, y] of each
    %       of the four corners.
    %   lines: n x 4 matrix of double
    %       A matrix with 4 columns where each row demarks an edge of the border
    %       of the given cluster. Coordinates are organized as [x, y, x, y]. The
    %       edges aren't in any particular order. To obtain the graphical
    %       boundary of the cluster, it is advised to plot the edges one-by-one.

    % Holds all edges known so far
    edge_matrix = zeros(4, size(node_coords, 1) * 4);
    em_ctr = 1;

    % Calculate all node corners coordinates
    DISTANCE = 0.5;
    fields = [...
        node_coords + [-DISTANCE, -DISTANCE], ...
        node_coords + [ DISTANCE, -DISTANCE], ...
        node_coords + [ DISTANCE,  DISTANCE], ...
        node_coords + [-DISTANCE,  DISTANCE], ...
    ];

    for field = fields'

        edges = [...
            [field(7:8); field(5:6)], ... % Top-left to Top-right
            [field(1:2); field(3:4)], ... % Bottom-left to Bottom-right
            [field(7:8); field(1:2)], ... % Top-left to Bottom-left
            [field(5:6); field(3:4)], ... % Top-right to Bottom-right
        ];
        for edge = edges
            select = ((edge_matrix(1, :) == edge(1)) & ...
                      (edge_matrix(2, :) == edge(2)) & ...
                      (edge_matrix(3, :) == edge(3)) & ...
                      (edge_matrix(4, :) == edge(4)));
%             select = all(bsxfun(@eq, edge_matrix, edge), 1);

            if any(select)
                % Edge detected twice, remove it
                edge_matrix(:, select) = [];
                em_ctr = em_ctr - 1;
            else
                % Unknown edge, add it
                edge_matrix(:, em_ctr) = edge;
                em_ctr = em_ctr + 1;
            end
        end
    end

    lines = edge_matrix(:, 1:(em_ctr - 1))';
end

function [cluster, num_colors] = colorize_clusters(pdata, clusters)
    %% Assigns colors to all clusters.
    %
    %   Fulfilling the constraint that adjacent clusters never have the same
    %   color. This function also determines the number of colors needed to do
    %   this using a simple heuristic. It doesn't guarantee to find the absolute
    %   minimum number of colors required!
    %
    %   Parameters
    %   ----------
    %   pdata: lhp.ProblemData
    %       The problem that `clusters` originates from. This is needed for the
    %       adjacency matrix.
    %   clusters: matrix of double
    %       A matrix where each column contains the nodes of a cluster. Values
    %       of 0 are ignored.
    %
    %   Returns
    %   -------
    %   cluster: vector of struct
    %       A representation of the input `clusters` in a struct form. Each
    %       struct in the array corresponds to one cluster, with the following
    %       fields:
    %
    %       - 'nodes': Nodes in this cluster
    %       - 'neighbors': Indices of clusters that are neighbors of this
    %         cluster
    %       - 'color': An index (between 1 and `num_colors`) that corresponds to
    %         one color. Can be translated to a real color with hsv2rgb, for
    %         example, to spread the colors evenly on the color wheel.

    % Start with a single color, and increase the number by one every time we
    % see that the number of available colors isn't enough.
    num_clusters = size(clusters, 2);
    cluster = repmat(struct(...
        "nodes", [], "neighbors", [], "color", []), num_clusters, 1);

    % Iterate over all nodes, get the cluster of the current node, get that
    % nodes neighbors, determine their clusters and build the lists this way
    handled_nodes = zeros(numel(pdata.Garden), 1);

    for node = 1:numel(pdata.Garden)
        handled_nodes(node) = 1;
        if pdata.GMatrix(node, 4) < 0
            % Blocked cell, ignore
            continue;
        end
        % Get cluster of current node
        cur_node_cidx = find(any(node == clusters, 1));
        if ~any(cur_node_cidx == cluster(cur_node_cidx).neighbors)
            cluster(cur_node_cidx).neighbors = [...
                    cluster(cur_node_cidx).neighbors, cur_node_cidx];
        end

        % Iterate over cluster neighbors
        for node_neighbors = find(pdata.Adjacency(:, node) & ~handled_nodes)'
            nbr_node_cidx = find(any(node_neighbors == clusters, 1));

            if any(nbr_node_cidx == cluster(cur_node_cidx).neighbors)
                % Already marked as neighbor of this cluster
                continue;
            else
                % Add neighbor to cluster of current node
                if ~any(nbr_node_cidx == cluster(cur_node_cidx).neighbors)
                    cluster(cur_node_cidx).neighbors = [...
                        cluster(cur_node_cidx).neighbors, nbr_node_cidx];
                end
                % Also add current nodes cluster to the cluster of the neighbor
                if ~any(cur_node_cidx == cluster(nbr_node_cidx).neighbors)
                    cluster(nbr_node_cidx).neighbors = [...
                        cluster(nbr_node_cidx).neighbors, cur_node_cidx];
                end

            end
        end
    end

    num_colors = 1;

    for c_idx = 1:numel(cluster)
        % Fill in some metadata while we're iterating over the clusters.
        cluster(c_idx).nodes = nonzeros(clusters(:, c_idx));
        cur_cluster = cluster(c_idx);

        if isempty(cur_cluster.color)
            color_candidates = 1:num_colors;
            for cluster_neighbors = cur_cluster.neighbors
                if isempty(cluster(cluster_neighbors).color)
                    continue;
                else
                    color_candidates(...
                        color_candidates == cluster(cluster_neighbors).color) = [];
                end
            end

            if isempty(color_candidates)
                % Need another color!
                num_colors = num_colors + 1;
                cluster(c_idx).color = num_colors;
            else
                % Take the first of all colors that are left.
%                 cluster(c_idx).color = color_candidates(1);
                % Take some random color out of all colors left.
                cluster(c_idx).color = color_candidates(randsample(length(color_candidates), 1));
            end
        end
    end

    return;
end

function order = get_raking_order(s, pdata)
    %% Get the order in which nodes are traversed
    %
    %   Taken from `lhp.rating.get_costs`.
    done = false;
    [~, sources] = lhp.utils.analyze_s(s);

    % We have to consider all nodes that:
    %   a) Aren't blocked in any way
    %   b) Aren't sinks
    cond = (s(:, 1) ~= s(:, 2)) & (pdata.GMatrix(:, 4) >= 0);
    candidates = pdata.GMatrix(cond, 3);

    order = zeros(numel(cond), 1);
    o_idx = 1;

    % Get copies of some values that we may mess with
    Scopy = s;

    start = pdata.Start;
    % Find the nearest source
    [~, goto_ind] = min(pdata.DMatrix(start, sources));
    a = sources(goto_ind);

%     order(o_idx) = a;
    order(a) = o_idx;
    o_idx = o_idx + 1;

    if isempty(sources)
        % This case occurs only when all cells are hubs.
        % In this case: sources are the hubs...
        done = true;
    end
    % Remove node from list of sources
    sources = sources(sources ~= a);

    while ~done
        candidates = candidates(candidates ~= a);

        % Rake from source node to the successor
        next = Scopy(a, 2);
        % Mark field as raked.
        Scopy(a, :) = [0, 0];

        % All candidates were handled.
        if ~any(Scopy(cond))
            break;
        end

        a = next;
        % If no other cell points to this field, we may consider this field a
        % "source". Thus, there will be no other source more close to this one.
        % In that case, start the loop again.
        if any(Scopy(:, 2) == next)
            % Find the nearest source
            [~, goto_ind] = min(pdata.DMatrix(a, sources));
            a = sources(goto_ind);
            % Remove node from list of sources
            sources = sources(sources ~= a);
        end

        % Mark next field in the order
%         order(o_idx) = a;
        order(a) = o_idx;
        o_idx = o_idx + 1;
    end
end
