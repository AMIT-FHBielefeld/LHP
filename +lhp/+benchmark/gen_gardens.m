%% Generate gardens for benchmarking.
%
%   Generates a set of gardens that shall be used for benchmarking in the
%   project. The gardens generated here explicitly have uniformly distributed
%   foliage!
function [regular, exotic] = gen_gardens()
    close("all");

    regular_garden_sizes = [13, 13; ...
                            18, 18; ...
                            25, 25; ...
                            35, 35; ...
                            50, 50; ...
                            70, 70; ...
                            100, 100];
    exotic_garden_sizes = [ 35, 35; ...
                            25, 49; ...
                            7, 175; ...
                            5, 245];
    tree_densities = [0.05; 0.15];
    foliages = ["GaussAroundTrees"; "Uniform1-5"; "Uniform1-10"];

    mkarg = @(name, fmt, value) struct("name", name, "format", fmt, "value", value);

    regular_gardens = [...
        mkarg("garden_size", "%dx%d", regular_garden_sizes), ...
        mkarg("tree_density", "%5.4f", tree_densities), ...
        mkarg("foliage", "%s", foliages) ...
        ];

    exotic_gardens = [...
        mkarg("garden_size", "%dx%d", exotic_garden_sizes), ...
        mkarg("tree_density", "%5.4f", tree_densities), ...
        mkarg("foliage", "%s", foliages) ...
        ];


    out_folder = "garden_figs";
    [success, warn] = mkdir(out_folder);
    if ~success
        error(warn);
    end

    pool = gcp();
    cleanObj = onCleanup(@()cleanUpGCP(pool));

    %% Generate regular gardens
    regular = par_make_gardens("regular", regular_gardens);

    %% Generate exotic gardens: Deformed subtype
    exotic = par_make_gardens("exotic", exotic_gardens);
end


function tb = par_make_gardens(~, args)
    tb = table();

    for aidx = 1:numel(args)
        arg = args(aidx);
        newtb = table();

        for nidx = 1:size(arg.value, 1)
            % Check if there are other columns than ours
            % In this case we copy them into the newtb with
            if any(cellfun(@(str) ~isequal(str, arg.name), tb.Properties.VariableNames))
                for tr_idx = 1:size(tb, 1)
                    cur_row = tb(tr_idx, :);
                    cur_row.(arg.name) = sprintf(arg.format, arg.value(nidx, :));
                    newtb = cat(1, newtb, cur_row);
                end
            else
                newtb.(arg.name)(nidx) = sprintf(arg.format, arg.value(nidx, :));
            end
        end

        tb = newtb;
    end

    % Table columns are sorted in the order given below. When extending this,
    % please always ensure that "tree_density" is the last element such that the
    % garden generation doesn't break. In its initial state equal gardens with
    % different tree densities were generated starting with each other to ensure
    % that the first trees places are always present in the same locations and
    % don't move around as the tree density increases.
    column_sort_order = ["garden_size", "foliage", "tree_density"];
    column_sort_indexes = arrayfun(@(seek) find([args.name] == seek), ...
        column_sort_order);
    % Eliminate duplicate rows
    tb = unique(tb, 'rows');
    tb = sortrows(tb, column_sort_indexes);
    % Add some indexes
    tb.index = (1:size(tb, 1))';
    % Placeholders for garden cells
    tb.garden = repmat({0}, size(tb, 1), 1);

    % Get all gardens that differ only in "tree_density" to subsequently
    % generate these on top of each other, but only if the foliage types match
    % exactly!
    tbrows = size(tb, 1);
    equality = zeros(tbrows, tbrows);
    for cmp_idx = 1:tbrows
        for with_idx = cmp_idx:tbrows
            equality(cmp_idx, with_idx) = ...
                (tb.garden_size(cmp_idx) == tb.garden_size(with_idx));
        end
    end
    equality = equality + equality';

    % Go through the matrix, identify groups of equal gardens differing only in
    % the tree density
    clusters = {};
    eq_row = size(equality, 1);
    while ~isempty(equality)
        similar = find(equality(eq_row, :));
        % Sort these with their foliage ascending
        % Actually they already are. ;)

        clusters = cat(1, clusters, similar);
        % Remove these from the equality matrix
        equality(similar, :) = [];
        equality(:, similar) = [];
        % Adapt eq_row
        eq_row = eq_row - numel(similar);
    end

    futures = parallel.FevalFuture.empty(numel(clusters), 0);
    % Dispatch workers
    for c_idx = 1:numel(clusters)
        futures(c_idx) = parfeval(@make_gardens, 1, tb(clusters{c_idx}, :));
    end

    % Setup progress bar
    progbar = lhp.utils.ProgressBar(...
        "WindowWidth", 80, ...
        "BarStyle", "=", ...
        "WidestNumber", 3, ...
        "UpdateString", "Generating gardens", ...
        "UpdateEvery", 0.02, ...
        "MaxValue", numel(futures));
    progbarFutures = afterEach(futures, @(~) progbar.increment(), 0);
    fprintf("\n");
    progbar.init();

    % Collect worker results
    while ~all([futures.Read])
        [jobIdx, result] = fetchNext(futures);
        tb(result.index, :) = result;
    end
