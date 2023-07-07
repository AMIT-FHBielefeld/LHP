function s = skip_zero_hubs(pdata, s)
    %% Skip all zero-hubs in a solution.
    %
    %   This function takes a successorfunction `s` and determines which cells
    %   in this solution never have any leaves on them (Either in the garden or
    %   during raking).
    %   If cells are found that never contain leaves, they are turned into hubs
    %   (i.e. clusters with one cell that don't contain leaves) and ignored in
    %   any following processing steps.
    %
    %   Arguments
    %   ---------
    %   pdata: lhp.ProblemData
    %       The problem for which `s` was generated.
    %   s: 2-column matrix of double
    %       A valid successorfunction.
    %
    %   Returns
    %   -------
    %   s: 2-column matrix of double
    %       A modified successorfunctions that doesn't include isolated cells
    %       with zero leaves in the solution.

    done = false;
    handled = (s(:, 2) < 0);

    while ~done
        % We start at the sources. We only consider those nodes that we haven't
        % handled before as valid source. This is mostly a measure to save time
        % as setdiff is considered an expensive function in terms of processing
        % time. The variable `handled` keeps track of which nodes we visited, as
        % these won't become sources again (and thus needn't be checked).
        sources = setdiff(s((s(:, 2) >= 0) & ~handled, 1), s(:, 2));

        % Check the amount of leaves on these cells
        no_leaves = (pdata.GMatrix(sources, 4) == 0);
        no_leave_nodes = sources(no_leaves);

        % No nodes left, exit
        if isempty(no_leave_nodes)
            break;
        end

        % Make these a hub
        s(no_leave_nodes, 2) = s(no_leave_nodes, 1);
        handled(no_leave_nodes) = true;
    end
end

