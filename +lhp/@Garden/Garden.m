classdef Garden
    %GARDEN Define a garden structure.
    %
    %   Manages garden matrices and associated operations.
    %
    %   Caution
    %   -------
    %   Due to the way this class is written, and due to the fact that the whole
    %   indexing with `subsref` has been overloaded, it is **NOT** possible to
    %   override the value of single or multiple garden cells using a syntax
    %   like:
    %
    %   .. code:: matlab
    %
    %      G(row, col) = value;       % Doesn't work!
    %
    %   To achieve this, you **MUST** work on the `Raw` member directly, i.e.:
    %
    %   .. code:: matlab
    %
    %      G.Raw(row, col) = value;   % This works.

    properties
        % The garden matrix in its raw representation.
        Raw;
    end

    properties (Access = public, Constant)
        CELL_SHED = struct(...
                        "value", -1, ...
                        "color", [0.8, 0.8, 0.8], ...
                        "description", "Schuppen");
        CELL_TREE = struct(...
                        "value", -2, ...
                        "color", [0.52, 0.19, 0.05], ...
                        "description", "Baeume");
        CELL_COMPOST = struct(...
                        "value", -10, ...
                        "color", [0, 0, 0], ...
                        "description", "Kompost");
    end

    methods
        function self = Garden(matrix)
            %GARDEN Create Garden from a numeric matrix.
            self.Raw = matrix;
        end

        function varargout = subsref(self, sr)
            %%Garden object indexing.
            %
            %   This method implements the indexing via '()' parentheses into
            %   Garden objects. This allows the user to handle Garden objects as
            %   if they were the Raw garden matrices contained inside of them.
            %
            %   What's special about this method is that **it flips the linear
            %   indexing behavior**. By default, when indexing with a scalar
            %   into a matrix (linear indexing), matlab treats the matrix as if
            %   it were a vector with *all columns contatenated, from left to
            %   right, below each other*. However, the definition of the linear
            %   indexing in the project (see GMatrix) is flipped: We act as if
            %   the rows were concatenated. This method uses the flipped
            %   indexing!
            %
            %   For instructions on how to use it, please consult the Matlab
            %   documentation on `subsref`.
            %
            %   Notes
            %   -----
            %   If you're looking for instructions on how to improve/extend this
            %   (or a general explanation of what happens in the code), have a
            %   look here:
            %   https://www.mathworks.com/help/matlab/customize-object-indexing.html
            switch sr(1).type
                case '.'
                    % Use builtin indexing for members
                    [varargout{1:nargout}] = builtin('subsref',self,sr);
                case '()'
                    if numel(sr) == 1
                        if (numel(sr(1).subs) == 1)
                            raw_t = self.Raw';
                            varargout = {raw_t(sr(1).subs{1})};
                        elseif (numel(sr(1).subs) == 2)
                                varargout = ...
                                    {self.Raw(sr(1).subs{1}, sr(1).subs{2})};
                        else
                            error("Only 1-D or 2-D indexing is supported!");
                        end
                    else
                        error("Not a valid indexing expression");
                    end
                case '{}'
                    % Use builtin indexing
                    error("Brace indexing is not supported for variables" + ...
                        " of this type.");
                otherwise
                    error("Not a valid indexing expression");
            end
        end

        function nargs = numArgumentsFromSubscript(self, subs, ctx)
            %% Number of outputs from indexing expressions.
            %
            %   The number of outputs to various indexing expressions is usually
            %   derived from a call to `numel`, using the desired indexing
            %   operations target. As we override `numel` to return the size of
            %   the underlying `Raw` garden matrix, matlab is lead to assume
            %   that an indexing expression like this (in the command window)::
            %
            %       garden.Raw
            %
            %   will return `numel` individual variables, which is of course
            %   bogus, since we want the whole array as one answer. Thus we
            %   define this method to tell matlab when it is in error.
            switch subs(1).type
                case '.'
                    if numel(subs) == 1
                        % Directly indexing as self.<MEMBER>
                        nargs = 1;
                        return;
                    end
                otherwise
                    % Pass ...
            end
            nargs = builtin('numArgumentsFromSubscript', self, subs, ctx);
        end

        function varargout = size(self, varargin)
            %%Obtain the size of the underlying raw matrix.
            %
            %   Notes
            %   -----
            %   The overload of this method is the reason, why the size of
            %   `lhp.Garden` displays as the size of the Raw matrix in every
            %   possible location. This is a side-effect, but it's somewhat nice
            %   to have here, because the user can see at a glance how big a
            %   garden is.
            %   Care must be taken not to confuse a m*n-array of `lhp.Garden`
            %   for a multidimensional array of individual gardens, because that
            %   is not the case!
            [varargout{1:nargout}] = size(self.Raw, varargin{:});
        end

        function num = numel(self)
            % Overload to return number of elements of Raw matrix.
            num = numel(self.Raw);
        end

        function truefalse = eq(self, other)
            %%Equality operator.
            %
            %   If a numeric value is given as second argument, it performs a
            %   comparison of the raw matrix to the value. If another instance
            %   of `lhp.Garden` is given, it returns true only if all elements
            %   of the gardens match.
            if strcmp(class(self), class(other))
                if any(size(self.Raw) ~= size(other.Raw))
                    error("Cannot compare gardens of different size!");
                end
                truefalse = all(self.Raw == other.Raw, 'all');
                return;
            elseif isnumeric(other)
                truefalse = builtin('eq', self.Raw, other);
                return;
            else
                error("Cannot compare unlike datatypes!");
            end
        end

        function truefalse = ge(self, other)
            % >= operator on the Raw matrix
            truefalse = builtin('ge',self.Raw,other);
        end

        function truefalse = gt(self, other)
            % > operator on the Raw matrix
            truefalse = builtin('gt',self.Raw,other);
        end

        function truefalse = le(self, other)
            % <= operator on the Raw matrix
            truefalse = builtin('le',self.Raw,other);
        end

        function truefalse = lt(self, other)
            % < operator on the Raw matrix
            truefalse = builtin('lt',self.Raw,other);
        end

        function truefalse = ne(self, other)
            % ~= operator on the Raw matrix
            truefalse = builtin('ne',self.Raw,other);
        end

        function gtrans = transpose(self)
            % Return new Garden with transposed Raw matrix (')
            gtrans = lhp.Garden(self.Raw');
        end

        function gtrans = ctranspose(self)
            % Return new Garden with transposed Raw matrix (')
            gtrans = lhp.Garden(self.Raw');
        end

        function [row, col] = ind2sub(self, index)
            %%Convert a linear index into indices for row and column.
            assert(index > 0, "Index must be positive!");
            assert(index <= numel(self.Raw), ...
                "Index %d is out of range!", index);

            [col, row] = ind2sub(size(self.Raw'), index);
        end

        function ind = sub2ind(self, row, col)
            %%Convert indices for row and column to a linear index (row-wise).
            assert(nargin == 3, ...
                "You must provide row and column coordinates!");
            assert(row <= size(self, 1), ...
                "Row coordinate can't be bigger than %d!", size(self, 1));
            assert(col <= size(self, 2), ...
                "Col coordinate can't be bigger than %d!", size(self, 2));
            assert(row > 0, "Coordinates must be positive!");
            assert(col > 0, "Coordinates must be positive!");

            % Note: The arguments are "twisted" here, because the indexing is
            % "flipped"! Don't touch it or it breaks!
            ind = sub2ind(size(self.Raw'), col, row);
        end

        function [new_garden, tree_idx] = add_tree(self, amount, kvargs)
            arguments
                self (:, :) lhp.Garden
                amount (1, 1) double {mustBeNonnegative, mustBeInteger} = 0;
                kvargs.NoLeaves (1, 1) logical = false;
            end

            if amount == 0
                new_garden = self;
                return;
            end

            free_fields = find(self.Raw >= 0);
            % Sanity checks
            assert(amount < numel(free_fields), ...
                "Cannot place more trees than there are free fields" + ...
                " in this garden!");

            %% Tree foliage pattern.
            leave_pattern = [...
                1  1  1  1  1  1  1;
                1  2  2  2  2  2  1;
                1  2  4  4  4  2  1;
                1  2  4  0  4  2  1;
                1  2  4  4  4  2  1;
                1  2  2  2  2  2  1;
                1  1  1  1  1  1  1];
            % coordinates of topleft corner from the tree trunk
            tree_topleft = [-3, -3];
            % Make a copy of the garden
            new_garden = self;

            while amount > 0
                % Store modified version of the garden for next iteration
                old_garden = new_garden;
                was_valid = false;

                % Iterate over a permutation of all fields to find a fitting one
                for ff_idx = randperm(numel(free_fields))
                    new_garden = old_garden;

                    % Pick some field
                    tree_idx = free_fields(ff_idx);
                    [t_row, t_col] = ind2sub(self.size(), tree_idx);

                    % Place a tree there
                    if kvargs.NoLeaves
                        new_garden.Raw(t_row, t_col) = ...
                            lhp.Garden.CELL_TREE.value;
                    else
                        for row = 1:size(leave_pattern, 1)
                            foliage_row = t_row + row - 1 + tree_topleft(1);
                            if (foliage_row < 1) || (foliage_row > self.size(1))
                                % Out of bounds
                                continue;
                            end

                            for col = 1:size(leave_pattern, 2)
                                foliage_col = t_col + col - 1 + tree_topleft(2);
                                if (foliage_col < 1) || (foliage_col > self.size(2))
                                    % Out of bounds
                                    continue;
                                end

                                if new_garden.Raw(foliage_row, foliage_col) < 0
                                    % Already blocked
                                    continue;
                                end

                                cur_leaves = leave_pattern(row, col);
                                if cur_leaves > 0
                                    new_garden.Raw(foliage_row, foliage_col) = ...
                                        new_garden.Raw(foliage_row, foliage_col) ...
                                        + cur_leaves;
                                else
                                    new_garden.Raw(foliage_row, foliage_col) = ...
                                        lhp.Garden.CELL_TREE.value;
                                end
                            end
                        end
                    end

                    compost = find(new_garden' == -10);
                    if new_garden.is_valid() && ~new_garden.is_isolated(compost)
                        amount = amount - 1;
                        free_fields(ff_idx) = [];
                        was_valid = true;
                        break;
                    else
                        continue;
                    end
                end
                if ~was_valid
                    error("Couldn't find a place to put a tree" + ...
                        " in this garden!");
                end
            end
        end

        function is_valid = is_valid(self, kvargs)
            %% Validate if all fields in a garden are reachable.
            %
            %   Optional Key-Value Parameters
            %   -----------------------------
            %   'DiagonalMovements': logical
            %       Set to true, if diagonal movements are allowed in this
            %       garden. Set to false if only horizontal and vertical
            %       movement is allowed.
            %       default: true
            %
            %   Returns
            %   -------
            %   true if garden is valid (no blocked fields)
            %   false otherwise
            %
            %   Notes
            %   -----
            %   A garden is considered to be valid, if no fields/cells are
            %   blocked. To ensure this, the garden is recursively flooded from
            %   any given starting point. A negative value is written into each
            %   flooded field. After flooding has completed (respecting whether
            %   or not to flood diagonally, too), the garden is checked for
            %   fields with a value greater or equal to 0. If any such field
            %   exists, this field is isolated, since it cannot be reached. In
            %   this case, the garden is not valid.
            arguments
                self (:, :) lhp.Garden
                kvargs.DiagonalMovements (1, 1) logical = true;
            end

            % Get a valid starting point
            tmp = find(self.Raw >= 0);
            [x, y] = ind2sub(size(self.Raw), tmp(1));
            start = [x, y];

            comp = lhp.Garden.rec_validate(self.Raw, start, ...
                kvargs.DiagonalMovements);

            is_valid = ~any(comp >= 0, 'all');
            return;
        end

        function  adj = make_adjacency(self, kvargs)
            % Erstellen einer Adjazenzmatrix aus einer Knotenmatrix
            %
            % Autor: R. Derdau
            %
            % 8-angeschlossen Nachbarn::
            %
            %     1  - 2  -  3
            %     | X  |  X  |
            %     4  - 5  -  6
            %     | X  |  X  |
            %     7  - 8  -  9
            %
            % Nicht vorhandene Knoten muessen ggf. noch entfernt werden z.B.
            % Knoten 4::
            %
            %     adj(4,:)=0; adj(:,4)=0
            %
            % Diese Implementierung stimmt so. Man nehme folgendes Beispiel::
            %
            %     G = [1     2     3     1     4     3;
            %          2     3     1     2    -1     6;
            %          3     4     1     3     2     1;
            %          2     1    -1     4     3     3];
            %     ZE = 4;
            %     SP = 6;
            %
            % So kann man sich von Hand herbeifuehren, dass die Adjazenz bei
            % Zeilenweiser Betrachtung des Gartens wie folgt aussieht::
            %
            %        |  1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19
            %     ---+--------------------------------------------------------------------------
            %      1 |
            %      2 |      u   X               X   X   X
            %      3 |      X   u   X               X   X   X
            %      4 |          X   u   X               X   X
            %      5 |              X   u   X               X       X
            %      6 |                  X   u                       X
            %      7 |      X                   u   X                   X   X
            %      8 |      X   X               X   u   X               X   X   X
            %      9 |      X   X   X               X   u   X               X   X   X
            %     10 |          X   X   X               X   u                   X   X   X
            %     11 |                                          u
            %     12 |                  X   X                       u                   X   X
            %     13 |                          X   X                   u   X                   X
            %     14 |                          X   X   X               X   u   X               X
            %     15 |                              X   X   X               X   u   X
            %     16 |                                  X   X                   X   u   X
            %     17 |                                      X       X               X   u
            %     18 |                                              X                       u
            %     19 |                                                  X   X                   u
            %
            % Dabei markieren Felder mit einem u eine Beziehung zu sich selbst.
            % In der Inzidenzberechnung sind diese Felder "1", also wahr. In
            % diesem Skript sind sie es nicht.
            %
            % Ein X markiert eine vorhandene Nachbarschaftsbeziehung.
            arguments
                self (:, :) lhp.Garden
                kvargs.Start (:, 1) double {mustBePositive, mustBeInteger}
                kvargs.Kompost (1, 1) double {mustBePositive, mustBeInteger}
            end

            Zeilen = self.size(1);
            Spalten = self.size(2);
            GMatrix = self.make_gmatrix();

            % Erster Diagonalvektor (fuer horizontale Verbindungen)
            diagVec1 = repmat([ones(Spalten-1,1); 0],Zeilen,1);
            diagVec1 = diagVec1(1:end-1);
            % Zweiter Diagonalvektor (fuer anti-diagonale Verbindungen)
            diagVec2 = [0; diagVec1(1:(Spalten*(Zeilen-1)))];
            % Dritter Diagonalvektor (fuer vertikale Verbindungen)
            diagVec3 = ones(Spalten*(Zeilen-1),1);
            % Vierter Diagonalvektor (fuer diagonale Verbindungen)
            diagVec4 = diagVec2(2:end-1);
            % Diagonalen zu einer Null-Matrix addieren
            adj = diag(diagVec1,1) ...
                  + diag(diagVec2,Spalten-1) ...
                  + diag(diagVec3,Spalten) ...
                  + diag(diagVec4,Spalten+1);

            % Besetze Felder auf der Hauptdiagonalen
            adj = adj + eye(Zeilen * Spalten);
            % Entfernt alle Knoten, die nicht harkbar (blockiert) sind,
            % ausser dem Kompost und dem Start (falls vorhanden)
            ind = (GMatrix(:, 4) < 0);
            if isfield(kvargs, "Kompost")
                not_composts = ones(Zeilen * Spalten, 1);
                not_composts(kvargs.Kompost) = 0;
            else
                not_composts = (GMatrix(:, 4) ~= lhp.Garden.CELL_COMPOST.value);
            end
            ind = (ind & not_composts);

            if isfield(kvargs, "Start")
                not_start = ones(Zeilen * Spalten, 1);
                not_start(kvargs.Start) = 0;
                ind = (ind & not_start);
            end

            adj(GMatrix(ind, 3), :) = 0;
            adj(:, GMatrix(ind, 3)) = 0;
            % Symmetrie nutzen
            adj = sparse(adj+adj.');
            % Stelle sicher, dass nur 1 oder 0 in Matrix steht!
            adj = spones(adj);
        end

        function GMatrix = make_gmatrix(self)
            %%MAKE_GMATRIX Create a GMatrix.
            %
            %   Creates the GMatrix data structure given a garden in matrix
            %   representation. The GMatrix is used by many of the solving
            %   algorithms. It is a 4-column matrix with one row for each node
            %   in the garden matrix G. The columns have the following meanings:
            %
            %   1. Row-Index of the given garden cell/node
            %   2. Column-Index of the given garden cell/node
            %   3. Scalar Index of the given garden cell/node, counted row-wise
            %      from the "top-left" corner. Note that this differs from the
            %      scalar indexes that Matlab understands, because Matlab works
            %      row-wise, whereas this works column-wise.
            %   4. Amount of leaves on the specific garden cell/node
            %
            %   Returns
            %   -------
            %   GMatrix: 4-column matrix of double
            %       A matrix in the format described above.

            ZE = size(self.Raw, 1);
            SP = size(self.Raw, 2);
            AnzElem = ZE * SP;

            %  Garten-Matrix mit Indizes und Laubmenge fuellen (4 x AnzElem)
            GMatrix = zeros(AnzElem,4);
            val=0;
            for i=1:ZE
                for j=1:SP
                    val=val+1;
                    GMatrix(val,1)=i;            %beschreibt Zeile
                    GMatrix(val,2)=j;            %beschreibt Spalte
                    GMatrix(val,3)=val;          %beschreibt Nummerierung (a)
                    GMatrix(val,4)=self.Raw(i,j); %beschreibt Laubmenge  M(a)
                end
            end
        end

        function D = make_distances(self, adjacency, kvargs)
            %% Berechne die Entfernungsmatrix eines Gartens.
            %
            %   Berechnet auf der Grundlage der Garten- und Adjazenzmatrix eines
            %   Gartens die Entfernungsmatrix nach einer gewuenschten Metrik. Ob
            %   bei der Berechnung der Entfernungen das "diagonale gehen"
            %   erlaubt ist oder nicht, kann ebenfalls eingestellt werden.
            %
            %   Parameters
            %   ----------
            %   adjacency: double
            %       Adjazenzmatrix des Gartens mit den zu beruecksichtigenden
            %       Nachbarschaftsbeziehungen.
            %
            %   Key-Value Parameters
            %   --------------------
            %   'Method': string, default: "Dijkstra"
            %       Die Methode, nach der die Entfernungsmatrix berechnet wird.
            %       Entweder:
            %
            %       * "Dijkstra"
            %         Erstellt die Entfernungsmatrix mit Hilfe des Dijkstra
            %         Algorithmus. Diese Methode beruecksichtigt die Tatsache,
            %         dass man z.B. nicht durch den Schuppen hindurch gehen
            %         kann.
            %       * "Manhattan"
            %         Erstellt die Entfernungsmatrix nach der Manhattan-Metrik.
            %         Diese Methode beruecksichtigt allerdings nicht, ob
            %         Hindernisse im Garten stehen.
            %
            %   'DiagonalWeight': double, default: 1
            %       Gewichtungsfaktor fuer diagonal zurueckgelegte Wegstuecke.
            %       Auf "1" setzen, um das diagonale gehen gleich teuer wie das
            %       horizontale und waagrechte gehen zu machen. Auf "Inf"
            %       setzen, um das diagonale gehen zu verbieten.
            arguments
                self (:, :) lhp.Garden
                adjacency (:, :) double
                kvargs.Method (1, 1) string {mustBeMember(kvargs.Method, ...
                    ["Dijkstra", "Manhattan"])} = "Dijkstra";
                kvargs.DiagonalWeight (1, 1) double {mustBeNonnegative(...
                    kvargs.DiagonalWeight)} = 1;
            end

            GMatrix = self.make_gmatrix();
            Adjazenz = adjacency;

            switch (kvargs.Method)
                case "Dijkstra"
                    GardenGraph = Adjazenz;
                    % Consider the weights for diagonal connections
                    % Diagonals are located at:
                    %     (-w) - 1
                    %     (-w) + 1
                    %       w  - 1
                    %       w  + 1
                    % where w = garden width
                    % Get garden width
                    width = GMatrix(end, 2);
                    n = size(GardenGraph, 1);

                    % Select fields that must be weighted
                    diag_cells = diag(ones(n - width - 1, 1), - width - 1) + ...
                                 diag(ones(n - width + 1, 1), - width + 1) + ...
                                 diag(ones(n - width + 1, 1), + width - 1) + ...
                                 diag(ones(n - width - 1, 1), + width + 1);
                    % Unselect fields that don't exist in Adjacency
                    diag_cells = diag_cells & GardenGraph;
                    % Apply the weights
                    GardenGraph(diag_cells) = kvargs.DiagonalWeight;

                    % Get the proper distances
                    populated = xor((GardenGraph & diag(ones(n, 1))), ...
                        diag(ones(n, 1)));
                    D = distances(graph(GardenGraph));
                    % Set blocked diagonals to Inf, can't visit those.
                    D(populated) = Inf;

                    return;

                case "Manhattan"
                    %% Entfernungsmatrix erstellen nach Manhattan-Metrik
                    AnzElem = GMatrix(end, 3);
                    D = zeros(AnzElem,AnzElem);

                    for i=1:AnzElem
                        for j=1:AnzElem
                            if i~=j
                                a1 = GMatrix(i,1);
                                a2 = GMatrix(i,2);
                                b1 = GMatrix(j,1);
                                b2 = GMatrix(j,2);

                                dx = (a1 - b1); % Strecke in x-Richtung
                                dy = (a2 - b2); % Strecke in y-Richtung
                                if kvargs.DiagonalWeight == Inf
                                    % Diagonales gehen ist explizit verboten!
                                    D(i, j) = abs(dx) + abs(dy);
                                else
                                    % Wir duerfen ja auch diagonal gehen, also
                                    % beachte das hier auch!
                                    hor_vert = abs(x - y);
                                    diagonals = min(abs(x), abs(y));

                                    D(i, j) = hor_vert + ...
                                        diagonals * kvargs.DiagonalWeight;
                                end
                            end
                        end
                    end
            end
        end

        function fh = plot(self, ax, kvargs)
            %% Plot a garden matrix.
            %
            %   Plots the given garden matrix to the given canvas. This function
            %   is special in that it:
            %
            %   1. Handles the values of the negative cells to give them special
            %      colors
            %   2. Creates a colormap to represent leaves on green grass.
            %
            %   Parameters
            %   ----------
            %   ax: matlab.graphics.axis.Axes, default: axes()
            %       Some sort of figure window that heatmap plots can be drawn
            %       on. If none is provided, plot is created in a new, separate
            %       figure.
            %
            %   Key-Value Parameters
            %   --------------------
            %   'BlockedCellColors': array of struct
            %       An array of structs that represent the blocked fields, their
            %       meaning (short description) and the color to assign to them.
            %       Note that this applies only to blocked fields (value < 0)!
            %       The struct must have the following fields:
            %
            %       - 'value': The negative value of the field to handle
            %       - 'color': Color to assign this field in the plot, specified
            %         as an array of [r, g, b], where each component must be
            %         between 0.0 and 1.0.
            %       - 'description': Description (In human-readable form,
            %         please) of what this field represents.
            %
            %   Returns
            %   -------
            %   fh: figure_handle
            %       Handle to the created figure.
            arguments
                self (:, :) lhp.Garden
                ax (1, 1) matlab.graphics.axis.Axes = axes();
                kvargs.BlockedCellColors (1, :) struct = ...
                    [ lhp.Garden.CELL_SHED, ...
                      lhp.Garden.CELL_TREE, ...
                      lhp.Garden.CELL_COMPOST
                    ];
            end

            % Define the color transitions for the positive fields
            min_leaves_color = [0.47, 0.67, 0.19];
            med_leaves_color = [0.92, 0.92, 0.16];
            max_leaves_color = [0.85, 0.33, 0.10];
            % Explicitly don't use the minimum of what we have! I expect fields
            % to be green when I can see the grass beneath!
            min_leaves_val = 0;
            max_leaves_val = max(self.Raw, [], 'all');
            med_leaves_val = round(mean([min_leaves_val, max_leaves_val]));

            % Creates the heatmap
            fh = heatmap(ax.Parent, self.Raw);
            % Extract fields to handle in the plot
            garden_fields = unique(self.Raw);
            value_range = (min(garden_fields):1:max(garden_fields))';
            cmap = zeros(numel(value_range), 3);
            mapticks = repmat("", numel(value_range), 1);
            % Treat negative values specially
            negs = value_range(value_range < 0);

            if ~isempty(kvargs.BlockedCellColors)
                for nidx = 1:numel(negs)
                    neg_value = negs(nidx);
                    is_known = (neg_value == [kvargs.BlockedCellColors.value]);

                    if any(is_known)
                        cmap(nidx, :) = ...
                            kvargs.BlockedCellColors(is_known).color;
                        mapticks(nidx) = ...
                            kvargs.BlockedCellColors(is_known).description;
                    else
                        % Negative value isn't known to us, use a default value
                        cmap(nidx, :) = [0, 0, 0];
                        mapticks(nidx) = "";
                    end
                end
            end

            % Workaround for empty gardens
            if max(value_range) == 0
                cmap((value_range) == 0, :) = min_leaves_color;
                colormap(fh, cmap);
            else
                % Color transitions for lower half
                % .. todo:: Should '<=' be '<'??
                lower = ((value_range >= 0) & (value_range <= med_leaves_val));
                scaled_lower = rescale(value_range(lower));
                cmap(lower, :) = (1 - scaled_lower) .* min_leaves_color + ...
                                 (scaled_lower) .* med_leaves_color;

                % Color transitions for upper half
                upper = (value_range >= med_leaves_val);
                scaled_upper = rescale(value_range(upper));
                cmap(upper, :) = (1 - scaled_upper) .* med_leaves_color + ...
                                 (scaled_upper) .* max_leaves_color;

                % For reasons, there is one line too many in the colormap...
                colormap(fh, cmap(1:end-1, :));
            end

            % Make some tick labels
            % Well it would work, but Matlab won't let us due to lacking
            % support.
            %             mapticks(value_range == min_leaves_val) = string(min_leaves_val);
            %             mapticks(value_range == med_leaves_val) = string(med_leaves_val);
            %             mapticks(value_range == max_leaves_val) = string(max_leaves_val);
            %             colorbar(fh, 'Ticks', find(mapticks ~= ""), ...
            %                 'TickLabels', mapticks(mapticks ~= ""));
        end

        function truefalse = is_isolated(self, coords, kvargs)
            %IS_ISOLATED Check if a cell is isolated.
            %
            %   Arguments
            %   ---------
            %   coords: double scalar or tuple
            %       Coordinates of the cell to check for isolation. The
            %       coordinates can either be a numeric scalar (in which case it
            %       is interpreted as a row-wise, 'flipped', linear array index)
            %       or a 2-element vector of row and column coordinates.
            %
            %   Keyword Arguments
            %   -----------------
            %   'DiagonalMovements': logical, default: true
            %       A flag that defines whether diagonal movements are allowed.
            arguments
                self (:, :) lhp.Garden
                coords (1, :) double {mustBeInteger, mustBePositive}
                kvargs.DiagonalMovements (1, 1) logical = true;
            end

            if isscalar(coords)
                [row, col] = self.ind2sub(coords);
                coords = [row, col];
            end

            any_free = false;
            % Consider diagonal cells only if that kind of movement is allowed.
            if any(kvargs.DiagonalMovements == [0, Inf])
                % Mustn't move diagonally
                candidates = [ ...
                    coords(1)-1, coords(2); ...     % N
                    coords(1)  , coords(2)+1; ...   % E
                    coords(1)+1, coords(2); ...     % S
                    coords(1)  , coords(2)-1; ...   % W
                    ]';
            else
                candidates = [ ...
                    coords(1)-1, coords(2); ...     % N
                    coords(1)-1, coords(2)+1; ...   % NE
                    coords(1)  , coords(2)+1; ...   % E
                    coords(1)+1, coords(2)+1; ...   % SE
                    coords(1)+1, coords(2); ...     % S
                    coords(1)+1, coords(2)-1; ...   % SW
                    coords(1)  , coords(2)-1; ...   % W
                    coords(1)-1, coords(2)-1; ...   % NW
                    ]';
            end

            % I'll surely go to hell for this type of nesting...
            for c = candidates
                try
                    if self.Raw(c(1), c(2)) >= 0
                        % Feld ist frei
                        any_free = true;
                    end
                catch ME
                    if isequal(ME.identifier, 'MATLAB:badsubscript')
                        continue;
                    else
                        ME.rethrow();
                    end
                end
            end

            truefalse = ~any_free;
        end

        function truefalse = is_in_shed(self, ind, col, kvargs)
            %% Checks if a cell is in a shed, but accesses the garden
            %
            %   Cells that are located in the shed are usually considered to be
            %   blocked, as the shed has negative numeric values. However, the
            %   start cell may legally be part of the shed, as it is handled
            %   specially to ensure that it doesn't show up in the adjacency
            %   matrix, but in the distance matrix (So that we can walk to/away
            %   from it).
            %
            %   Keep in mind that the shed is defined as having the numeric
            %   value (-1).
            %
            %   Cells in the shed are only valid if they can access any of the
            %   "regular" non-blocked garden cells. This function ensures that
            %   the option for diagonal walking is considered when checking
            %   this, i.e. when `DiagonalCost` is :math:`inf`, only cells that
            %   aren't diagonally adjacent are considered in this check.
            %
            %   Arguments
            %   ---------
            %   sub: double
            %       A subscript (linear index into the garden) or a row
            %       coordinate. This is interpreted as row only if `col` is
            %       specified, too. Otherwise it's treated as a linear index.
            %       Keep in mind that linear indexes count row-wise, as detailed
            %       in the classes description!
            %   col: double
            %       If present, `ind` is interpreted as row coordinate, and this
            %       is the column coordinate of the cell to check. This
            %       parameter is optional.
            %
            %   Keyword Arguments
            %   -----------------
            %   'DiagonalMovements': logical, default: true
            %       If set to true, diagonal neighbor cells are considered when
            %       determining if the given cell can be reached from the
            %       currounding garden. If set to false, only horizontally and
            %       vertically adjacent cells are considered instead.
            %
            %   Returns
            %   -------
            %   true
            %       if the given cell is located in a shed but accessible from
            %       the garden surrounding it
            %   false
            %       if it isn't.
            arguments
                self (:, :) lhp.Garden
                ind (1, 1) double {mustBePositive, mustBeInteger}
                col (1, 1) double {mustBeNonnegative, mustBeInteger} = 0;
                kvargs.DiagonalMovements (1, 1) logical = true;
            end

            if nargin == 2
                % Got linear index. Convert to coordinates
                [row, col] = self.ind2sub(ind);
            else
                % Just rename param
                row = ind;
                assert(col > 0);
            end

            % Sanity checks
            assert(row <= self.size(1), ...
                "Row index (%d) outside of garden!", row);
            assert(col <= self.size(2), ...
                "Col index (%d) outside of garden!", col);

            % GO!
            truefalse = false;
            % Check if the field is a shed in the first place
            if (self.Raw(row, col) == lhp.Garden.CELL_SHED.value)
                % Collect all valid neighbors of the field
                truefalse = ~self.is_isolated([row, col], ...
                    "DiagonalMovements", kvargs.DiagonalMovements);
            end
            return;
        end

        function start_index = get_start(self, start)
            %% Get a starting field in this garden.
            %
            %   Arguments
            %   ---------
            %   start: 2-element vector of int, default: [0, 0]
            %       The location (coordinates) of a possible starting point in
            %       this garden. If [0, 0] is provided, some valid starting
            %       point is selected at random. If the garden contains a shed
            %       (cells with value -1), the start node is located in the shed
            %       (such that it is accessible from the garden surrounding it).
            %       If no cell exists that is in the shed and accessible from
            %       the garden, the start node is placed randomly in the garden
            %       instead.
            %
            %   Returns
            %   -------
            %   start_index: double
            %       The linear index into the garden at which the starting field
            %       is located.
            %
            %   Raises
            %   ------
            %   Can raise errors e.g. if given starting field is blocked and not
            %   in a shed, if the starting field is isolated, or invalid
            %   coordinates were given.
            if all(start == 0)
                % Get a starting point at random
                Start = inf;
                shed = find(transpose(self == lhp.Garden.CELL_SHED.value));

                while isinf(Start)
                    % If there's a shed, locate the start there!
                    if ~isempty(shed)
                        candidate_index = randsample(numel(shed), 1);
                        [start_ze, start_sp] = self.ind2sub(...
                            shed(candidate_index));
                        Start = [start_ze, start_sp];
                        if self.is_isolated(Start)
                            shed(candidate_index) = [];
                            Start = inf;
                            continue;
                        else
                            assert(self.is_in_shed(...
                                self.sub2ind(Start(1), Start(2))));
                            break;
                        end
                    else
                        % Otherwise choose location at random.
                        start_ze = randi([1, size(self, 1)]);
                        start_sp = randi([1, size(self, 2)]);
                        if self.Raw(start_ze, start_sp) >= 0
                            Start = [start_ze, start_sp];
                        end
                    end
                end
            elseif any(start == 0)
                error("Cannot use '0' as coordinate for either row or" + ...
                    " column of the starting field!");
            else
                % Make sure that start is valid in this garden
                if self.Raw(start(1), start(2)) >= 0
                    Start = start;
                elseif self.is_in_shed(start(1), start(2))
                    Start = start;
                else
                    error("Starting field (%d, %d) is a blocked field in" ...
                        + " this garden!", start(1), start(2));
                end
            end
            % Must make sure that start isn't isolated!
            assert(~self.is_isolated(Start), ...
                "Start at (%d, %d) is isolated!\n", ...
                Start(1), Start(2));

            start_index = self.sub2ind(Start(1), Start(2));
        end
    end

    methods (Static, Access = public)
        function [Garten, Dateiname] = random(Ze, Sp, kvargs)
            %% Generate a random garden.
            %
            %   The garden is randomly created with a garden shed, a compost
            %   field an some trees in it. What is to be placed can be specified
            %   (or ommited) by the user.
            %
            %   Arguments
            %   ---------
            %   Ze: double
            %       Number of rows in the garden. Must be a positiv integer.
            %   Sp: double
            %       Number of columns in the garden. Must be a positiv integer.
            %
            %   Keyword Arguments
            %   -----------------
            %   'Plot': logical, default: false
            %       If set to "true", opens a plot of the generated garden using
            %       the :meth:`~+lhp.Garden.plot` method.
            %   'Export': logical, default: false
            %       If set to "true", export the garden to a file in excel
            %       format.
            %   'ExportName': string
            %       Filename for export. If provided, 'Export' is implicitly set
            %       to true. Name is returned as second return value.
            %   'TreeDensity': double, default: 0.05
            %       A value in the interval [0, 0.9] which determines how many
            %       of the free garden fields (in percent) to place trees onto.
            %   'WithShed': logical, default: true
            %       Whether the garden should be created with a shed in it
            %       (true) or without a shed (false).
            %   'ShedSize': tuple of double, default: [5, 5]
            %       Size of the garden shed, as a tuple of [rows, cols].
            %   'WithCompost': logical, default: true
            %       If true, add a compost field to the garden. Skip compost
            %       otherwise.
            %   'LeavesDistributionType': string, default: "GaussAroundTrees"
            %       The distribution type for the leaves in the garden. Must be
            %       one of:
            %
            %       GaussAroundTrees
            %           Distribute leaves according to a Gaussian normal
            %           distribution around each of the generated trees. This
            %           means that each tree will have a predefined pattern of
            %           leaves lying around its trunk, as if the leaves have
            %           fallen straight down from the tree to the ground,
            %           without wind or other influences.
            %
            %       Uniform
            %           Uniformly distribute leaves in the garden. The trees are
            %           planted into the garden without associated leave
            %           patterns, leaves are added afterwards. Define a range
            %           for the uniform distribution by appending it to the
            %           argument. I.e. to draw leaves from a uniform
            %           distribution in the interval [1, 10], give "Uniform1-10"
            %           as argument.
            %
            %   Returns
            %   ---------
            %   Garten: lhp.Garden
            %       A valid garden, ready for being solved.
            %   Dateiname: String
            %       Name of the file to which the garden was exported, if any.
            arguments
                Ze (1, 1) double {mustBeInteger, mustBePositive};
                Sp (1, 1) double {mustBeInteger, mustBePositive};
                kvargs.Plot (1, 1) logical = false;
                kvargs.Export (1, 1) logical = false;
                kvargs.ExportName (1, 1) string = "";
                kvargs.TreeDensity (1, 1) double {mustBeNonnegative} = 0.05;
                kvargs.WithShed (1, 1) logical = true;
                kvargs.ShedSize (1, 2) double {mustBeInteger, ...
                    mustBePositive} = [5, 5];
                kvargs.WithCompost (1, 1) logical = true;
                kvargs.LeavesDistributionType (1, 1) string = ...
                    "GaussAroundTrees";
            end

            if ((Ze <= kvargs.ShedSize(1)) || (Sp <= kvargs.ShedSize(2)))
                error("Garden can't be smaller than the shed.");
            end

            Garten = lhp.Garden.empty(Ze, Sp, ...
                "WithShed", kvargs.WithShed, ...
                "WithCompost", kvargs.WithCompost, ...
                "ShedSize", kvargs.ShedSize);
            ldt = kvargs.LeavesDistributionType;

            free_fields = nnz(Garten >= 0);
            trees_to_add = ceil(free_fields * kvargs.TreeDensity);

            if isequal(ldt, "GaussAroundTrees")
                Garten = Garten.add_tree(trees_to_add);

            elseif startsWith(ldt, "Uniform")
                % Extract range from argument
                tmp = regexp(ldt, "Uniform(\d+)-(\d+)$", "tokens");
                if (numel(tmp) ~= 1) || (numel(tmp{1}) ~= 2)
                    error("Garden:UnknownLeavesDistributionType", ...
                        "Uniform distribution needs a valid argument.");
                end
                tmp = str2double(tmp{1});
                from = tmp(1);
                to = tmp(2);
                if (from < 0) || (to < 0) || (to < from)
                    error("Garden:UnknownLeavesDistributionType", ...
                        "Uniform distribution needs a valid argument.");
                end

                Garten = Garten.add_tree(trees_to_add, "NoLeaves", true);
                unipat = round(rescale(rand(Ze, Sp), from, to, ...
                    'InputMin', 0, 'InputMax', 1));
                % Overwrite all previously populated fields.
                Garten.Raw(Garten.Raw >= 0) = unipat(Garten.Raw >= 0);
            else
                error("Garden:UnknownLeavesDistributionType", ...
                    "Leaves distribution pattern '%s' is not defined.", ldt);
            end

            %% Abarbeiten der variablen Eingaben
            if kvargs.Plot
                %% Plotten der Daten
                Garten.plot();
            end

            if kvargs.Export
                %% Excel-Export
                if kvargs.ExportName == ""
                    dateiZe = num2str(Ze);
                    dateiSp = num2str(Sp);
                    dateinamePrefix = "Garten_";
                    dateinameSuffix = datestr(now, "yyyymmdd-HHMMSS");
                    Dateiname = strcat(dateinamePrefix, dateiZe, 'x', ...
                        dateiSp, '_', dateinameSuffix);
                else
                    Dateiname = kvargs.ExportName;
                end
                %Export ins Excel Format benoetigt eine Tabelle!
                temp_garten = table(Garten.Raw);
                writetable(temp_garten, Dateiname, "FileType", "spreadsheet", ...
                "WriteVariableNames", false, "WriteRowNames", false);
            end

            return;
        end

        function garden = empty(rows, cols, kvargs)
            %% Make a base-garden with a shed and compost, but without trees.
            %
            %   Arguments
            %   ---------
            %   rows: double
            %       Number of rows in the garden.
            %   cols: double
            %       Number of columns in the garden.
            %
            %   Keyword Arguments
            %   -----------------
            %   'WithShed': logical, default: true
            %       Whether the garden should be created with a shed in it
            %       (true) or without a shed (false).
            %   'ShedSize': tuple of double, default: [5, 5]
            %       Size of the garden shed, as a tuple of [rows, cols].
            %   'WithCompost': logical, default: true
            %       If true, add a compost field to the garden. Skip compost
            %       otherwise.
            arguments
                rows (1, 1) double {mustBeInteger, mustBePositive}
                cols (1, 1) double {mustBeInteger, mustBePositive}
                kvargs.WithShed (1, 1) logical = true;
                kvargs.ShedSize (1, 2) double {mustBeInteger, ...
                    mustBePositive} = [5, 5];
                kvargs.WithCompost (1, 1) logical = true;
            end

            assert((kvargs.ShedSize(1) < rows) && ...
                   (kvargs.ShedSize(2) < cols), ...
                "Shed must be smaller than the garden!");

            raw_garden = zeros(rows, cols);
            if kvargs.WithShed
                shedpos_row = randi(rows - kvargs.ShedSize(1));
                shedpos_col = randi(cols - kvargs.ShedSize(2));

                raw_garden(...
                    shedpos_row:(shedpos_row + kvargs.ShedSize(1) - 1), ...
                    shedpos_col:(shedpos_col + kvargs.ShedSize(2) - 1)) ...
                    = lhp.Garden.CELL_SHED.value;
            end

            garden = lhp.Garden(raw_garden);
            if kvargs.WithCompost
                while 1
                    % Place the compost
                    free = find(garden.Raw >= 0);
                    compost_idx = free(randsample(numel(free), 1));
                    garden.Raw(compost_idx) = lhp.Garden.CELL_COMPOST.value;

                    if garden.is_valid()
                        return;
                    end
                    garden.Raw(compost_idx) = 0;
                end
            end
        end
    end

    methods (Static, Access = private)
        function Garten = rec_validate(Garten, current_node, diagonal_allowed)
            %% Flood a given garden to see if there are any unreachable fields.
            %
            %   Parameters
            %   ----------
            %   Garten: matrix
            %       Der zu untersuchende Garten
            %   current_nore: vector
            %       Koordinaten des aktuellen Knoten (Zeile, Spalte)

            [ze, sp] = size(Garten);

            current_ze = current_node(1);
            current_sp = current_node(2);

            % Mark this field.
            Garten(current_node(1), current_node(2)) = -1;

            if diagonal_allowed
                neighbors = [current_ze - 1, current_sp - 1;    % SW
                             current_ze + 0, current_sp - 1;    % W
                             current_ze + 1, current_sp - 1;    % NW
                             current_ze - 1, current_sp + 0;    % S
                             current_ze + 1, current_sp + 0;    % N
                             current_ze - 1, current_sp + 1;    % SE
                             current_ze + 0, current_sp + 1;    % N
                             current_ze + 1, current_sp + 1];   % NE
            else
                neighbors = [current_ze + 1, current_sp + 0;    % N
                             current_ze + 0, current_sp - 1;    % W
                             current_ze + 0, current_sp + 1;    % E
                             current_ze - 1, current_sp + 0];   % S
            end

            for neighbor = neighbors'
                % Use row vectors...
                neighbor = neighbor'; %#ok

                if (neighbor(1) < 1 || neighbor(1) > ze) || ...
                   (neighbor(2) < 1 || neighbor(2) > sp)
                   continue;
                end

                % Make sure it's valid
                if Garten(neighbor(1), neighbor(2)) < 0
                    continue;
                end

                tmp = lhp.Garden.rec_validate(...
                    Garten, neighbor, diagonal_allowed);
                Garten(tmp < 0) = -1;
            end
            return;
        end
    end
end