end

function gtable = make_gardens(gtable)
    %   Arguments
    %   ---------
    %   gs: gtable: Table with garden parameters to generate
    %
    %   Returns
    %   -------
    %   garden: The generated garden
    gs_str = regexp(gtable.garden_size(1), "(\d+)x(\d+)", "tokens");
    gs = arrayfun(@(str) str2double(str), gs_str{1});
    tds = unique(gtable.tree_density);

    G = lhp.Garden.random(gs(1), gs(2), ...
        "ShedSize", [4, 4], ...
        "LeavesDistributionType", gtable.foliage(1));

    num_free = nnz(G >= 0);
    trees_added = 0;

    for td_idx = 1:numel(tds)
        td_rows = find(gtable.tree_density == tds(td_idx));
        % Current tree density as number
        td = str2double(tds(td_idx));

        for fp_idx = td_rows'
            folpat = gtable.foliage(fp_idx);
            trees_to_add = ceil(num_free * td) - trees_added;

            if startsWith(folpat, "Uniform")
                % If we previously created a garden with gaussian foliage
                % patterns, we reuse that by stripping all leaves and only
                % creating a fresh foliage pattern.
                if startsWith(gtable.foliage(td_rows(1)), "Gauss")
                    Grep = replace_foliage(gtable.garden{td_rows(1)}, folpat);
                    % We must add the garden to the matrix here because if we
                    % overwrite 'G', additional trees will be added to the
                    % *wrong* garden!
                    gtable.garden(fp_idx) = {Grep};
                    continue;
                else
                    G = G.add_tree(trees_to_add, "NoLeaves", true);
                end
            elseif startsWith(folpat, "Gauss")
                G = G.add_tree(trees_to_add);
            else
                error("Unknown foliage pattern %s", folpat);
            end

            gtable.garden(fp_idx) = {G};
            trees_added = trees_added + trees_to_add;
        end
    end

    function G = replace_foliage(garden, pattern)
        blocked = (garden.Raw < 0);

        % Create a new, completely empty garden
        G = lhp.Garden.random(size(garden, 1), size(garden, 2), ...
            "TreeDensity", 0, ...
            "WithShed", false, ...
            "ShedSize", [1, 1], ...
            "WithCompost", false, ...
            "LeavesDistributionType", pattern, ...
            "Export", false);

        % Add the blocked fields from before back in
        G.Raw(blocked) = garden.Raw(blocked);
    end
end

function cleanUpGCP(parpool)
    % Kill all remaining workers.
    if numel(parpool.FevalQueue.QueuedFutures) > 0
        fprintf("Killing all queued workers...");
        cancel(parpool.FevalQueue.QueuedFutures);
        fprintf(" DONE!\n");
    end

    if numel(parpool.FevalQueue.RunningFutures) > 0
        fprintf("Killing all running workers...");
        cancel(parpool.FevalQueue.RunningFutures);
        fprintf(" DONE!\n");
    end
end
