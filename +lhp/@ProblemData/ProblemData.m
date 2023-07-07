classdef ProblemData
    %PROBLEMDATA Class to store problem and solver parameters.
    %       author: kabdelhak

    % These parameters are not to be tampered with by the user!
    properties (SetAccess = private)
        Garden;             % Original matrix data
        GMatrix;            % Data structure used in surrounding program
        Adjacency;          % Original adjacency matrix
        WAdjacency;         % Weighted adjacency matrix
        DMatrix;            % Original distance matrix for all nodes
        Target;             % Original target node index
    end

    properties
        Start;              % Original start node index
        Max_Val;            % Maximum value allowed for each node
        Max_Trans;          % Maximum value allowed for transportation

        Rake_Param;         % Cost parameter for raking
        Unprod_Param;       % Cost parameter for unproductive time
        Trans_Param;        % Cost parameter for transportation
    end

    properties (SetAccess = private)
        % The "cost" of moving across cells diagonally in the distance matrix.
        % 0 or Inf means: Don't move diagonally
        DiagonalWeight = 1;
        % Signals if this instance is flattened or not.
        flattened = false;
    end

    methods
        %% Constructors
        function self = ProblemData(ze, sp, kvargs)
        %MAKE_PDATA Create and instantiate a ProblemData object.
        %
        %   This function takes as argument the number of rows and the number of
        %   columns that a garden should have and, based on these inputs,
        %   creates a new randomized garden along with the default parameters
        %   that are required to solve the "garden" problem.
        %
        %   The return value is an instance of ProblemData. This function mainly
        %   serves as convenienvce function and as a single point of entry for
        %   all functions that need ProblemData instances. Using this
        %   centralized approach, changes and bugfixes to the creation process
        %   affect all algorithms that rely on this function.
        %
        %   Parameters
        %   ----------
        %   ze: int > 0
        %       The number of rows the garden should have. Set to some arbitrary
        %       value when manually passing the garden to use. Value will update
        %       accordingly.
        %   sp: int > 0
        %       The number of columns the garden should have. Set to some
        %       arbitrary value when manually passing the garden to use. Value
        %       will update accordingly.
        %
        %   Keyword Arguments
        %   -----------------
        %   'MaxLaub'   : int, default: 25
        %       The maximum amount of leaves that one garden cell can carry
        %   'MaxLade'   : int, default: 25
        %       The maximum amount of leaves that can be transported
        %   'HarkParam' : double, default: 1
        %       The cost for raking one unit of leaves for a distance of one cell
        %   'WegeParam' : double, default: 1
        %       The cost of walking unproductive distances ("Unproduktive Wege")
        %   'TransParam': double, default: 1
        %       The cost of transporting one unit of leaves to the compost.
        %   'Kompost'   : 2-element vector of int, default: [0, 0]
        %       The location (coordinates) of the compost within the garden. If
        %       [0, 0] is provided, the cell with a value of (-10) is assumed to
        %       be the compost.
        %   'Start'     : 2-element vector of int, default: [0, 0]
        %       The location (coordinates) of the starting point from which the
        %       problem is solved. If [0, 0] is provided, some cell is selected
        %       at random. If the garden contains a shed (cells with value -1),
        %       the start node is located in the shed (such that it is
        %       accessible from the garden surrounding it). If no cell exists
        %       that is in the shed and accessible from the garden, the start
        %       node is placed randomly in the garden instead.
        %   'Garten'    : matrix of int
        %       The garden matrix that is to be solved. *Please read the Notes
        %       below!*
        %       Default: Generate one through `zufaelligerGarten.m`.
        %   'Export': logical, default: false
        %       If set to true, export the generated garden into a file.
        %   'DiagonalWeight': double, default: 1.4142
        %       The cost for walking over fields diagonally. Set to inf to
        %       prohibit walking diagonally entirely. Set to sqrt(2) for
        %       euclydian distance (default).
        %
        %   Returns
        %   -------
        %   pdata: ProblemData
        %       A valid instance of ProblemData that contains the specified data.
        %
        %   Notes
        %   -----
        %   **Some notes about using the "Garten" Parameter**:
        %   This parameter can be used to create a ProblemData instance for a
        %   given, pre-defined garden. When using a pre-defined garden, you
        %   must make sure that the garden is valid by yourself!
        %   Also: Note that the location of the compost is determined by a cell
        %   with value (-10). If this is not present in your garden, you must
        %   specify the location of the compost as a key-value argument, too!
        %   Finally, it is not possible to "skip" the ze and sp parameters,
        %   these must be supplied! However, when passing in an existing
        %   garden, they are ignored. For this reason, just set them to a value
        %   of "10", they will be updated accordingly.
            arguments
                ze (1, 1) double {mustBePositive, mustBeInteger}
                sp (1, 1) double {mustBePositive, mustBeInteger}
                % Optional arguments
                kvargs.MaxLaub (1, 1) double {mustBePositive, ...
                    mustBeInteger} = 25;
                kvargs.MaxLade (1, 1) double {mustBePositive, ...
                    mustBeInteger} = 25;
                kvargs.HarkParam (1, 1) double {mustBeNonnegative} = 1;
                kvargs.WegeParam (1, 1) double {mustBeNonnegative} = 1;
                kvargs.TransParam (1, 1) double {mustBeNonnegative} = 1;
                kvargs.Kompost (1, 2) double {mustBeNonnegative, ...
                    mustBeInteger} = [0, 0];
                kvargs.Start (1, 2) double {mustBeNonnegative, ...
                    mustBeInteger} = [0, 0];
                kvargs.Garten (:, :) lhp.Garden
                kvargs.Export (1, 1) logical = false;
                kvargs.DiagonalWeight (1, 1) double {mustBeNonnegative} = 1.4142;
            end

            if isfield(kvargs, "Garten")
                G = kvargs.Garten;
            else
                % When generating a garden, we must make sure that the amount of leaves
                % in all cells is valid!
                ctr = 0;
                while true
                    G = lhp.Garden.random(ze, sp, "Export", kvargs.Export);
                    if any(G > kvargs.MaxLaub)
                        ctr = ctr + 1;
                        % Make a maximum of 10 attempts to generate a garden!
                        if ctr == 10
                            error("Couldn't generate a garden of size [%2d, %2d]" ...
                                + " that satisfies MaxLaub == %d\n", ze, sp, kvargs.MaxLaub);
                        end
                    else
                        break;
                    end
                end
            end

            % Set the weight of diagonal movement here so that it can be
            % considered when e.g. checking  whether or not a cell is isolated!
            self.DiagonalWeight = kvargs.DiagonalWeight;

            GMatrix = G.make_gmatrix();
            Start = G.get_start(kvargs.Start);

            if all(kvargs.Kompost == 0)
                ind = (GMatrix(:, 4) == lhp.Garden.CELL_COMPOST.value);  % Get compost field
                assert(nnz(ind) == 1, "Found %d compost fields, expected 1!\n", nnz(ind));
                Kompost = GMatrix(ind, 1:2);
            elseif any(kvargs.Kompost == 0)
                error("Cannot use '0' as coordinate for either row or" + ...
                    " column of the compost field!");
            else
                Kompost = kvargs.Kompost;
            end
            % Must make sure that compost isn't isolated!
            assert(~G.is_isolated(Kompost), ...
                "Compost at (%d, %d) is isolated!\n", ...
                Kompost(1), Kompost(2));

            % Actually set the compost, too.
            G.Raw(Kompost(1), Kompost(2)) = lhp.Garden.CELL_COMPOST.value;
            % Ensure that the garden is still valid now!
            if ~G.is_valid("DiagonalMovements", ~isinf(kvargs.DiagonalWeight))
                error("Compost at (%d, %d) would split garden into " ...
                    + "two parts!\n", Kompost(1), Kompost(2));
            end
            % Algorithms expect compost to be a scalar value
            Kompost = G.sub2ind(Kompost(1), Kompost(2));

            self.Target = Kompost;
            self.Start = Start;

            self = self.setGarden(G);

            self.Max_Val = kvargs.MaxLaub;
            self.Max_Trans = kvargs.MaxLade;
            self.Rake_Param = kvargs.HarkParam;
            self.Unprod_Param = kvargs.WegeParam;
            self.Trans_Param = kvargs.TransParam;

            return;
        end

        %% Setters and Getters for Properties
        function self = set.Start(self, Start)
            arguments
                self (1, 1) lhp.ProblemData
                Start (1, 1) double {mustBePositive(Start)}
            end

            % If PData was flattened before restoring, Adjacency will be empty
            % and thus we just assume that the Start node is valid.
            if self.is_flattened() || isempty(self.Adjacency)
                self.Start = Start;
                return;
            end

            % Check that the Start node is somehow accessible
            if any((self.DMatrix(Start, :) > 0) & ~isinf(self.DMatrix(Start, :)))
                if (Start == self.Target)
                    error("Start can't be equal to Target!");
                end
                self.Start = Start;
            else
                error("Startnode %d doesn't have free neighbor cells!\n", ...
                    Start);
            end
        end

        function self = set.Max_Val(self, Max_Val)
            arguments
                self (1, 1) lhp.ProblemData
                Max_Val (1, 1) double {mustBePositive}
            end

            self.Max_Val = Max_Val;
        end

        function self = set.Max_Trans(self, Max_Trans)
            arguments
                self (1, 1) lhp.ProblemData
                Max_Trans (1, 1) double {mustBePositive}
            end

            self.Max_Trans = Max_Trans;
        end

        function self = set.Rake_Param(self, Rake_Param)
            arguments
                self (1, 1) lhp.ProblemData
                Rake_Param (1, 1) double {mustBeNonnegative}
            end

            self.Rake_Param = Rake_Param;
        end

        function self = set.Unprod_Param(self, Unprod_Param)
            arguments
                self (1, 1) lhp.ProblemData
                Unprod_Param (1, 1) double {mustBeNonnegative}
            end

            self.Unprod_Param = Unprod_Param;
        end

        function self = set.Trans_Param(self, Trans_Param)
            arguments
                self (1, 1) lhp.ProblemData
                Trans_Param (1, 1) double {mustBeNonnegative}
            end

            self.Trans_Param = Trans_Param;
        end

        function print(self, fd)
            %% Print the current instance to some output
            %
            %   Takes the current instance of ProblemData and prints its
            %   contents to some output device. This can either be a file or
            %   any kind of file descriptor, that is compatible with fprintf.
            %
            %   Parameters
            %   ----------
            %   self: lhp.ProblemData
            %   fd: int
            %       Any valid file descriptor. Pass 1 or leave empty to print to
            %       stdout (MATLAB Command Window).
            arguments
                self (1, 1) lhp.ProblemData
                fd (1, 1) double = 1;  % To write to stdout
            end

            fprintf(fd, "\n\n####### AKTUELLES PROBLEM #######\n\n");
            fprintf(fd, "# Der Garten:\n");
            table_width = size(self.Garden, 2);
            fprintf(fd, "%s+\n", join(repmat("+---", 1, table_width), ""));

            for line = 1:size(self.Garden, 1)
                values = self.Garden(line, :);
                out = "|";
                for val = values
                    if val == lhp.Garden.CELL_COMPOST.value
                        % Give more space to the compost to keep formatting
                        % intact.
                        out = out + sprintf("%3d|", val);
                    else
                        out = out + sprintf("%2d |", val);
                    end
                end
                fprintf(fd, "%s\n", out);
                fprintf(fd, "%s+\n", join(repmat("+---", 1, table_width), ""));
            end

            % Get the coordinates for a scalar index. Note that we must swap the
            % results since we count the scalar index rows-first, matlab counts
            % columns-first.
            [a, b] = ind2sub(size(self.Garden), self.Start);
            fprintf(fd, "\n# Die Parameter:\n");
            fprintf(fd, "  - Startpunkt: %3d -- (%d, %d)\n", self.Start, b, a);
            [a, b] = ind2sub(size(self.Garden), self.Target);
            fprintf(fd, "  - Kompost:    %3d -- (%d, %d)\n", self.Target, b, a);
            fprintf(fd, "  - Maximale Laubmenge pro Feld:   %2d\n", self.Max_Val);
            fprintf(fd, "  - Maximale Transportmenge:       %2d\n", self.Max_Trans);
            fprintf(fd, "  - Kosten fuer das Harken:         %4.3f\n", self.Rake_Param);
            fprintf(fd, "  - Kosten fuer unproduktive Wege:  %4.3f\n", self.Unprod_Param);
            fprintf(fd, "  - Kosten fuer Transport:          %4.3f\n", self.Trans_Param);
            fprintf(fd, "\n\n");
        end

        function fh = plot(self, ax, kvargs)
            %% Plot the current garden.
            %
            %   This method plots the current garden as a heatmap to a given
            %   axis.
            %
            %   Parameters
            %   ----------
            %   self: lhp.ProblemData
            %   ax: matlab.graphics.axis.Axes
            %       The axis that the plot should be created on. If no axis is
            %       given, a new figure will be created instead.
            %
            %   Keyword Arguments
            %   -----------------
            %   'TreatBlockedAsNan': logical, default: false
            %       If set to true, all blocked fields in the garden
            %       (value < 1) will be set to NaN before plotting. This way
            %       blocked fields can easily be distinguished from regular
            %       fields, although the ability to differentiate between
            %       different 'types' of blockade is lost.
            %
            %   Returns
            %   -------
            %   fh: matlab.graphics.chart.HeatmapChart
            %       A handle to the newly created heatmap chart.
            arguments
                self (1, 1) lhp.ProblemData
                ax (1, 1) matlab.graphics.axis.Axes = axes();
                kvargs.TreatBlockedAsNan (1, 1) logical = false;
            end

            if kvargs.TreatBlockedAsNan
                fh = self.Garden.plot(ax, 'BlockedCellColors', []);
            else
                fh = self.Garden.plot(ax);
            end
            return;
        end

        function self = flatten(self)
        %%FLATTEN Flatten this instance of ProblemData
        %
        %   Removes all structures and member variables from PData that can be
        %   derived (in some way) from the data that is stored. Currently, this
        %   includes the member variables 'GMatrix', 'DMatrix' and 'Adjacency'.
        %   All of these can be derived (when needed) from the 'Garden' member
        %   (which is the garden they are calculated for).
        %   This method aids in reducing the storage need for ProblemData
        %   Objects. It has been determined that for gardens of about 30 x 30
        %   cells in size, the required memory for 'GMatrix', 'DMatrix' and
        %   'Adjacency' makes up 99.88 % of the total memory consumption of
        %   ProblemData.
            self.GMatrix = [];
            self.DMatrix = [];
            self.Adjacency = [];
            self.WAdjacency = [];
            self.flattened = true;
        end

        function self = unflatten(self)
        %%UNFLATTEN Restore this instance of ProblemData
        %
        %   Recreate all data structures that were removed by the flatten()
        %   method to save memory space.
            self = self.has_updated("Garden");
            self.flattened = false;
        end

        function bool = is_flattened(self)
            bool = self.flattened;
            return;
        end

    end

    methods(Access=private)
        function self = has_updated(self, what)
            %% Notify that internal properties updated.
            %
            %    This method makes sure that all internal properties that are
            %    dependent on each other are updated properly when one of them
            %    changes. This will aid in preventing reconstructing the whole
            %    object if a single parameter changes.
            %
            %   The property that has changed and causes other properties to
            %   update is specified in "what".
            switch (what)
                case "Garden"
                    self = self.setGMatrix();
                    self = self.setAdjacency();
                    self = self.setDMatrix();
                otherwise
                    % PASS
            end
        end

        function self = setGarden(self, Garden)
            arguments
                self (1, 1) lhp.ProblemData
                Garden (:, :) lhp.Garden
            end

            % Apply sanity checks
            if ~isempty(self.Start)
                if ((Garden(self.Start) < 0) && ~Garden.is_in_shed(self.Start))
                    % Cell is blocked! Must update start!
                    self.Start = self.getStartNode();
                    warning("Start node has been updated to ensure it is" ...
                        + " not inside a blocked cell!");
                end
            end

            if ~isempty(self.Target)
                if Garden(self.Target) ~= lhp.Garden.CELL_COMPOST.value
                    % Compost cell value isn't -10!
                    Garden(Garden == lhp.Garden.CELL_COMPOST.value) = randi( ...
                        [min(Garden.Raw(Garden >= 0)), max(Garden.Raw)]);
                    [t_z, t_s] = Garden.ind2sub(self.Target);
                    Garden.Raw(t_z, t_s) = lhp.Garden.CELL_COMPOST.value;
                    warning("Adapted Compost node value.");
                end
            end

            if ~isempty(self.Max_Val)
                if max(Garden.Raw) > self.Max_Val
                    error("Maximum amount of leaves (%d) in this garden" ...
                        + " is bigger than configured maximum (%d)!\n", ...
                        max(Garden.Raw), self.Max_Val);
                end
            end

            self.Garden = Garden;
            self = self.has_updated("Garden");
        end

        function self = setGMatrix(self)
            %% Calculate updated GMatrix from current garden.
            self.GMatrix = self.Garden.make_gmatrix();
        end

        function self = setAdjacency(self)
            %% Calculate updated Adjacency from current garden.
            if isempty(self.GMatrix)
                error("Can't calculate Adjacency when garden is missing!");
            end

            self.Adjacency = self.Garden.make_adjacency(...
                "Start", self.Start, "Kompost", self.Target);
            self.WAdjacency = self.Adjacency;
            % Apply diagonal weights to adjacency matrix
            % Consider the weights for diagonal connections
            % Diagonals are located at:
            %     (-w) - 1
            %     (-w) + 1
            %       w  - 1
            %       w  + 1
            % where w = garden width
            % Get garden width
            width = size(self.Garden, 2);
            n = size(self.WAdjacency, 1);
            % Select fields that must be weighted
            diag_cells = diag(ones(n - width - 1, 1), - width - 1) + ...
                         diag(ones(n - width + 1, 1), - width + 1) + ...
                         diag(ones(n - width + 1, 1), + width - 1) + ...
                         diag(ones(n - width - 1, 1), + width + 1);
            % Unselect fields that don't exist in Adjacency
            diag_cells = diag_cells & self.WAdjacency;
            % Apply the weights
            self.WAdjacency(diag_cells) = self.DiagonalWeight;
        end

        function self = setDMatrix(self)
            %% Calculate updated distance matrix from current garden.
            self.DMatrix = self.Garden.make_distances(self.Adjacency, ...
                "DiagonalWeight", self.DiagonalWeight);

            % Remove compost from adjacency matrix after computing the
            % distance matrix
            ind = (self.GMatrix(:, 4) == lhp.Garden.CELL_COMPOST.value);
            self.Adjacency(self.GMatrix(ind, 3), :) = 0;
            self.Adjacency(:, self.GMatrix(ind, 3)) = 0;

            % Remove start node from adjacency matrix in case it's blocked (e.g.
            % in the shed)
            if (self.GMatrix(self.Start, 4) < 0)
                self.Adjacency(self.Start, :) = 0;
                self.Adjacency(:, self.Start) = 0;
            end
        end
    end

    methods (Access = {?lhp.TestManager})
        % These methods can only be accessed by the TestManager!

        function self = inflate(self, DMatrix, Adjacency, GMatrix)
            %% INFLATE: Populate DMatrix, Adjacency and GMatrix from outside.
            %
            %   This method is meant as a way of accelerating the "unflattening"
            %   process when used in conjunction with the TestManager class.
            %   Since the TestManager usually holds many different tests that
            %   all have the same structural parameters (i.e. the garden and
            %   compost are the same), their DMatrix, Adjacency and GMatrix will
            %   be equal, too. In such cases there is no need to unflatten each
            %   ProblemData on it's own, since all of them will do the same
            %   calculations.
            %   Since the mentioned properties are read-only from outside,
            %   however, this method is needed to "feed" pre-existing values
            %   into the ProblemData class.
            %
            %   Note
            %   ----
            %   This method is meant **only** for use from the TestManager
            %   class.
            %
            %   Parameters
            %   ----------
            %   DMatrix: matrix of double
            %       The distance matrix for this ProblemData instance.
            %   Adjacency: matrix of double
            %       The adjacency matrix for this ProblemData instance.
            %   GMatrix: matrix of double
            %       The GMatrix for this ProblemData instance.
            %
            %   Returns
            %   -------
            %   self: ProblemData
            %       A populated version of this ProblemData instance.
            arguments
                self (1, 1) lhp.ProblemData
                DMatrix (:, :) double
                Adjacency (:, :) double
                GMatrix(:, 4) double
            end

            %% Sanity check the parameters
            % Check for matrix dimension to be correct
            garden_size = numel(self.Garden);

            assert(isequal(garden_size, size(DMatrix, 1)), ...
                "DMatrix has invalid size!");
            assert(isequal(garden_size, size(DMatrix, 2)), ...
                "DMatrix has invalid size!");

            assert(isequal(garden_size, size(GMatrix, 1)), ...
                "GMatrix has invalid size!");

            assert(isequal(garden_size, size(Adjacency, 1)), ...
                "Adjacency has invalid size!");
            assert(isequal(garden_size, size(Adjacency, 2)), ...
                "Adjacency has invalid size!");

            % Check that obstacles are at the expected locations.
            obstacles = reshape((self.Garden' < 0), garden_size, 1);

            % Note that the compost is by definition accessible!
            assert(DMatrix(self.Target, self.Target) == 0, ...
                "Compost in DMatrix is at wrong position!");
            DMat_selection = DMatrix(obstacles, obstacles);
            compost_index = sum(obstacles(1:self.Target));
            DMat_selection(compost_index, compost_index) = Inf;
            assert(all(isinf(DMat_selection), "all"), ...
                "DMatrix has obstacles at invalid locations!");

            assert(all(GMatrix(obstacles, 4) < 0, "all"), ...
                "GMatrix has obstacles at invalid locations!");

            assert(all(Adjacency(obstacles, :) == 0, "all"), ...
                "Adjacency has obstacles at invalid locations!");

            % Take the values.
            self.DMatrix = DMatrix;
            self.GMatrix = GMatrix;
            self.Adjacency = Adjacency;

            return;
        end
    end
end

