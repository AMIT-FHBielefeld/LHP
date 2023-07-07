classdef StochasticWrapper < lhp.algo.BaseWrapper
    %StochasticWrapper Wrapper to manage genetic algorithms for LHP
    %
    %   As a childclass of `BaseWrapper`, this class spezializes on managing
    %   genetic/bio-inspired algorithms for solving the "Laubharkproblem".

    properties (SetAccess=public)
        % Number of runs for the monte-carlo simulation.
        NumMonteCarloRuns;
        % Whether to store populations, too.
        StorePopulations;
        % Number of workers for parallelization
        NumWorkers;
        % Whether to record RNG states when running evaluations
        StoreRNG;
    end

    properties (SetAccess=private)
        % Additional parameters, passed as second argument to the algorithm
        % handle that this object solves for.
        Parameters;
    end

    methods (Access=public)
        function self = StochasticWrapper(algorithm_handle, algorithm_name, ...
                algorithm_parameters, bdargs, kvargs)
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
            %   algorithm_parameters:
            %       A struct, class or other arbitrary structure that contains
            %       additional information for the algorithm that is passed in
            %       as `algorithm_handle`. This structure is treated as opaque
            %       object and no assumptions about its contents are being made.
            %       It only needs to make sense to the algorithms that use it.
            %       When running the algorithms (`algorithm_handle`), this
            %       structure is passed as second argument, after the instance
            %       of `ProblemData` that is to be solved.
            %
            %   Keyword Arguments
            %   -----------------
            %   'NumMonteCarloRuns': positive integer, default: 10
            %       Defines how many iterations to perform during the
            %       Monte-Carlo Simulation.
            %   'StorePopulations': logical, default: true
            %       Control whether the Populations that were created by the
            %       genetic algorithm should be stored in the results structure,
            %       too. Note that the required storage will become very large
            %       for bigger gardens. Set to 'false' is calculating big
            %       problems or many problems.
            %   'NumWorkers': double, default: 0
            %       If set to any positive number bigger than 0, the monte-carlo
            %       simulation will be run with at most this many worker
            %       threads. If set to 0, parallelization is deactivated.
            %   'StoreRNG': logical, default: false
            %       It set to true, two additional fields will be added to the
            %       results structure:
            %
            %       - 'rng_type': Stores the type of random number generator
            %         under which the evaluation of a result took place
            %       - 'rng_state': Stores the exact state of the rng before the
            %         algorithm evaluation was performed
            %
            %       These fields allow the user to precisely reproduce
            %       calculations that were performed as part of e.g. automated
            %       tests, where not all results (like populations) could be
            %       stored for reasons of memory usage.
            %       In order to ''replay'' these results, the `replay` method
            %       can be used. Refer to the documentation of `replay` for
            %       additional information.
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
                algorithm_parameters (1, 1)
                bdargs.?lhp.algo.BaseWrapper
                kvargs.NumMonteCarloRuns (1, 1) double {...
                    mustBeInteger(kvargs.NumMonteCarloRuns), ...
                    mustBePositive(kvargs.NumMonteCarloRuns)} = 10;
                kvargs.StorePopulations (1, 1) logical = true;
                kvargs.NumWorkers (1, 1) double {mustBeNonnegative} = 0;
                kvargs.StoreRNG (1, 1) logical = false;
            end

            % Expand and pass arguments for BaseData to BaseData.
            bdargs_cell = namedargs2cell(bdargs);
            self@lhp.algo.BaseWrapper(...
                algorithm_handle, algorithm_name, bdargs_cell{:});
            self.Parameters = algorithm_parameters;

            % Set default parameters
            self.NumMonteCarloRuns = kvargs.NumMonteCarloRuns;
            self.StorePopulations = kvargs.StorePopulations;
            self.NumWorkers = kvargs.NumWorkers;
            self.StoreRNG = kvargs.StoreRNG;
        end

        function plot(self, canvas, what, which)
            %% Plot the internal data.
            %
            %   Takes the canvas and plots the data to it. If more than one
            %   dataset was recorded, the plot style is a boxplot (Refer to
            %   MATLABs boxplot). Otherwise, a bar-plot is shows.
            %   Data is always plotted as specified cost over garden size.
            %
            %   Parameters
            %   ----------
            %   self: lhp.algo.BaseWrapper
            %       An instance of this class
            %   canvas:
            %       A canvas to some MATLAB object that data should be plotted
            %       to.
            %   what: string
            %       Specify, what data to plot to the canvas. This can either
            %       be:
            %
            %       - 'Kosten': Gesamtkosten
            %       - 'Harkarbeit': Kosten fuer das Harken
            %       - 'Wegearbeit': Kosten unproduktiver Wege
            %       - 'Transportarbeit': Kosten fuer den Transport
            %       - 'Zeit': Ausfuehrungsdauer
            %   which: string
            %       Specify how to plot the selected data
            %
            %       - 'Best': Plot data of the result with the lowest total cost
            %       - 'Worst': Plot data of the result with the highest total
            %         cost
            %       - 'Average': Make an errorbar-plot with mean and standard
            %         deviation.
            %
            arguments
                self (1, 1) lhp.algo.BaseWrapper
                canvas (1, 1)
                what (1, 1) string {mustBeMember(what, ["Kosten", "Harkarbeit", ...
                    "Wegearbeit", "Transportarbeit", "Zeit"])}
                which (1, 1) string {mustBeMember(which, ["Best", "Worst", ...
                    "Average"])} = "Average";
            end

            self.make_plot(canvas, what, which);
        end

        function result = replay(self, res_struct, pdata, fargs)
            %%REPLAY a result obtained in the Monte-Carlo Simulation.
            %
            %   Given a result from a Monte-Carlo-Simulation (under the
            %   condition, that 'StoreRNG' was set to true before running the
            %   simulation), this method reruns the calculations with the RNG
            %   type and state that were previously stored as part of the
            %   results structure.
            %
            %   The purpose of this method is to rerun calculations exactly like
            %   they were run before, with the option to store additional return
            %   parameters that couldn't be stored before due to memory
            %   constraints or similar.
            %
            %   After having performed the calculation, the method asserts that
            %   the results obtained from the rerun exactly match the results
            %   previously stored in the `res_struct` argument.
            %
            %   Arguments
            %   ---------
            %   res_struct: struct
            %       A result structure that was previously obtained from a call
            %       to `add_new_data`. It **must** contain the fields `rng_type`
            %       and `rng_state`, which will have been created if the
            %       `StoreRNG` constructor parameter was set to true.
            %   pdata: ProblemData
            %       The `ProblemData` object that the solution was originally
            %       created for.
            %   fargs: cell array
            %       An arbitrary list of additional arguments to pass to the
            %       algorithm to execute.
            %
            %   Returns
            %   -------
            %   result: struct
            %       The result structure obtained from rerunning the algorithm
            %       with the given RNG type and state.
            %
            %   Raises
            %   ------
            %   LHP:NoRngData
            %       Raised when the function is called for a results structure
            %       that doesn't have the 'rng_type' and 'rng_state' fields.
            %   LHP:ResultMismatch
            %       Thrown when the result from rerunning the algorithm doesn't
            %       match the result inside the `res_struct` argument.
            %
            %   Notes
            %   -----
            %   Execution of the algorithms is performed on a single thread!
            %   This is necessary as we override and restore the state of the
            %   global RNG before running the evaluation which spawns the
            %   workers. This keeps the intrusion into the existing code as low
            %   as possible. If the algorithm were to be executed in parallel,
            %   it would spawn worker threads which would obtain their own
            %   (randomly initialized) RNG that doesn't reflect the one stored
            %   here.
            arguments
                self (1, 1) lhp.algo.StochasticWrapper
                res_struct (1, :) struct
                pdata (1, 1) lhp.ProblemData
                fargs (1, :) cell = {};
            end

            for s_idx = 1:numel(res_struct)
                if (~isfield(res_struct, "rng_type") ...
                        || ~isfield(res_struct, "rng_state"))
                    error("LHP:NoRngData", ...
                        "Didn't find RNG state data in the supplied " + ...
                        "structure. Did you set the 'StoreRNG' flag?");
                end

                % Store the current RNG to restore later on
                glob_rng = RandStream.getGlobalStream();

                % Threads use a different type of RNG than the "regular" matlab
                % main excution thread. Due to this, seeds and RNG states aren't
                % inter-compatible. That's why we need to temporarily override
                % the global RNG to ensure that the results are actually the
                % same. On the plus side it turns out that indeed every worker
                % thread has it's own (thread-safe, reentrant) RNG...
                new_rng = RandStream(res_struct(s_idx).rng_type);
                new_rng.State = res_struct(s_idx).rng_state;
                RandStream.setGlobalStream(new_rng);

                % Temporarily mess with the object parameters so we get all
                % return values. Also make sure we don't run the "replay" as
                % Monte-Carlo-Simulation, as that's not the point!
                prev_nmcr = self.NumMonteCarloRuns;
                prev_numworkers = self.NumWorkers;
                prev_storepops = self.StorePopulations;
                % Set to sensible values for single testrun.
                % NumWorkers **MUST** be set to 0 here, as otherwise the
                % evaluation of the algorithm will run in a separate worker
                % thread which isn't affected by the override of the RNG
                % performed above!
                self.NumMonteCarloRuns = 1;
                self.NumWorkers = 0;
                self.StorePopulations = true;

                % Don't believe a single word of what the code analyzer says! We
                % can't preallocate 'result', as it is possibly an array of
                % structs. We can't use dynamic member assignment in that case,
                % as we would have to dynamically create the same members in all
                % struct, which is impossible as we only obtain them one-by-one.
                % There's no way to preallocate this, except for hardcoding the
                % struct values, which is nonsense as it requires manual
                % maintenance should the structs ever change. Compared to the
                % average execution time of any of the bio-inspired algorithms,
                % the overhead of memory allocation is negligible...
                ret = self.get_new_results(pdata, fargs{:});
                result(s_idx) = ret; %#ok

                % Restore previous state of members
                self.NumMonteCarloRuns = prev_nmcr;
                self.NumWorkers = prev_numworkers;
                self.StorePopulations = prev_storepops;

                % Restore global RNG
                RandStream.setGlobalStream(glob_rng);

                % Assert that the calculated result matches the expected one.
                for to_match = ["HA", "WA", "TA", "K"]
                    assert(res_struct(s_idx).(to_match) == result(s_idx).(to_match), ...
                        "LHP:ResultMismatch", ...
                        "Calculated result (%f) didn't match the expected" + ...
                        " result (%f) for variable '%s'!", ...
                        result(s_idx).(to_match), ...
                        res_struct(s_idx).(to_match), to_match);
                end
            end
        end
    end

    methods (Access=protected)
        function make_plot(self, canvas, what, which)
            arguments
                self (1, 1) lhp.algo.StochasticWrapper
                canvas (1, 1) matlab.graphics.axis.Axes
                what (1, 1) string {mustBeMember(what, ["Kosten", "Harkarbeit", ...
                    "Wegearbeit", "Transportarbeit", "Zeit"])}
                which (1, 1) string {mustBeMember(which, ["Best", "Worst", ...
                    "Average", "All"])} = "Average";
            end

            % Since we sort the table by a running index, we must make sure the
            % x-data is in the right order!
            [xdata, idx_sorted] = sort(self.get(0, "AnzElem"), 'ascend');

            if any(strcmpi(which, ["Best", "All"]))
                ydata = self.get(0, what, "Best");
                plot(canvas, xdata, ydata(idx_sorted), "--*", ...
                    "DisplayName", self.alg_name + " BEST");
            end
            if any(strcmpi(which, ["Worst", "All"]))
                ydata = self.get(0, what, "Worst");
                plot(canvas, xdata, ydata(idx_sorted), "--*", ...
                    "DisplayName", self.alg_name + " WORST");
            end
            if any(strcmpi(which, ["Average", "All"]))
                ydata = self.get(0, what, "Average");
                errorbar(canvas, xdata, ydata(idx_sorted), ...
                    self.get(0, what, "Deviation"), "--*", "DisplayName", ...
                    self.alg_name + " MEAN \pm DEV");
            end
        end

        function results = get_new_results(self, pdata, fargs)
            %% Execute the algorithm and store given results
            %
            %   Parameters
            %   ----------
            %   self: lhp.algo.StochasticWrapper
            %       An instance of this class.
            %   pdata: lhp.ProblemData
            %       A definition of the problem that is to be solved
            %   fargs:
            %       An arbitrary argument list that is passed to the algorithm
            %       to be executed.
            %
            %   Returns
            %   -------
            %   results: struct
            %       A struct with the fields: "HA", "WA", "TA", "K", "s",
            %       "time" (for execution time in seconds) and "pop" (The
            %       generated population, if any)
            arguments
                self (1, 1) lhp.algo.StochasticWrapper
                pdata (1, 1) lhp.ProblemData
                fargs (1, :) cell = {};
            end

            results = struct();
            store_pops = self.StorePopulations;
            store_rng = self.StoreRNG;
            post_opt = self.PostOptimize;
            algorithm = @() self.algorithm(pdata, self.Parameters, fargs{:});

            parfor (i = 1:self.NumMonteCarloRuns, self.NumWorkers)
                if store_rng
                    glob_rng = RandStream.getGlobalStream();
                    results(i).rng_type = glob_rng.Type;
                    results(i).rng_state = glob_rng.State;
                end

                tStart = cputime();
                [s, pop] = algorithm();
                time_taken = cputime() - tStart;

                [HA, WA, TA, K] = lhp.rating.get_costs(s, pdata);

                % Do this only if post-optimization is activated
                % If it isn't, nothing changes here.
                if ~isempty(post_opt)
                    results(i).post_opt = "none";
                    K_min = K;
                    % Iterate over all configured post-optimization strategies
                    for po_strat = post_opt
                        % Get the post-optimized successor function
                        s_new = lhp.utils.hz(pdata, s, po_strat);
                        % Calculate all new costs.
                        % Store the costs in new, temporary variables so we
                        % don't overwrite the original costs calculated above
                        % (because after all, the result here may be worse)
                        [HA_po, WA_po, TA_po, K_po] = ...
                            lhp.rating.get_costs(s_new, pdata);
                        % Check if we surpassed the previous minimal cost
                        if (K_po < K_min)
                            % Update minimal cost
                            K_min = K_po;
                            % Store all relevant data
                            results(i).post_opt = po_strat;
                            HA = HA_po;
                            WA = WA_po;
                            TA = TA_po;
                            K = K_po;
                        end

                    end
                end

                results(i).HA = HA;
                results(i).WA = WA;
                results(i).TA = TA;
                results(i).K = K;
                results(i).time = time_taken;
                results(i).s = s;
                if (store_pops)
                    results(i).pop = pop;
                end
            end
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
                "Storing Populations", string(self.StorePopulations); ...
                "# of Monte Carlo Runs", string(self.NumMonteCarloRuns); ...
                "# of Worker Threads", string(self.NumWorkers)];
        end
    end
end

