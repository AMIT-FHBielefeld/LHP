classdef BaseWrapper < handle
    %%BaseWrapper Data carrier for managing calculation results.
    %
    %   This class manages an algorithm that is invoked through a public method
    %   with a given set of parameters. It automatically calculates derived
    %   quantities such as resulting cost.
    %
    %   This class maintains all collected data in an exclusively internal data
    %   structure. Access to the structure is provided through ordered methods.
    %
    %   The class is abstract and not meant for direct instantiation. Instead
    %   it acts as a common interface for all ancestors that may specialize on
    %   managing specific algorithms. This is necessary since for example the
    %   genetic algorithm runs in a monte-carlos simulation and thus generates
    %   more than one result for a specific garden/problem, unlike the
    %   heuristics, that generate exactly one solution.

    properties (Access=protected)
        % Table with all results, stored as: Parameter, Result
        data_table;
        % Function handle of the algorithm wrapped inside.
        algorithm;

        % Internal counter for access through get() and plot().
        current_index;
        % Name of the algorithm (for output)
        alg_name;
    end

    properties (Access=public)
        % Set to true to store results such that they can be accessed by `get`
        StoreResults;
        % Perform post-optimization of results through the 'hz' function
        PostOptimize;
    end

    methods (Access=public)
        function self = BaseWrapper(algorithm_handle, algorithm_name, kvargs)
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
            %       spaces! Refer to the get_name() method for information on
            %       special formatting rules.
            %
            %   Keyword Arguments
            %   -----------------
            %   'StoreResults': logical
            %       If set to true (default), calculated results from
            %       add_new_data method are stored in the internal data table.
            %       If set to false, the calculated results are only returned,
            %       but not stored.
            %   'PostOptimize': array of strings
            %       An array of strings, where each string must be a valid
            %       argument to the function `hz`. If provided, the
            %       `add_new_data` method will take all intermediary results and
            %       optimize them through the `hz` function. The best result
            %       (Along with the `hz` method that produced them) will be
            %       stored in the 'result' struct.
            %
            %   Notes
            %   -----
            %   To obtain a function handle, simply prepend the functions name
            %   with an @ sign.
            %   For example, to retrieve a function handle for the "dir"
            %   command:
            %
            %       f_handle = @dir
            arguments
                algorithm_handle (1, 1) function_handle
                algorithm_name (1, 1) string
                kvargs.StoreResults (1, 1) logical = true;
                kvargs.PostOptimize (1, :) string = [];
            end

            if contains(algorithm_name, " ")
                error("Algorithmenname darf keine Leerzeichen enthalten!");
            end

            self.algorithm = algorithm_handle;
            self.alg_name = algorithm_name;
            self.data_table = table('Size', [0, 6], 'VariableTypes', ...
                {'double', 'double', 'double', 'double', 'lhp.ProblemData', 'struct'}, ...
                'VariableNames', {'Index', 'AnzElem', 'Zeilen', 'Spalten', ...
                'ProblemData', char(self.alg_name)});
            self.StoreResults = kvargs.StoreResults;
            self.PostOptimize = kvargs.PostOptimize;
            self.current_index = 1;
        end

        function [index, results] = add_new_data(self, pdata, varargin)
            %% Create new data from the algorithm
            %
            %   Call the algorithm with varargin as parameters, and record the
            %   results in the internal data structures.
            %
            %   Parameters
            %   ----------
            %   self: lhp.algo.BaseWrapper
            %       An instance of this class
            %   pdata: lhp.ProblemData
            %       A definition of the problem that is to be solved
            %   varargin:
            %       An arbitrarily shaped list of arguments that is
            %       unpacked and passed to the algorithm as arguments.
            %
            %   Returns
            %   -------
            %   index: int
            %       The index under which this measurement is stored in the
            %       internal dataset (for access through get() method).
            %   results: struct
            %       A struct holding the results of the algorithm. This struct
            %       contains at least the costs (Harkarbeit, Wegearbeit,
            %       Transportarbeit, Gesamtkosten) and the successor-function.
            arguments
                self (1, 1) lhp.algo.BaseWrapper
                pdata (1, 1) lhp.ProblemData
            end
            arguments (Repeating)
                varargin
            end

            ze = size(pdata.Garden, 1);
            sp = size(pdata.Garden, 2);

            % Calculate whatever we require from the algorithm
            results = self.get_new_results(pdata, varargin);


            if ~self.StoreResults
                index = 0;
                return;
            end

            % Now that we have the results, let's store them accordingly.
            tb = table(self.current_index, ze * sp, ze, sp, pdata, results);
            tb.Properties.VariableNames = self.data_table.Properties.VariableNames;

            if isempty(self.data_table)
                self.data_table = tb;
            else
                self.data_table = [self.data_table; tb];
            end

            self.data_table = sortrows(self.data_table, {'Index', 'AnzElem', ...
                'Zeilen', 'Spalten'}, 'ascend');
            self.current_index = self.current_index + 1;

            % Assign return values.
            index = self.current_index - 1;
            return;
        end

        function ret = get(self, run, what, which)
            %% Access internal data.
            %
            %   Returns the internally stored data, depending on the specifier
            %   "what".
            %
            %   Parameters
            %   ----------
            %   self: lhp.algo.BaseWrapper
            %   run: int or 2-element vector of int, default: 0
            %       The index of the run whose data is to be returned. If a
            %       range is given (as a 2-element vector), return the data for
            %       all results that are within this (inclusive) range. Indexes
            %       can be obtained from the add_new_data() method.
            %       Pass 0 to retrieve values of all stored runs.
            %       Pass inf to retrieve only the most recent run.
            %   what: string, default: "All"
            %       A specifier that declares which data to get.
            %       Can be one of:
            %
            %       - "Kosten": Return the total cost that the algorithm
            %                   produced.
            %       - "Harkarbeit": Return the cost for raking.
            %       - "Wegearbeit": Return the cost for unproductive ways.
            %       - "Transportarbeit": Return the cost for transport.
            %       - "Nachfolger": Return the generated successor function.
            %       - "Zeit": Return the function execution time in seconds.
            %       - "Pop": Return the produced population (Genetic only).
            %       - "All": Return all stored data as table.
            %       - "ProblemData": Return the ProblemData used for a given run
            %       - "AnzElem": Return number of elements in specific garden
            %       - "Index": Return the running index
            %   which: string, default: "Best"
            %       A string that further details which data to return. This is
            %       only relevant for algorithms that generate more than one
            %       result to a given garden (like the genetic algorithm!).
            %       Can be one of:
            %
            %       - "Best": Return results for the algorithm that had the
            %         least total cost ("Kosten")
            %       - "Worst": Return results for the algorithm that had the
            %         highest total cost ("Kosten")
            %       - "Average": Return the mean of all results.
            %       - "Deviation": Return the standard deviation of all results.
            %       - "All": Return all of the filtered results.
            %
            %   Returns
            %   -------
            %   ret:
            %       The result as filtered by the arguments given. Note that
            %       when calling for matrices of values (i.e. when "which" is
            %       "All"), each row represents the result of one round in the
            %       monte-carlo simulation, and each column represents one
            %       garden size.
            arguments
                self (1, 1) lhp.algo.BaseWrapper
                run (:, :) double {mustBeNonnegative(run)} = 0;
                what (1, 1) string {mustBeMember(what, ["Kosten", ...
                    "Harkarbeit", "Wegearbeit", "Transportarbeit", ...
                    "Nachfolger", "Zeit", "Pop", "All", ...
                    "ProblemData", "AnzElem", "Index"])} = "All";
                which (1, 1) string {mustBeMember(which, ["Best", ...
                    "Worst", "Average", "Deviation", "All"])} = "Best";
            end

            % If user specified only an index, return the subtable for index.
            if nargin == 1
                ret = self.data_table;
                return;
            end

            % Catch illegal combinations of parameters.
            if any(strcmpi(what, ["Nachfolger", "Pop", "ProblemData", ...
                    "AnzElem", "Index"]))
                if any(strcmpi(which, ["Average", "Deviation"]))
                    error_str = "Invalid parameter combination!\n" ...
                        + "  Asking for the %s of %s is not possible!\n";
                    error(error_str, which, what);
                end
            end

            % Determine the range of indexes to extract from the table
            if (run == 0) % Get all data
                subtable = self.data_table;
            elseif isinf(run)
                % Table is always sorted, so last run is last row in table.
                subtable = self.data_table(end, :);
            else
                if isscalar(run)
                    run = [run, run];
                end
                index = (self.data_table.Index >= run(1)) & ...
                    (self.data_table.Index <= run(2));
                subtable = self.data_table(index, :);
            end

            % Collect the specified data.
            % Some branches return early, because operations such as "mean"
            % don't apply to these.
            num_gardens = size(subtable, 1);
            switch what
                case "Kosten"
                    ret = reshape([subtable{:, self.alg_name}.K], ...
                        num_gardens, []);
                case "Harkarbeit"
                    ret = reshape([subtable{:, self.alg_name}.HA], ...
                        num_gardens, []);
                case "Wegearbeit"
                    ret = reshape([subtable{:, self.alg_name}.WA], ...
                        num_gardens, []);
                case "Transportarbeit"
                    ret = reshape([subtable{:, self.alg_name}.TA], ...
                        num_gardens, []);
                case "Nachfolger"
                    ret = reshape({subtable{:, self.alg_name}.s}, ...
                        num_gardens, []);
                case "Zeit"
                    ret = reshape([subtable{:, self.alg_name}.time], ...
                        num_gardens, []);
                case "Pop"
                    if ~isa(self, "lhp.algo.StochasticWrapper")
                        %This property only exists for Genetic algorithms!
                        ret = [];
                        return;
                    end
                    ret = reshape([subtable{:, self.alg_name}.pop], ...
                        num_gardens, []);
                    return;
                case "All"
                    ret = subtable;
                    return;
                case "ProblemData"
                    ret = subtable{:, "ProblemData"};
                    return;
                case "AnzElem"
                    ret = [subtable{:, "AnzElem"}];
                    return;
                case "Index"
                    ret = [subtable{:, "Index"}];
                    return;
                otherwise
                    error("Unknown parameter %s!\n", what);
            end
            ret = ret';

            % Do data aggregation.
            switch which
                case "Best"
                    % Get the runs which had the lowest total cost, respectively
                    [~, min_idx] = min(self.get(run, "Kosten", "All"), ...
                        [], 1);
                    ret = ret(sub2ind(size(ret), min_idx, 1:num_gardens));
                case "Worst"
                    % Get the runs which had the highest total cost, respectively
                    [~, max_idx] = max(self.get(run, "Kosten", "All"), ...
                        [], 1);
                    ret = ret(sub2ind(size(ret), max_idx, 1:num_gardens));
                case "Average"
                    ret = mean(ret, 1);
                case "Deviation"
                    ret = std(ret, 0, 1);
                case "All"
                    return;
                otherwise
                    error("Unknown parameter %s!\n", which);
            end

            return;
        end

        function plot(self, canvas, what)
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
            %       to. Usually of type axes.
            %   what: string
            %       Specify, what data to plot to the canvas. This can either
            %       be:
            %
            %       'Kosten'            Gesamtkosten
            %       'Harkarbeit'        Kosten fuer das Harken
            %       'Wegearbeit'        Kosten unproduktiver Wege
            %       'Transportarbeit'   Kosten fuer den Transport
            %       'Zeit'              Ausfuehrungsdauer
            %
            arguments
                self (1, 1) lhp.algo.BaseWrapper
                canvas (1, 1)
                what (1, 1) string {mustBeMember(what, ["Kosten", "Harkarbeit", ...
                    "Wegearbeit", "Transportarbeit", "Zeit"])}
            end

            self.make_plot(canvas, what);
        end

        function print(self, run, fd)
            %% Print the current instance to some output
            %
            %   Takes the current instance of ProblemData and prints its
            %   contents to some output device. This can either be a file or
            %   any kind of file descriptor, that is compatible with fprintf.
            %
            %   Parameters
            %   ----------
            %   self: ProblemData
            %   run: int
            %       The run for which the data should be printed. A "run" is
            %       characterized by the Index (Column "Index" in
            %       the return value of get()).
            %   fd: int
            %       Any valid file descriptor. Pass 1 or leave empty to print to
            %       stdout (MATLAB Command Window).
            arguments
                self (1, 1) lhp.algo.BaseWrapper
                run (1, 1) double {mustBeNonnegative}
                fd (1, 1) double = 1;  % To write to stdout
            end

            s = self.get(run, "Nachfolger");
            s = s{:};

            fprintf(fd, "# Algorithmus %s\n\n", self.alg_name);
            fprintf(fd, "  - Nachfolgerfunktion (s):\n");
            compartment_length = 14;
            for i = 1:14:size(s, 1)
                idx_st = i;
                idx_end = min(i + compartment_length - 1, size(s, 1));
                fprintf(fd, "    | %s\n", strjoin(compose("%2d |", ...
                    s(idx_st:idx_end, 1))));
                fprintf(fd, "    +%s\n", strjoin(repmat("----+", 1, ...
                    idx_end - idx_st + 1), ""));
                fprintf(fd, "    | %s\n", strjoin(compose("%2d |", ...
                    s(idx_st:idx_end, 2))));
                fprintf(fd, "\n");
            end
            fprintf(fd, "\n");
            fprintf(fd, "  - Kosten:\n");
            fprintf(fd, "    - Harkarbeit:      %2d\n", ...
                self.get(run, "Harkarbeit"));
            fprintf(fd, "    - Wegearbeit:      %2d\n", ...
                self.get(run, "Wegearbeit"));
            fprintf(fd, "    - Transportarbeit: %2d\n", ...
                self.get(run, "Transportarbeit"));
            fprintf(fd, "    - Gesamtarbeit:    %2d\n", ...
                self.get(run, "Kosten"));
            fprintf(fd, "\n\n");
        end

        function clear(self)
            %% Clear the data inside the table.
            %
            %   Clear all the contents of the results table. After calling this
            %   function, calls to get() return an empty table.
            self.data_table(:, :) = [];
            self.current_index = 1;
        end

        function name = get_name(self, style)
            %% Get the (algorithm) name of this BaseWrapper instance
            %
            %   Parameters
            %   ----------
            %   style: string
            %       Can be one of:
            %
            %       - 'Regular': Return the name as is (default)
            %       - 'Latex': Return the name formatted as Latex. Replaces all
            %         "-" (dashes) with " " (spaces), and converts all "_"
            %         (underscores) to "_{...}", where the closing bracket is
            %         placed before the next "-" or "_".
            arguments
                self (1, 1) lhp.algo.BaseWrapper
                style (1, :) string {mustBeMember(style, ["Regular", "Latex"])} ...
                    = "Regular";
            end

            if strcmpi(style, "Regular")
                % No processing requested.
                name = self.alg_name;
                return;
            end

            % Get the base name
            name = self.alg_name;
            name = strrep(name, "-", " ");
            name = char(name); % To allow array manipulation on members.

            spaces = strfind(name, " ");
            spaces(end+1) = strlength(name)+1; % To ensure termination
            underscores = strfind(name, "_");
            delim = sort([spaces, underscores]);

            for idx = numel(underscores):-1:1
                from = underscores(idx);
                % Replace to next "-" or "_" in the name
                to = delim(find(delim > underscores(idx), 1, "first"));

                name = strcat(name(1:from), '{', name(from+1:to-1), '}', ...
                        name(to:end));
            end

            name = string(name);
        end

        function disp(self)
            %% Override default command-window display
            %
            %   Override Matlabs default formatting when printing information
            %   about `BaseWrapper` and derivatives in the CommandWindow. The
            %   printed results can be enriched by BaseWrappers child classes
            %   by overriding the "get_disp_info" abstract method.
            %
            %   If called on a scalar instance of this class or any subclass,
            %   detailed information is displayed. If called on arrays of this
            %   class, an "overview" is shown instead.
            if ~isscalar(self)
                link = sprintf('<a href="matlab:help %1$s">%1$s</a>', ...
                    class(self));
                fprintf("  %dx%d array of %s\n", size(self), link);
                fprintf("\n");
            else
                base_str = [...
                    "Algorithm name", self.get_name("Latex");
                    "Function handle", strcat("@", func2str(self.algorithm))];
                longest_str = max(strlength(base_str(:, 1)));

                for str_idx = 1:size(base_str, 1)
                    fprintf("   %*s: %s\n", longest_str, base_str(str_idx, 1), ...
                        base_str(str_idx, 2));
                end

                if ~self.StoreResults
                    fprintf("   STORAGE IS DISABLED!\n");
                else
                    fprintf("   %*s: %d\n", longest_str, "Stored Results", ...
                        self.current_index - 1);
                end
                fprintf("\n");

                child_strs = self.get_disp_info();
                if ~isempty(child_strs)
                    fprintf(" ---- Additional Properties ----\n");
                    longest_str = max(strlength(child_strs(:, 1)));

                    for str_idx = 1:size(child_strs, 1)
                        fprintf("   %*s: %s\n", longest_str, child_strs(str_idx, 1), ...
                            child_strs(str_idx, 2));
                    end
                    fprintf("\n");
                end
            end

            helplink = sprintf('<a href="matlab:help %1$s">Help</a>', ...
                class(self));
            doclink = sprintf('<a href="matlab:doc %1$s">Documentation</a>', ...
                class(self));
            fprintf("   [%s]  [%s]\n", helplink, doclink);
            fprintf("\n");
            return;
        end
    end

    methods (Abstract, Access=protected)
        get_new_results(self, pdata, fargs)
            %% Execute the algorithm and store given results
            %
            %   Parameters
            %   ----------
            %   self: lhp.algo.BaseWrapper
            %       An instance of this class.
            %   pdata: ProblemData
            %       A definition of the problem that is to be solved
            %   fargs: cell array
            %       An arbitrary argument list that is passed to the algorithm
            %       to be executed.
            %
            %   Returns
            %   -------
            %   struct
            %       A struct that contains at least the fields "HA", "WA",
            %       "TA", "K" and "s" for the various algorithm costs as
            %       returned by kostenrechnung() and the successor function s.
            %       Can be extended by further more specific fields.

        make_plot(self, canvas, what)
            %% Create a plot.
            %
            %   Parameters
            %   ----------
            %   self: lhp.algo.BaseWrapper
            %   canvas:
            %       Some "canvas" to create the plot on. Usually plot axes.
            %   what:
            %       A string specifier as accepted by get() that specifies the
            %       data to plot.

        get_disp_info(self)
            %% Get additional info to print upon disp()
            %
            %   Returns
            %   -------
            %   A matrix of size n x 2, where each entry in the first column
            %   will be printed before a colon, after which the second entry is
            %   printed.
    end
end

