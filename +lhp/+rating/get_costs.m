function [HA, WA, TA, K] = get_costs(s, pdata, kvargs)
%GET_COSTS Calculate the cost of a solution s.
%
%   Given a valid successorfunction s, this function calculates the total cost
%   of the generated solution. It does not perform sanity checks on whether the
%   solution is valid or not, the user is expected to perform these checks if
%   necessary.
%
%   In order to calculate the cost, the solution must be brought into order such
%   that starting from the starting point, leaves are collected at all
%   designated hubs and transported to the compost.
%
%   The total cost consists of three individual cost factors, whose calculation
%   is described below:
%
%   Cost for raking ("HA")
%       Costs for raking are caused whenever leaves are moved from one cell to
%       another. The costs are calculated according to the following formula:
%
%       .. math:: HA = \lceil \frac{M_{cur} }{ M_{max} } \rceil * \alpha
%
%       Where :math:`M_{cur}` denotes the amount of leaves on the current cell,
%       :math:`M_{max}` denotes the maximum amount of leaves that can be moved
%       when raking once, and :math:`alpha` is the cost of raking.
%       Note that the mentioned method for obtaining raking costs wouldn't
%       consider cases where the solution (successorfunction s) rakes piles of
%       leaves with 0 leaves on them, as the cost would be 0. To compensate for
%       this, all costs for raking are superimposed with the cost for walking.
%       In other words: When raking from one cell to another, the total cost of
%       this "maneuver" is the cost for raking *plus* the cost for walking.
%
%       **Note**: When raking takes place diagonally, the raking cost is
%       multiplied with the "diagonal distance" that was configured by the user!
%
%   Cost for walking ("WA")
%       Costs for walking are caused whenever a movement from one cell to
%       another takes place. This includes ''unproductive'' walking, for example
%       when walking from a hub to the next source to rake leaves from. But it
%       also includes walking while raking, to move from one cell to another
%       while transporting leaves. It **does not** include the cost for
%       transportation (see below).
%
%       The cost for walking is always the distance walked (obtained from the
%       distance matrix which is calculated by Dijkstras algorithm) multiplied
%       with the cost of walking.
%
%   Cost for transport ("TA")
%       Transportation cost accumulates after all raking has been done. Then the
%       gardener walks from the position where they last raked leaves back to
%       the starting position to get a wheelbarrow, which is used to transport
%       the leaves from all hubs to the garden compost.
%       To obtain the actual cost we make some assumptions:
%
%       1. The wheelbarrow is located at the starting position.
%       2. The leaves are transported in "Pendeltouren", which means that
%          starting from the compost, we go to each hub to collect the leaves.
%
%       These assumptions ease the calculation of the transportation cost.
%       However, they do not necessarily agree with the most intuitive way of
%       transporting leaves to the compost, which would be to: (1) Go back to
%       the start to grab the wheelbarrow, (2) go to the nearest hub immediately
%       and transport leaves from that hub to the compost, (3) repeat 2 until
%       all hubs have been handled, (4) go from the compost back to the start to
%       park the wheelbarrow.
%
%       It should be mentioned that this "intuitive" approach causes issues when
%       calculating the cost of transportation, as the walking from the start to
%       the first hub, and the cost of walking from the last hub to the start
%       aren't equal, and thus must be "tracked" with care. We decided against
%       this approach in favor of the "Pendeltouren".
%
%   Parameters
%   ----------
%   s: 2 column vector
%       The successorfunction as provided by any of the algorithms. Must be a
%       valid successorfunction.
%   pdata: lhp.ProblemData
%       The problem description for which s was generated.
%
%   Keyword Arguments
%   -----------------
%   'MaxLeavesViolationAction': {"None", "InfCosts", "Throw"}, default: "Throw"
%       Action to take when the maximum amount of leaves during calculation of
%       the costs surpasses the user-defined maximum of `pdata.Max_Val`. This
%       means that the solution is invalid, as it violates the maximum amount of
%       leaves per cell. This argument allows to define an action to take:
%
%       - "None": Don't do anything at all.
%       - "InfCosts": Set all costs to inf and return immediately.
%       - "Throw": Throw an error and abort function execution.
%
%   Returns
%   -------
%   HA: double
%       "Harkaufwand"
%   WA: double
%       "Unproduktive Wege"
%   TA: double
%       "Transportaufwand"
%   K: double
%       "Gesamtkosten"
%
%   Raises
%   ------
%   LHP:MaxLeavesViolated
%       Raised when during simulation of the raking process the maximum leaves
%       boundary defined in `pdata.Max_Val` is violated **and**
%       `'MaxLeavesViolationAction'` is set to "Throw".
    arguments
        s (:, 2) double {mustBeInteger}
        pdata (1, 1) lhp.ProblemData
        kvargs.MaxLeavesViolationAction (1, 1) string {mustBeMember(...
            kvargs.MaxLeavesViolationAction, ["None", "InfCosts", "Throw"])} ...
            = "Throw";
    end

    done = false;
    max_hark = 1;
    kompost = pdata.Target;
    HA = 0;
    WA = 0;
    [hubs, sources] = lhp.utils.analyze_s(s);

    %% About the cost of raking ("Harkaufwand")
    % We walk through all nodes of a cluster and cum the amount of leaves we
    % push around with us.
    % We have to consider all nodes that:
    %   a) Aren't blocked in any way
    %   b) Aren't sinks
    cond = (s(:, 1) ~= s(:, 2)) & (pdata.GMatrix(:, 4) >= 0);
    candidates = pdata.GMatrix(cond, 3);

    % Get copies of some values that we may mess with
    Gcopy = pdata.GMatrix;
    Scopy = s;

    start = pdata.Start;
    % Find the nearest source
    [dist, goto_ind] = min(pdata.DMatrix(start, sources));
    % Distance to the source is an "Unproduktiver Weg"
    WA = WA + dist * pdata.Unprod_Param;
    a = sources(goto_ind);

    if isempty(sources)
        % This case occurs only when all cells are hubs.
        % In this case: sources are the hubs...
        done = true;
        next = start;
    end
    % Remove node from list of sources
    sources = sources(sources ~= a);

    while ~done
        candidates = candidates(candidates ~= a);

        % Rake from source node to the successor
        next = Scopy(a, 2);
        % Account for moving the leaves, consider diagonal movements (DMatrix)
        HA = HA + ceil(Gcopy(a, 4) / max_hark) * pdata.Rake_Param * pdata.DMatrix(a, next);
        % Account for walking, too!
        WA = WA + pdata.DMatrix(a, next) * pdata.Unprod_Param;
        % Mark field as raked.
        Scopy(a, :) = [0, 0];
        Gcopy(next, 4) = Gcopy(next, 4) + Gcopy(a, 4);
        % Sanity check: Check that the amount of leaves on this cell doesn't
        % surpass the maximum amount of leaves allowed.
        if (Gcopy(next, 4) > pdata.Max_Val)
            switch (kvargs.MaxLeavesViolationAction)
                case "None"
                    % Do nothing.
                case "InfCosts"
                    HA = inf;
                    WA = inf;
                    TA = inf;
                    K = inf;
                    return;
                case "Throw"
                    error("LHP:MaxLeavesViolated", ...
                        "Maximum amount of leaves (%.2f) on cell %d" + ...
                        " violates the configured maximum of %d!", ...
                        Gcopy(next, 4), next, pdata.Max_Val);
                otherwise
                    error("Action '%s' isn't implemented!", ...
                        kvargs.MaxLeavesViolationAction);
            end
        end
        Gcopy(a, 4) = 0;

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
            [dist, goto_ind] = min(pdata.DMatrix(a, sources));
            % Distance to the source is an "Unproduktiver Weg"
            WA = WA + dist * pdata.Unprod_Param;
            a = sources(goto_ind);
            % Remove node from list of sources
            sources = sources(sources ~= a);
        end
    end

    % All the raking costs are handled now. Next we have to deal with the:
    %   1) "Unproduktive Wege"
    %   2) "Transportaufwand"
    %
    % The former exist because we:
    %   - Go from the last visited node to the start to get a wheelbarrow
    %   - Go from the start node to the nearest hub
    %   - Go from the last (most distant) hub back to the start node.
    last_node = next;
    WA = WA + pdata.DMatrix(last_node, start) * pdata.Unprod_Param;
%     WA = WA + min(pdata.DMatrix(start, hubs)) * pdata.Unprod_Param;
%     WA = WA + max(pdata.DMatrix(start, hubs)) * pdata.Unprod_Param;
    WA = WA + 2 * pdata.DMatrix(kompost, start) * pdata.Unprod_Param;
    % Convert WA to double if empty!
    if isempty(WA)
        WA = 0;
    end

    % Calculate costs for transportation.
    % Note: We're dealing with "Pendeltouren", so we have twice the distance.
    TA = sum((ceil(Gcopy(hubs, 4) ./ pdata.Max_Trans)) .* pdata.DMatrix(hubs, kompost)) ...
        * 2 * pdata.Trans_Param;

    % Calculate total cost ("Gesamtkosten")
    K = TA + WA + HA;
end

