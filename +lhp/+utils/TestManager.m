classdef TestManager < handle
    %TESTMANAGER Run LHT tests systematically, and in parallel

    properties(Access=private)
        % Table with all tests, algorithms and their test results
        lht_table;
        % Running ID of test cases
        test_case_id;
        % list of all algorithms
        algorithms;
    end

    methods
        function this = TestManager()
            %TESTMANAGER Construct an instance of this class
            %
            %   Instantiate internal data structures.
            this.test_case_id = 1;
            this.lht_table = table('Size', [0, 3], ...
                'VariableTypes', ["double", "cell", "string"], ...
                'VariableNames', ["TestCaseID", "ProblemData", "Description"]);
            % Initialize empty, we add content later on.
            this.algorithms = struct("handle", {}, "name", {});
        end

        function addAlgorithm(this, ahandle, aname)
            %% Add algorithms that are to be tested.
            %
            %   Add an algorithm to the "list" of algorithms that each test is
            %   run on.
            %
            %   Parameters
            %   ----------
            %   ahandle: lhp.algo.BaseWrapper
            %       An Object to the algorithm that is to be executed.
            %   aname: String (optional)
            %       A string that names the algorithm. Is used as table column
            %       name in the results table. If left empty, it is taken from
            %       the BaseWrapper object.
            arguments
                this (1, 1) lhp.utils.TestManager
                ahandle (1, 1) lhp.algo.BaseWrapper
                aname (1, 1) string = ahandle.get_name();
            end

            this.algorithms(end+1).handle = ahandle;
            this.algorithms(end).name = aname;
            % Add the new algorithm to the table, too. Since we use the given
            % name as table descriptor, it mustn't contain spaces.
            num_lines = size(this.lht_table, 1);
            table_name = strrep(aname, " ", "_");
            % Create empty dummy table column
            dummy = repmat({0}, num_lines, 1);
            this.lht_table.new_var = dummy;
            this.lht_table.Properties.VariableNames(end) = table_name;
        end

        function remove_algorithm(this, aname)
            %% Remove algorithms from this TestManager.
            %
            %   Remove the algorithm matching the supplied name from the table
            %   of results.
            %
            %   Parameters
            %   ----------
            %   aname: string
            %       The name that uniquely identifies one of the algorithms in
            %       this instance. Can be obtained through the "get_name()"
            %       method of a `BaseWrapper` object. Note that the "base" name
            %       is needed, not any interpreted version of it (like when
            %       using the "Latex" input parameter)!
            arguments
                this (1, 1) lhp.utils.TestManager
                aname (1, 1) string
            end

            selection = ([this.algorithms.name] == aname);
            % Check that the algorithm really exists.
            if all(selection == 0)
                error("There is no algorithm with name '%s'!\n", aname);
            end

            this.algorithms(selection) = [];
            % Remove it's entry from the table, too.
            table_vars = this.lht_table.Properties.VariableNames;
            to_remove = cellfun(@(x) strcmp(x, aname), table_vars);
            this.lht_table(:, to_remove) = [];
        end

        function algorithms = get_algorithms(this)
            %% Get a vector of all algorithms in this instance.
            %
            %   Can be used as convenience function to quickly extract the
            %   available algorithms that have been configured, instead of
            %   having to get the names from the full results table. Note that,
            %   independent of the configuration of the handles that were
            %   initially given to the TestManager, internal results are not
            %   stored in the handles, and thus won't be present in the returned
            %   handles.
            %
            %   Returns
            %   -------
            %   algorithms: cell-vector of `BaseWrapper`
            %       An array of `BaseWrapper` instances that this object works
            %       with. Returned as cell because algorithms may have different
            %       data types.
            algorithms = {this.algorithms.handle};
        end

        function addTestCase(this, pdata, description)
            %% Add a new testcase.
            %
            %   Adds a new test to the table of tests to run. Each test is
            %   assigned a numerically unique, monotonically increasing
            %   TestCaseID for unique identification. These TestCaseIDs remain
            %   the same for as long as the `TestManager` exists and aren't
            %   changed by calls to e.g. remove_test_case().
            %
            %   Parameters
            %   ----------
            %   pdata: lhp.ProblemData
            %       An instance of ProblemData that contains the "Problem" to
            %       solve.
            %   description: string (optional)
            %       A written description of the test case. Can be left blank.
            arguments
                this (1, 1) lhp.utils.TestManager
                pdata (1, 1) lhp.ProblemData
                description (1, 1) string = "";
            end
            tci = this.test_case_id;

            tablewidth = size(this.lht_table, 2);
            dummy = repmat({{0}}, 1, tablewidth - 3);
            new_row = size(this.lht_table, 1) + 1;
            this.lht_table(new_row, :) = [{tci, {pdata}, description}, dummy];

            this.test_case_id = tci + 1;
        end

        function remove_test_case(this, index)
            %% Remove a test case given by its index
            %
            %   Removes a test case from the table of results. The index that
            %   the given test previously populated will be removed from the
            %   table and won't be re-populated. This is to ensure compatibility
            %   with evaluation codes that rely on test case IDs. This should
            %   not cause issues in conjunction with the logical indexing into
            %   the table (through "where()"), as long as the evaluation of
            %   "where()" always takes place on the current dataset, and isn't
            %   saved and restored from previous evaluations!
            %
            %   Parameters
            %   ----------
            %   index: double
            %       A scalar or 1-D vector of double values that denote valid
            %       indexes in the results table. The indexes given here will be
            %       removed from the table.
            arguments
                this (1, 1) lhp.utils.TestManager
                index (1, :) double {mustBePositive, mustBeInteger}
            end

            % Make sure index is in the table
            table_indexes = this.lht_table.TestCaseID;
            if ~all(ismember(index, table_indexes))
                error("You must provide valid TestCaseIDs!");
            end

            selection = any(table_indexes == index, 2);
            this.lht_table(selection, :) = [];
        end

        function results = runAllTests(this, kvargs)
            %% Run all available test cases.
            %
            %   Takes all test cases that haven't been run yet and executes
            %   them with each of the algorithms specified. Tests are executed
            %   in parallel, using the Parallel Computation Toolbox. Thus, it
            %   is strictly necessary that the toolbox is installed!
            %
            %   During testing, a text-based progress bar is displayed by
            %   default. If you prefer a graphical progress bar (like with
            %   'uiprogressdlg()'), have a look at the 'UI' Parameter to this
            %   method.
            %
            %   Keyword Arguments
            %   -----------------
            %   'UI': matlab.ui.dialog.ProgressDialog
            %       A handle to a graphical progress bar, created with the
            %       uiprogressdlg() function. If supplied, the progress of the
            %       tests will be shown on the respective progress bar, instead
            %       of in the command window (text-based output)
            %   'OvercommitFactor': double, default: 1.5
            %       Controls how many parallel jobs to dispatch at any given
            %       point in time. Setting this to 1 will always only dispatch
            %       as many jobs as there are parallel workers. It is
            %       recommended to increase this value above 1 to have some jobs
            %       in ''reserve'' to pick up for workers that have already
            %       finished their jobs, without the main action loop having to
            %       reschedule some first. Reduce this value if you realize
            %       you're running out of RAM.
            %
            %   Returns
            %   -------
            %   The table with all of the gathered results.
            arguments
                this (1, 1) lhp.utils.TestManager
                kvargs.UI (1, 1) matlab.ui.dialog.ProgressDialog
                kvargs.OvercommitFactor (1, 1) double {mustBePositive} = 1.5;
            end
            untested_mat = this.getUntestedTestCases();
            untested = find(untested_mat);
            untested_size = size(untested_mat);

            num_tests_to_run = nnz(untested);
            if num_tests_to_run == 0
                fprintf("All tests have been run already!\n");
                fprintf("Nothing to do...\n");
                % Quit immediately!
                results = this.lht_table;
                return;
            else
                fprintf("Begin running %d tests!\n\n", num_tests_to_run);
            end

            % Get a parallel pool.
            p = gcp();
            % Register cleanup function to make sure workers are killed even if
            % user sends Ctrl+C to kill this function.
            cleanObj = onCleanup(@()cleanUpGCP(p));

            if ~isfield(kvargs, "UI")
                % Initialize text-based progress bar
                % Clear any previous junk we may have printed.
                fprintf("\n\n\n");
                progbar = lhp.utils.ProgressBar(...
                    "WindowWidth", 80, ...
                    "BarStyle", "=", ...
                    "WidestNumber", 5, ...
                    "UpdateString", "Test completion", ...
                    "UpdateEvery", 0.2, ...
                    "MaxValue", num_tests_to_run);
            else
                % Initialize UI-based progress bar
                progbar = lhp.utils.ProgressBar(...
                    "WindowWidth", 80, ...
                    "BarStyle", "=", ...
                    "WidestNumber", 5, ...
                    "UpdateString", "Test completion", ...
                    "UpdateEvery", 0.2, ...
                    "MaxValue", num_tests_to_run, ...
                    "UI", kvargs.UI);
            end
            % Call with the "proper" arguments, so the bar is correctly
            % displayed when picking up tests that were previously aborted.
            progbar.init(0);

            % Put initial jobs into the queue
            qlen = ceil(p.NumWorkers * kvargs.OvercommitFactor);
            jobqueue = table('Size', [qlen, 2], ...
                'VariableTypes', {'double', 'parallel.FevalFuture'}, ...
                'VariableNames', {'TestID', 'Future'});
            cur_idx = 1;

            % Initially fill the queue up
            while cur_idx <= qlen
                u = untested(cur_idx);

                [line, col] = ind2sub(untested_size, u);

                % Get the algorithm and corresponding data for this runner
                algorithm = this.algorithms(col).handle;
                pdata = this.lht_table.ProblemData{line};

                jobqueue.Future(cur_idx) = ...
                    parfeval(@algorithm.add_new_data, 2, pdata);
                jobqueue.TestID(cur_idx) = cur_idx;
                cur_idx = cur_idx + 1;

                % No jobs left to enqueue. Remove all 'unavailable' futures and
                % start collecting.
                if cur_idx > nnz(untested)
                    jobqueue(cur_idx:end, :) = [];
                    break;
                end
            end

            while nnz(untested) > 0
                try
                    % Collect results.
                    [jobIdx, ~, result] = fetchNext(jobqueue.Future);
                    completedIdx = jobqueue.TestID(jobIdx);
                    % Get the actual table index this worker belongs to
                    test_id = untested(completedIdx);
                    % Mark the test as done
                    untested(completedIdx) = 0;

                    progbar.increment();

                    % Add new test results to the table
                    [line, col] = ind2sub(untested_size, test_id);
                    this.lht_table{line, col + 3} = {result};

                    if (nnz(untested) == 0) || (cur_idx > numel(untested))
                        % No tests left, we're done here
                        continue;
                    else
                        % Enqueue new job
                        u = untested(cur_idx);
                        [line, col] = ind2sub(untested_size, u);

                        % Get the algorithm and corresponding data for this
                        % runner
                        algorithm = this.algorithms(col).handle;
                        pdata = this.lht_table.ProblemData{line};

                        jobqueue.Future(jobIdx) = ...
                            parfeval(@algorithm.add_new_data, 2, pdata);
                        jobqueue.TestID(jobIdx) = cur_idx;
                        cur_idx = cur_idx + 1;
                    end

                catch ME
                    cleanUpGCP(p);
                    error(sprintf("There was an error running the tests." + ...
                        " All running threads have been stopped.\n\n%s", ...
                        getReport(ME)));
                end
            end

            results = this.lht_table;
            return;

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
        end

        function results = get_results(this, kvargs)
            %% Return current results to the user.
            %
            %   Keyword Arguments
            %   -----------------
            %   'From': array
            %       An array (either logical or numeric) that specifies which
            %       rows (TestCaseIDs) to return. If left empty, all results
            %       will be returned.
            %   'Value': string
            %       A value from the result structs of all algorithms to return.
            %       For reasons of compatibility, this can only be set to fields
            %       that exist in all algorithms return values. If you need
            %       access to specific fields not covered here, obtain them from
            %       the whole results table instead. If 'Value' is not supplied,
            %       the results aren't filtered. If it is supplied, please refer
            %       to the 'Merge' parameter for additional handling of
            %       specialties.
            %       Possible values are:
            %
            %       - 'Gesamtkosten': Get the total cost
            %       - 'Harkkosten': Get the cost of raking
            %       - 'Wegekosten': Get the cost of unproductive walking
            %       - 'Transportkosten': Get the cost of transportation
            %       - 'Zeit': Get the total execution time in seconds
            %
            %   'Merge': string, default: 'Median'
            %       This parameter takes care of special handling for algorithms
            %       that produce multiple results (like stochastic algorithms
            %       running in a Monte-Carlo simulation). We cannot return all
            %       of the results in the table (for obvious reasons), thus we
            %       must "merge" them to scalar values. The following operations
            %       thus don't apply to heuristics.
            %       Possible values are:
            %
            %       - 'Mean': Get the mean of all results
            %       - 'Median': Get the median of all results
            %       - 'Minimum': Get the minimum of all results
            %       - 'Maximum': Get the maximum of all results
            %
            %   'ExportAs': string
            %       Specify this argument to export the selected results table
            %       to an Excel-compatible format. The value to this argument is
            %       the filename under which to save the exported file. The
            %       format defaults to CSV for biggest compatibility. The export
            %       location is the "exports" folder in the project root folder.
            %       This directory is created if it doesn't exist.
            %       **Note**: Exporting only works if you supply the "Value"
            %       argument, as it is not possible to export all structures
            %       into a regular 2-D table.
            arguments
                this (1, 1) lhp.utils.TestManager
                kvargs.From (1, :) logical
                kvargs.Value (1, 1) string {mustBeMember(kvargs.Value, ...
                    ["Gesamtkosten", "Harkkosten", "Wegekosten", ...
                     "Transportkosten", "Zeit"])}
                kvargs.Merge (1, 1) string {mustBeMember(kvargs.Merge, ...
                    ["Mean", "Median", "Minimum", "Maximum"])} = "Median";
                kvargs.ExportAs (1, 1) string
            end

            results = this.lht_table;
            if ismember("From", fieldnames(kvargs))
                results = results(kvargs.From, :);
            end

            if isfield(kvargs, "Value")
                % Get the value to obtain
                var = "";
                switch (kvargs.Value)
                    case "Gesamtkosten"
                        var = "K";
                    case "Harkkosten"
                        var = "HA";
                    case "Wegekosten"
                        var = "WA";
                    case "Transportkosten"
                        var = "TA";
                    case "Zeit"
                        var = "time";
                end

                % Get the operation to perform
                op = [];
                switch (kvargs.Merge)
                    case "Mean"
                        op = @mean;
                    case "Median"
                        op = @median;
                    case "Minimum"
                        op = @min;
                    case "Maximum"
                        op = @max;
                end

                subres = results(:, 4:end);
                selection = varfun(@(cell) (cellfun(...
                    @(struct) (get_data(struct, var, op)), cell)), subres);
                results = [results(:, 1:3), selection];

                if isfield(kvargs, "ExportAs")
                    % Prepare export to file.
                    TARGET_DIR = "exports";
                    [~, file, ~] = fileparts(kvargs.ExportAs);
                    filename = fullfile(TARGET_DIR, strcat(file, ".csv"));

                    if ~isfolder(TARGET_DIR)
                        mkdir(TARGET_DIR);
                    end

                    writetable(results, filename, ...
                        "WriteVariableNames", true, ...
                        "WriteRowNames", false, ...
                        "WriteMode", "overwrite", ...
                        "Encoding", "UTF-8", ...
                        "QuoteStrings", true, ...
                        "Delimiter", ",");
                end
            end

            return;

            function data = get_data(struct, var, op)
                % Get data from a given result 'struct' and apply 'op'.
                % Returns NaN if 'var' is no member of 'struct'.
                try
                    data = op([struct.(var)]);
                catch
                    data = NaN;
                end
            end
        end

        function [data, grouped_by, sorted_by] = extract(this, algorithm, variable, kvargs)
            %% EXTRACT Extract data from the generated algorithm results
            %
            %   This method allows somewhat complex access to the data that is
            %   contained in the results table.
            %
            %   Parameters
            %   ----------
            %   algorithm: string
            %       The name of an algorithm from which to extract result data.
            %       The given name must match any of the algorithm names that
            %       are part of this TestManager instance.
            %   variable: string
            %       The variable to extract from the specified algorithms
            %       results. This must be a member of the results structures
            %       generated by the specific algorithm.
            %
            %   Keyword Arguments
            %   -----------------
            %   'GroupBy': string
            %       The name of a member variable of ProblemData that the
            %       returned data is to be grouped by. Data is grouped in a 3D
            %       fashion. Refer to the "data" return value for more
            %       information on how grouping works.
            %       Also, please refer to the "grouped_by" return parameter.
            %   'SortBy': string (Optional)
            %       The name of a scalar member variable of ProblemData that the
            %       returned data is to be sorted by. Refer to the "data" return
            %       value for more information on how sorting affects returned
            %       data.
            %       Also, please refer to the "sorted_by" return parameter.
            %   'From': logical array (Optional)
            %       Defines an array that can be used to index into the results
            %       table (row-wise). If supplied, only data from the selected
            %       table rows will be considered for returning to the user.
            %       The indexing array must be logical.
            %       By default, all rows are considered.
            %
            %   Returns
            %   -------
            %   data: matrix
            %       A matrix that contains the requrested data. The matrix max
            %       have up to three dimensions, depending on the complexitiy of
            %       the requested data.
            %       The matrix is organized as follows:
            %
            %       - The first dimension (rows) is controlled by the 'SortBy'
            %         Key-Value parameter. It affects merely how the
            %         individual data rows are organized, not their content.
            %       - The second dimension (columns) is affected by the type of
            %         algorithm that is evaluated. It contains the individual
            %         measurements performed. The second dimension is always 1
            %         for the heuristic algorithms (Since these produce only 1
            %         solution per Problem). It can be bigger than 1 for
            %         Stochastic Algorithms since these are configured to
            %         perform Monte-Carlo Simulations, and thus create more than
            %         one solution for one Problem.
            %       - The third dimension (depth) is affected by the 'GroupBy'
            %         Key-Value Parameter. For each distinct Element that is
            %         part of the 'GroupBy' parameter, an additional 2-D
            %         matrix is appended in the third dimension. If e.g. tests
            %         have been performed on three distinct gardens (of same
            %         or different size), and the 'GroupBy' parameter is set
            %         to 'Garden' (Which is the member of ProblemData), the
            %         returned matrix will have a depth of 3.
            %
            %       Here's an illustration of how the result is organized::
            %
            %                    J     K     L
            %                   /     /     /        _    GroupBy
            %           S |    A --- B --- C         /|
            %           o      |     |     |/
            %           r |    D --- E --- F       /
            %           t      |     |     |/
            %           B |    G --- H --- I     /
            %           y V
            %               - - - - - - - >
            %               # Measurements (1 for Heuristics, more for Genetic)
            %
            %   grouped_by: array
            %       An array that is populated with the values that the returned
            %       data is grouped by. This array has as many elements as the
            %       returned matrix is deep. Also, every value in its respective
            %       3rd dimension layer of data belongs to the corresponding
            %       array element of grouped_by. Refer to the examples for more
            %       information.
            %   sorted_by: array (optional)
            %       This is only populated if the 'SortBy' parameter has been
            %       set.
            %       If available, this array contains the values that the data
            %       matrix is sorted by in the first dimension (rows) in exactly
            %       the order that the rows are sorted. Refer to the examples
            %       for more information.
            %
            %   Examples
            %   --------
            %   1) Working with scalar data.
            %   >> tm = lhp.utils.TestManager();
            %   >> tm.addAlgorithm(lhp.algo.DeterministicWrapper.gather("Range", 1));
            %   >> tm.addAlgorithm(lhp.algo.DeterministicWrapper.gather("Range", 2));
            %   % Add some test cases
            %   >> for i = 1:5; tm.addTestCase(lhp.ProblemData(12, 12)); end
            %   >> tm.runAllTets();
            %   % Now play with the data.
            %   % Get the computation times.
            %   % Since we have generated 5 gardens at random, they're all
            %   % distinct. So the returned data is 1x1x5
            %   >> tm.extract("Clustermax", "time", "GroupBy", "Garden")
            %
            %   .. todo:: Example 2 needs a rework with the package names...
            %
            %   2) Working with genetic algorithms and different tests
            %   >> tm = lhp.utils.TestManager();
            %   >> tm.addAlgorithm(LHT_GeneticData(@genetic, "Genetisch"));
            %   % Prepare some tests
            %   >> garden_sizes = [10, 15, 20];
            %   >> population_sizes = [1, 2, 5, 10, 15];
            %   >> for gs = garden_sizes
            %   >>     G = zufaelligerGarten(gs, gs);
            %   >>     pdata = ProblemData(gs, gs, "Garten", G, "PopulationSize", 1);
            %   >>     for ps = population_sizes
            %   >>         pdata.Popsize = ps;
            %   >>         info_str = sprintf("Gartengroesse: %d x %d; Population: %d", gs, gs, ps);
            %   >>         tm.addTestCase(pdata, info_str);
            %   >>     end
            %   >> end
            %   >> tm.runAllTests();
            %   % Evaluate the results now. We want to see how PopulationSize
            %   % affects the total cost of the generated solution. We do so
            %   % for different gardens. Thus we split the results into
            %   % Problems that dealt with equal gardens ('GroupBy'), and sort
            %   % all data by PopulationSize ('SortBy')
            %   >> [stacked_scores, gardens, popsizes] = tm.extract("Genetisch", "K", ...
            %   ...    "GroupBy", "Original", "SortBy", "Popsize");
            %   % Say we want to know the least (best) costs per garden and
            %   % Popsize. Remember that the second dimension are the multiple
            %   % measurements from the Monte-Carlo simulation.
            %   >> min_scores = min(stacked_scores, [], 2);
            %   % Create one figure per garden
            %   >> for idx = 1:numel(gardens)
            %   >>     figure();
            %   >>     subplot(1, 2, 1);
            %   >>     heatmap(gardens(idx)); title("Gartenmatrix");
            %   >>     subplot(1, 2, 2);
            %   >>     plot(popsizes, min_scores(:, :, idx); title("Min-Kosten");
            %   >>     xlabel("Populationsgroesse");
            %   >> end
            arguments
                this (1, 1) lhp.utils.TestManager
                algorithm (1, :) string
                variable (1, :) string
                kvargs.GroupBy (1, :) string = "";
                kvargs.SortBy (1, :) string = "";
                kvargs.From (1, :) logical;
            end

            %% Argument validation
            mytmppdata = this.lht_table.ProblemData{1};
            pdata_fieldnames = fieldnames(mytmppdata);
            % Grouping variables must be member of ProblemData
            if isempty(kvargs.GroupBy) || ~ismember(kvargs.GroupBy, pdata_fieldnames)
                fields_str = sprintf("  - %s\n", pdata_fieldnames{:});
                error("You must specify a grouping variable that is a valid member\n" ...
                    + "of the ProblemData class!\n" ...
                    + "To specify a grouping variable refer to the documentation.\n" ...
                    + "Valid variables include: \n"...
                    + "%s\n\n", fields_str);
            end

            % Sorting Variables, too, must be members of ProblemData
            if strlength(kvargs.SortBy) > 0
                % If the variable contains a dot, it references a member of a
                % member-struct or subclass. We must account for this with the
                % new bee algorithm that encapsulates it's config params in its
                % own class.
                member = kvargs.SortBy;
                if ~isempty(strfind(kvargs.SortBy, "."))
                    tmp = strsplit(kvargs.SortBy, ".");
                    member = tmp(1);
                end

                if ~ismember(member, pdata_fieldnames) || ...
                        ~isscalar(mytmppdata.(member))
                    scalars = zeros(1, numel(pdata_fieldnames));
                    for x = 1:numel(scalars)
                        scalars(x) = isscalar(mytmppdata.(pdata_fieldnames{x}));
                    end
                    fields_str = sprintf("  - %s\n", pdata_fieldnames{logical(scalars)});
                    error("Sorting variables must be valid, scalar members of the\n" ...
                        + "ProblemData class!\n" ...
                        + "Valid variables include:\n" ...
                        + "%s\n\n", fields_str);
                end
            end

            % Algorithm names must be the same names as specified in the
            % data table.
            valid_alg_names = this.lht_table.Properties.VariableNames(4:end);
            if ~ismember(algorithm, valid_alg_names)
                alg_str = sprintf("  - %s\n", valid_alg_names{:});
                error("The algorithm you specified is invalid (%s)\n" ...
                    + "Valid algorithms include:\n" ...
                    + "%s\n\n", algorithm, alg_str);
            end

            % Variable names must be valid members of the selected algorithms
            % results structure.
            valid_vars = fieldnames(this.lht_table{1, algorithm}{1});
            if ~ismember(variable, valid_vars)
                var_str = sprintf("  - %s\n", valid_vars{:});
                error("The variable you specified is invalid (%s)\n" ...
                    + "Please supply a variable that is part of your algorithms results!\n" ...
                    + "Valid variables include:\n" ...
                    + "%s\n\n", variable, var_str);
            end

            %% Actual data extraction
            pdatas = [this.lht_table.ProblemData{:}];
            alg_results = this.lht_table.(algorithm);
            if ismember("From", fieldnames(kvargs)) %~any(isinf(kvargs.From))
                pdatas = pdatas(logical(kvargs.From));
                alg_results = alg_results(logical(kvargs.From));
            end

            var_cell = cellfun(@(cell) ([cell.(variable)]), alg_results, ...
                "UniformOutput", false);
            var = vertcat(var_cell{:});

            % Split by grouping variable
            grouped_by = {};
            for idx = 1:numel(pdatas)
                gb = pdatas(idx).(kvargs.GroupBy);
                if ~this.cellfind(grouped_by, gb)
                    % Append new group variable, since we haven't got that yet.
                    grouped_by{end+1} = gb;
                end
            end

            entries_per_group = ceil(numel(pdatas) / numel(grouped_by));
            stacked_var = zeros(entries_per_group, size(var, 2), numel(grouped_by));
            groupvar = {pdatas.(kvargs.GroupBy)};

            for idx = 1:numel(grouped_by)
                group_idx = this.cellfind(groupvar, grouped_by{idx});
                if strlength(kvargs.SortBy) > 0
                    % Must handle subindexing again.
                    if strfind(kvargs.SortBy, ".")
                        tmp = strsplit(kvargs.SortBy, ".");
                        subs = [pdatas(group_idx).(tmp(1))];
                        main = tmp(2);
                        to_sort = zeros(1, numel(subs));
                        for tsidx = 1:numel(to_sort)
                            to_sort(tsidx) = subs(tsidx).(main);
                        end
                        [sorted_by, sort_idx] = sort(to_sort);
                    else
                        [sorted_by, sort_idx] = sort(vertcat(pdatas(group_idx).(kvargs.SortBy)), 1);
                    end
                    tmp = var(group_idx, :);
                    sorted_var = tmp(sort_idx, :);
                    stacked_var(1:size(sorted_var, 1), ...
                        1:size(sorted_var, 2), idx) = sorted_var;
                else
                    stacked_var(:, :, idx) = var(group_idx, :);
                end
            end

            data = stacked_var;
            return;
        end

        function indexes = where(self, pdata_variable, relation, comp)
        %WHERE Extract the indizes of test cases that match given criteria.
        %
        %   Returns a sorted list of all indizes of test cases where the given
        %   pdata_variable relates to the variable comp as specified. This can
        %   be used, for example, to extract specifically all tests where a
        %   given criterion is matched (e.g. Strict Rating is True, or similar).
        %
        %   The indices can the be processed by the user, or passed to other
        %   methods for more fine-grained control about the data to obtain.
        %   Methods that accept indices as arguments include:
        %
        %   - extract()
        %   - get_results()
        %
        %   Parameters
        %   ----------
        %   pdata_variable: string
        %       String name of a variable that is part of ProblemData.
        %       Currently, indices can only be filtered based on member
        %       variables in ProblemData.
        %   relation: string
        %       A string that defines a Matlab-style relational operator that
        %       describes the expected relation between pdata_variable and comp.
        %       Valid values include: "==", "~=", "<", "<=", ">", ">="
        %   comp:
        %       A variable that must be of the same type as the member of
        %       ProblemData specified in pdata_variable.
        %
        %   Returns
        %   -------
        %   indexes: array of integer
        %       An array that contains the indices for all tests where the given
        %       criterion matches.
            arguments
                self (1, 1) lhp.utils.TestManager
                pdata_variable (1, 1) string
                relation (1, 1) string {mustBeMember(relation, ...
                    ["==", "~=", "<", "<=", ">", ">="])}
                comp (1, 1)
            end

            %% Validate arguments
            pdata_props = properties("lhp.ProblemData");
            if ~ismember(pdata_variable, pdata_props)
                error("You must specify a valid member of the ProblemData class!" ...
                    + " Valid members include:\n%s\n\n", ...
                    sprintf("  - %s\n", pdata_props{:})); %#ok<*SPERR>
            end
            %% Code
            pdatas = [self.lht_table.ProblemData{:}];
            if isempty(pdatas)
                return;
            elseif ~strcmpi(class(pdatas(1).(pdata_variable)), class(comp))
                error("Type of argument 'comp' doesn't match type of" ...
                    + " member variable %s!", pdata_variable);
            end

            var = vertcat(pdatas.(pdata_variable));
            switch (relation)
                case "=="
                    indexes = (var == comp);
                case "~="
                    indexes = (var ~= comp);
                case "<"
                    indexes = (var < comp);
                case "<="
                    indexes = (var <= comp);
                case ">"
                    indexes = (var > comp);
                case ">="
                    indexes = (var >= comp);
                otherwise
                    error("I don't know what that means");
            end
        end

        function flatten(this)
            %% Reduce memory consumption by flattening all ProblemData members.
            %
            %   Iterates through all members of type ProblemData in the internal
            %   data table and calls their "flatten()" methods to reduce their
            %   memory usage. See `ProblemData.flatten()` for further
            %   information.
            for cell = 1:numel(this.lht_table.ProblemData)
                this.lht_table.ProblemData{cell} = ...
                    this.lht_table.ProblemData{cell}.flatten();
            end
        end

        function unflatten(this)
            %% Restore all ProblemData members
            %
            %   Calls the unflatten() method of all ProblemData members. Refer
            %   to `ProblemData.unflatten()` for further information.
            table_pdatas = [this.lht_table.ProblemData{:}];
            for idx = 1:numel(table_pdatas)
                % First check that this pdata isn't flattened yet.
                if table_pdatas(idx).is_flattened()
                    % Check if we already have a solution for that.
                    %for search_idx = 1:numel(table_pdatas)
                    %    if ~isequal(size(table_pdatas(search_idx).Garden), ...
                    %            size(table_pdatas(idx).Garden))
                    %        continue;
                    %    end

                    %    if ~table_pdatas(search_idx).is_flattened() && ...
                    %        all((table_pdatas(search_idx).Garden == table_pdatas(idx).Garden), "all") && ...
                    %        (table_pdatas(search_idx).Start == table_pdatas(idx).Start) && ...
                    %        (table_pdatas(search_idx).Target == table_pdatas(idx).Target)

                    %        % Nice, we already have that. Then take the
                    %        % solutions we calculated previously.
                    %        table_pdatas(idx) = table_pdatas(idx).inflate(...
                    %            table_pdatas(search_idx).DMatrix, ...
                    %            table_pdatas(search_idx).Adjacency, ...
                    %            table_pdatas(search_idx).GMatrix);
                    %        break;
                    %    end
                    %end
                    table_pdatas(idx) = table_pdatas(idx).unflatten();
                end

                this.lht_table.ProblemData{idx} = table_pdatas(idx);
            end
        end

        function tm = merge_with(this, other)
            %% Merge this TestManager with another.
            %
            %   Takes another instance of TestManager and merges the results
            %   table with the results of the current TestManager. Merging works
            %   only if certain conditions apply, as detailed below.
            %
            %   For merging of different test cases (with the same algorithms
            %   present in both TestManagers) the algorithms used in both
            %   TestManagers **must** have the same Name property to be
            %   recognized as the same algorithm. Note that this is the case if
            %   you instantiate all algorithms through the `gather()` or
            %   `wrapper()` functions, depending on the algorithm type.
            %   For this merge type, essentially the rows of `other` are
            %   concatenated to the results table of the current TestManager.
            %
            %   For merging of different algorithms (with the same test cases
            %   present in both TestManagers) the ProblemData-objects of both
            %   TestManagers must match in all of their respective attributes,
            %   excluding the test description string (as this may be left empty
            %   and is thus ambiguous) to be recognized as being equal. Note
            %   that his means that tests won't be recognized as identical if
            %   e.g. the gardens differ, or the starting field (Because in this
            %   case, in fact, they are different tests!).
            %
            %   If column- or row-wise matches can't be found and any columns or
            %   rows are left over (without a fitting match in the other results
            %   table), "regular" new entries will be created for them instead.
            %   All results that are present will be filled in, any other tests
            %   won't be run automatically. It is up to the user to have these
            %   holes filled by means of the `runAllTests()` method.
            %
            %   Parameters
            %   ----------
            %   other: lhp.utils.TestManager
            %       Another instace of TestManager, whose results are to be
            %       merged into the results of the current TestManager.
            %
            %   Returns
            %   -------
            %   tm: lhp.utils.TestManager
            %       The modified version of this TestManager that contains all
            %       results.
            %
            %   Notes
            %   -----
            %   This method doesn't make assumptions about the ordering of
            %   identical test cases or algorithms. It is thus not required to
            %   keep tests or algorithms in the same strict order, as long as a
            %   match can be found.
            arguments
                this (1, 1) lhp.utils.TestManager
                other (1, 1) lhp.utils.TestManager
            end

            % Sanity checks
            % Either of both result tables mustn't be empty
            if isempty(this.lht_table) && isempty(other.lht_table)
                error('TestManager:CantMergeEmpty', ...
                    "At least one of both results tables must be populated!");
            end
            % this and other mustn't be the same reference
            if (this == other)
                error('TestManager:CantMergeSelf', ...
                    "Can only merge different TestManager instances!");
            end

            this_str.algorithms = this.get_algorithms();
            this_str.pdatas = this.lht_table.ProblemData;

            other_str = struct();
            other_str.results = other.get_results();
            other_str.algorithms = other.get_algorithms();
            other_str.pdatas = other.lht_table.ProblemData;

            %   Make two mappings:
            %
            %   1. For the algorithms
            %   2. For the test cases
            %
            %   that tell us which 'thing' from `other` belongs where in `this`.

            % Algorithm mapping
            other_str.algorithm_mapping = zeros(1, numel(other_str.algorithms));
            % Tracks the last vacant position. This is where we input algorithms
            % present in 'other' that don't exist in 'this' yet.
            overrun = numel(this_str.algorithms) + 1;

            for other_aidx = 1:numel(other_str.algorithms)
                other_alg = other_str.algorithms{other_aidx};
                for this_aidx = 1:numel(this_str.algorithms)
                    this_alg = this_str.algorithms{this_aidx};
                    if isequal(this_alg, other_alg)
                        other_str.algorithm_mapping(other_aidx) = this_aidx;
                        % Continue to next algorithm from other
                        break;
                    end

                    if this_aidx == numel(this_str.algorithms)
                        % Only come here when the algorithm in 'other' wasn't
                        % yet present in 'this'
                        other_str.algorithm_mapping(other_aidx) = overrun;
                        overrun = overrun + 1;
                        % Add new algorithm to this table
                        this.addAlgorithm(other_alg);
                    end
                end
            end

            % Testcase mapping
            other_str.test_mapping = zeros(1, numel(other_str.pdatas));
            % Tracks the last vacant position. This is where we input tests
            % present in 'other' that don't exist in 'this' yet.
            overrun = numel(this_str.pdatas) + 1;

            for other_pidx = 1:numel(other_str.pdatas)
                other_pdata = other_str.pdatas{other_pidx};
                for this_pidx = 1:numel(this_str.pdatas)
                    this_pdata = this_str.pdatas{this_pidx};
                    if isequal(this_pdata, other_pdata)
                        other_str.test_mapping(other_pidx) = this_pidx;
                        % Continue to next test from other
                        break;
                    end

                    if this_pidx == numel(this_str.pdatas)
                        % Only come here when the test in 'other' wasn't yet
                        % present in 'this'
                        other_str.test_mapping(other_pidx) = overrun;
                        overrun = overrun + 1;
                        % Add new algorithm to this table
                        this.addTestCase(other_pdata, ...
                            other_str.results{other_pidx, 3});
                    end
                end
            end

            % Print some progress along the way
            fprintf("\n\n\n");
            num_tests_to_run = numel(other_str.pdatas) * numel(other_str.algorithms);
            progbar = lhp.utils.ProgressBar(...
                "WindowWidth", 80, ...
                "BarStyle", "=", ...
                "WidestNumber", 5, ...
                "UpdateString", "Merge completion", ...
                "UpdateEvery", 0.2, ...
                "MaxValue", num_tests_to_run);
            progbar.init(0);

            % Populate all tests now!
            for test_idx = 1:numel(other_str.pdatas)
                test_idx_in_this = other_str.test_mapping(test_idx);
                for alg_idx = 1:numel(other_str.algorithms)
                    % Add 3 since first 3 cols are metadata, not actual results
                    alg_idx_in_this = other_str.algorithm_mapping(alg_idx) + 3;
                    table_cell = this.lht_table{test_idx_in_this, ...
                        alg_idx_in_this};
                    if isnumeric(table_cell{1})
                        % There's no result yet, add it
                        % Beware that the "result" may be empty as well, there's
                        % really no need to check for this case here.
                        this.lht_table{test_idx_in_this, alg_idx_in_this} = ...
                            other_str.results{test_idx, alg_idx + 3};
                    else
                        % There's some result here already
                        warning('TestManager:ResultAlreadyExistent', ...
                            "Already have a result for algorithm '%s'" + ...
                            " with test at ID '%d'! Skipping...", ...
                            other_str.algorithms{alg_idx}.get_name(), ...
                            this.lht_table{test_idx_in_this, 1});
                    end
                    progbar.increment();
                end
            end
        end

        %% Operator overloads
        function disp(this)
            if isempty(this.algorithms)
                fprintf("! No algorithms to test added yet !\n");
            else
                alg_names = strjoin([this.algorithms.name], ", ");
                fprintf(" Algorithms to test: %s\n", alg_names);
            end

            untested = this.getUntestedTestCases();
            if (untested == -1)
                fprintf("! No tests were added yet !\n");
            else
                fprintf("Number of testcases: %4d\n", this.test_case_id - 1);
                not_run = nnz(untested);
                fprintf("  Tests left to run: %4d\n", not_run);
            end
        end
    end

    methods(Access=private)
        function untested = getUntestedTestCases(this)
            %% Get test cases that weren't run yet.
            %
            %   This includes test cases that were just recently added, and test
            %   cases for algorithms that were recently added. The table of
            %   tests is "extracted" from class-internal members.
            %
            %   Returns
            %   -------
            %   untested: scalar or matrix
            %       If any tests were added to the instance, returns a matrix
            %       representation of the tests (the same way they are organized
            %       internally in lht_table). A "1" marks tests that need to be
            %       run, a "0" marks tests that were completed.
            %       If no tests or algorithms were added yet, -1 is returned
            %       instead.

            % Get the subpart of the table that includes only the algorithms
            [tableheight, tablewidth] = size(this.lht_table);
            if (tablewidth < 4) || (tableheight == 0)
                % There aren't any tests yet in here...
                untested = -1;
                return;
            end

            subtable = this.lht_table(:, 4:end);
            untested = zeros(tableheight, tablewidth - 3);

            isemptycell = @(cell) (cell{1} == 0);

            for alg = 1:(tablewidth - 3)
                for line = 1:tableheight
                    field = subtable{line, alg};
                    if isstruct(field{1})
                        % Contains valid data
                        continue;
                    end
                    if isemptycell(field)
                        untested(line, alg) = 1;
                    end
                end
            end

            return;
        end
    end

    methods (Static)
        function cell_index = cellfind(cell, expr)
            %%CELLFIND Find entries in cell arrays
            %
            %   Given a cell array and an expression to search for, this function
            %   returns any index in the cell array that contains an object equal
            %   to the expression that is searched.
            %
            %   Parameters
            %   ----------
            %   cell: cell-array
            %       An array of cells, where each cell contains an arbitrary object.
            %   expr: arbitrary
            %       Some object that is searched for inside the cell array cells. The
            %       only restrictions to this input are:
            %       - It must define the == operator
            %       - It must be of the same type as the cell array contents
            %
            %   Returns
            %   -------
            %   cell_index: scalar or array
            %       - If a single match was found: Single cell array index of the match
            %       - If multiple matches were found: An array of indexes where the
            %           cell array matched expr
            %       - If no match was found: 0
            cell_index = 0;
            for idx = 1:numel(cell)
                c = cell{idx};
                % Ignore unlike gardens
                if any(size(c) ~= size(expr))
                    continue;
                end

                if c == expr
                    if cell_index == 0
                        cell_index = idx;
                    else
                        cell_index = [cell_index, idx];
                    end
                end
            end
            return;
        end
    end
end

