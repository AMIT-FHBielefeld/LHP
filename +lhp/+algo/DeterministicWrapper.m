classdef DeterministicWrapper < lhp.algo.BaseWrapper
    %DeterministicWrapper Wrapper to manage deterministic algorithms for LHP.
    %
    %   As a childclass of `BaseWrapper`, this class spezializes on managing
    %   deterministic algorithms for solving the "Laubharkproblem".

    properties (GetAccess=public, SetAccess=public)
        % The Key-Value arguments passed to the constructor.
        OptimizeMaxLaub
        RemoveEmptyNodes
    end

    methods (Access=public)
        function self = DeterministicWrapper(algorithm_handle, algorithm_name, ...
                bdargs, kvargs)
            %% Construct an instance of this class
            %
            %   Upon creation, the internal data storages are all empty. The
            %   object is associated with the given function handle for it's
            %   entire lifetime.
            %   It is not possible to "switch" algorithms later on.
            %
            %   Parameters
            %   ----------
            %   algorithm_handle: function_handle
            %       A function handle of the algorithm that is associated with
            %       this data class. Note that the handle should **NOT** include
            %       parameters to be passed to the function. This is handled in
            %       the get_new_data method.
            %       The algorithm **MUST** return exactly one
            %       successfunction-vector. *NOTHING ELSE!*
            %   algorithm_name: string
            %       The display name of the algorithm. This is used as Table
            %       Column descriptor and for plot legends. Name mustn't contain
            %       spaces!
            %
            %   Keyword Arguments
            %   -----------------
            %   'OptimizeMaxLaub': logical, default: false
            %       If set to true, the heruistic algorithm will determine a
            %       problem-specific 'MaxLaub' parameter within the interval
            %       [1, ProblemData.MaxLaub] that yields the lowest cost for
            %       this specific problem. The MaxLaub that was chosen will be
            %       stored in the results structures, too.
            %   'RemoveEmptyNodes': logical, default: false
            %       If set to true, the successorfunction (i.e. solution) of any
            %       deterministic heuristic will be cleansed of cells that never
            %       carry any leaves on them. This applies only to cells that do
            %       not have leaves on them in the garden itself and which do
            %       not have any leaves of neighboring cells raked onto them.
            %       Any such cells are eliminated from the successor function by
            %       setting them to be clusters of size 1 (which are empty).
            %       These are then neither raked to, nor visited in any other
            %       way.
            %   PLACEHOLDER:
            %       For additional Key-Value Parameters, check the
            %       `BaseWrapper` class.
            %
            %   Notes
            %   -----
            %   To obtain a function handle, simply prepend the functions name
            %   with an @ sign.
            %   For example, to retrieve a function handle for the "dir"
            %   command:
            %
            %       f_handle = @dir
            %
            arguments
                algorithm_handle (1, 1) function_handle
                algorithm_name (1, 1) string
                bdargs.?lhp.algo.BaseWrapper
                kvargs.OptimizeMaxLaub (1, 1) logical = false;
                kvargs.RemoveEmptyNodes (1, 1) logical = false;
            end

            bdargs_cell = namedargs2cell(bdargs);
            self@lhp.algo.BaseWrapper(...
                algorithm_handle, algorithm_name, bdargs_cell{:});

            self.OptimizeMaxLaub = kvargs.OptimizeMaxLaub;
            self.RemoveEmptyNodes = kvargs.RemoveEmptyNodes;
        end
    end

    methods (Access=protected)
        function make_plot(self, canvas, what)
            arguments
                self (1, 1) lhp.algo.BaseWrapper
                canvas (1, 1) matlab.graphics.axis.Axes
                what (1, 1) string {mustBeMember(what, ["Kosten", "Harkarbeit", ...
                    "Wegearbeit", "Transportarbeit", "Zeit"])}
            end

            % Since we sort the table by a running index, we must make sure the
            % x-data is in the right order!
            [xdata, idx_sorted] = sort(self.get(0, "AnzElem"), 'ascend');
            ydata = self.get(0, what);
            ydata = ydata(idx_sorted);

            plot(canvas, xdata, ydata, "--*", ...
                "DisplayName", self.get_name("Latex"));
        end

        function results = get_new_results(self, pdata, fargs)
            %% Execute the algorithm and store given results
            %
            %   This functions performs the computations for a given
            %   deterministic heuristic. It's behaviour can be modified with
            %   some constructor parameters (e.g. to activate
            %   post-optimizations).
            %
            %   During the algorithm execution, the executions times are
            %   measured, too. Time is taken using the `cputime()` function to
            %   achieve accurate results. Regular time measurements with tic and
            %   toc aren't a sensible option here, as they do not account for
            %   scheduling on heavily loaded systems. cputime accurately
            %   measures the time the algorithms spent executing (and **not**
            %   waiting for the scheduler to pick them up again).
            %   The actual time recorded as part of the results structure is
            %   given in seconds and includes the time spent calculating up to
            %   the point where this specific result was recorded. I.e. it
            %   **does not** describe the time it would take if the calculation
            %   was performed with the ''best'' parameters directly.
            %
            %   Parameters
            %   ----------
            %   self: lhp.algo.DeterministicWrapper
            %       An instance of this class.
            %   pdata: ProblemData
            %       A definition of the problem that is to be solved
            %   fargs:
            %       An arbitrary argument list that is passed to the algorithm
            %       to be executed.
            %
            %   Returns
            %   -------
            %   results: struct
            %       A structure with the results. It has the following mandatory
            %       fields:
            %
            %       - 'K': Total cost of the best found solution
            %       - 'HA': Cost of raking
            %       - 'TA': Cost of transportation
            %       - 'WA': Cost of (unproductive) walking
            %       - 'time': Time spent executing the algorithm in seconds. See
            %         above for more details
            %       - 's': The generated successorfunction for the best result
            %
            %       Other, optional fields:
            %
            %       - 'post_opt': Only present if the 'PostOptimize' variable is
            %         set on the object. Contains a string which is a parameter
            %         to the `lhp.utils.hz` method that produced this optimal
            %         result. A value of "none" means that the `hz` function
            %         didn't yield improvements.
            %       - 'optMaxLaub': Only present if the 'OptimizeMaxLaub'
            %         variable is set on the object. Contains the numeric value
            %         of "MaxLaub" for which this algorithm produces the best
            %         result on the problem described by 'pdata'.
            %
            %   Notes
            %   -----
            %   *For developers only*: The internal optimization loop works with
            %   a 'tmp_result' structure that is entirely recreated whenever an
            %   algorithm produced a better solution. This is intentional and
            %   mustn't be changed!
            %   If only the central 'results' structure were used and we
            %   overwrite e.g. values of 'post_opt' in *any* loop, we would have
            %   to pay attention to reset/eliminate this field if in a later
            %   iteration we find a solution that's better but e.g. doesn't need
            %   any post optimization routines.
            %   To avoid this issue of having old values in struct fields that
            %   may not belong to the current solution, 'tmp_result' is used to
            %   find the best solution of a run (**and always entirely
            %   recreated!**) and at the end of the iteration is compared to the
            %   'results' structure.
            arguments
                self (1, 1) lhp.algo.DeterministicWrapper
                pdata (1, 1) lhp.ProblemData
                fargs (1, :) cell = {};
            end

            time_taken = 0;
            iter_end = 1;
            if self.OptimizeMaxLaub == true
                iter_end = pdata.Max_Val;
            end

            results = struct("K", inf);

            for myMaxLaub = 1:iter_end
                if self.OptimizeMaxLaub == true
                    pdata.Max_Val = myMaxLaub;
                end

                tStart = cputime();
                s = self.algorithm(pdata, fargs{:});
                if self.RemoveEmptyNodes
                    s = lhp.utils.skip_zero_hubs(pdata, s);
                end
                time_taken = time_taken + (cputime() - tStart);

                [HA, WA, TA, K] = lhp.rating.get_costs(s, pdata);

                % Store preliminary results. If any of the post-optimizations
                % improves over this, they overwrite it.
                tmp_result = struct(...
                    "K", K, ...
                    "HA", HA, ...
                    "WA", WA, ...
                    "TA", TA, ...
                    "time", time_taken, ...
                    "s", s);

                % Do this only if post-optimization is activated
                % If it isn't, nothing changes here.
                if ~isempty(self.PostOptimize)
                    % Iterate over all configured post-optimization strategies
                    for po_strat = self.PostOptimize
                        % Get the post-optimized successor function
                        t_hz = cputime();
                        s_new = lhp.utils.hz(pdata, s, po_strat);
                        time_taken = time_taken + (cputime() - t_hz);
                        % Calculate all new costs.
                        % Store the costs in new, temporary variables so we
                        % don't overwrite the original costs calculated above
                        % (because after all, the result here may be worse)
                        [HA_po, WA_po, TA_po, K_po] = lhp.rating.get_costs(...
                            s_new, pdata);
                        % Check if we surpassed the previous minimal cost
                        if (K_po < tmp_result.K)
                            tmp_result = struct(...
                                "K", K_po, ...
                                "HA", HA_po, ...
                                "WA", WA_po, ...
                                "TA", TA_po, ...
                                "time", time_taken, ...
                                "s", s_new, ...
                                "post_opt", po_strat);
                        else
                            % No improvement achieved, continue
                            continue;
                        end
                    end

                    if ~isfield(tmp_result, "post_opt")
                        % HZ didn't improve results, so record it as such, too.
                        tmp_result.post_opt = "none";
                    end
                end

                if self.OptimizeMaxLaub
                    tmp_result.optMaxLaub = myMaxLaub;
                end

                % Record it if we achieved an improvement!
                if (tmp_result.K < results.K)
                    results = tmp_result;
                end
            end
            % Restore the Max_Val just in case pdata is a handle that is used
            % by multiple algorithms...
            pdata.Max_Val = iter_end;
            return;
        end

        function strmat = get_disp_info(self)
            %% Get additional info to print upon disp()
            %
            %   Returns
            %   -------
            %   A matrix of size n x 2, where each entry in the first column
            %   will be printed before a colon, after which the second entry is
            %   printed.
            strmat = [...
                "   Optimizing Max Laub", string(self.OptimizeMaxLaub)];
        end

    end

    methods (Static)
        function hdarray = gather(hdargs, kvargs)
            %% Gather a bunch of heuristic algorithms for execution.
            %
            %   This is a convenience function that is meant to ease the
            %   instantiation of `DeterministicWrapper` class instances for the
            %   user. It automatcially reads the file
            %   "lhp.algo.deterministic.algorithms.txt" and, based on the user
            %   input, create one or more instances of the
            %   `DeterministicWrapper` class that is return as array.
            %   The format of the file is described in the file itself. Note
            %   that this function can only instantiate algorithms that are
            %   explicitly listed in the aforementioned file. If you add new
            %   algorithms and want to "spawn" them through this interface, add
            %   them to the file as described there.
            %
            %   The purpose of this function is to make the instantiatino of
            %   large amounts of `DeterministicWrapper` for tests easier for the
            %   user.
            %
            %   Keyword Arguments
            %   -----------------
            %   See `DeterministicWrapper` constructor
            %       This function accepts Key-Value parameters that are valid
            %       for the `DeterministicWrapper` constructor. These parameters
            %       are passed to all instances of `DeterministicWrapper` that
            %       are created.
            %       **NOTE**: Constructor Parameters to the class instances must
            %       be the first arguments!
            %   'Range': double
            %       A scalar or array of IDs (Refer to "algorithms.txt") that
            %       selects specific deterministic algorithms to instantiate.
            %       Leave empty (i.e. don't specify as argument) to select all
            %       algorithms.
            %   'NameSuffix': string, default: ""
            %       A suffix to append to all algorithm names from the files.
            %       Can be used to distinguish between equal heuristics that use
            %       different constructor parameters.
            %
            %   Returns
            %   -------
            %   hdarray: Array of `DeterministicWrapper`
            %       An array of the instantiated algorithms.
            arguments
                hdargs.?lhp.algo.DeterministicWrapper
                kvargs.Range (1, :) double {mustBePositive, mustBeInteger}
                kvargs.NameSuffix (1, 1) string = "";
            end
            filepath = erase(mfilename("fullpath"), "DeterministicWrapper");
            % importfile = filepath + "+deterministic/algorithms.txt";

            % Correction to use with Windows or Linux
            importfile = [filepath filesep '+deterministic' filesep 'algorithms.txt'];

            hdargs_cell = namedargs2cell(hdargs);

            opts = detectImportOptions(importfile);
            opts.CommentStyle = "#";
            opts.VariableNames = ["ID", "Handle", "Funktionsname"];
            opts.VariableTypes = ["double", "string", "string"];

            hdtable = readtable(importfile, opts);

            to_scan = hdtable.ID;
            if isfield(kvargs, "Range")
                % Sanitize input first
                assert(max(kvargs.Range) <= max(hdtable.ID), ...
                    "Biggest range index mustn't be bigger than %d!", ...
                    max(hdtable.ID));
                assert(min(kvargs.Range) >= min(hdtable.ID), ...
                    "Smallest range index mustn't be smaller than %d!", ...
                    min(hdtable.ID));
                to_scan = kvargs.Range;
            end

            % Import folders so it finds the algorithms, too
            import('lhp.algo.deterministic.*');
            import('lhp.algo.deterministic.simultaneous_cluster.*');
            import('lhp.algo.deterministic.successive_cluster.*');

            for tmp = 1:numel(to_scan)
                idx = find(hdtable.ID == to_scan(tmp));
                algname = strcat(hdtable.Funktionsname(idx), kvargs.NameSuffix);
                hdarray(tmp) = lhp.algo.DeterministicWrapper(...
                    str2func(hdtable.Handle(idx)), ...
                    algname, ...
                    hdargs_cell{:});
            end

            return;
        end
    end
end

