classdef GeneticParameters
    %GENETICPARAMS Summary of this class goes here
    %   Detailed explanation goes here

    properties
        Strict;             % True if strict, false if fast/sloppy
        InitializationAlgorithms;      % heuristics to be used for initialization
        Popsize;            % Size of population
        T_Max;              % Number of steps taken on top level
        Mutation_Param;     % Maximum number of mutated genes per step
        Crossover_Param;    % Minimal probability of crossover
        Stagnation_Param;   % Parameter to influence stagnation behaviour
        Reinit_Param;       % Percentile of randomly generated chromosomes
    end

    properties (Constant, Access = private)
        STANDARD_STRICT = false;
        % STANDARD_INIT_HEURISTICS = [6,7,8,9,10,11,14,17,18,19,20,21,23,28];
        STANDARD_INIT_HEURISTICS = 0;
        STANDARD_POPSIZE = 25;
        STANDARD_T_MAX = 1e6;
        STANDARD_MUTATION_PARAM = 0.72;
        STANDARD_CROSSOVER_PARAM = 0.64;
        STANDARD_STAGNATION_PARAM = 59;
        STANDARD_REINIT_PARAM = 0.04;
    end

    methods
        function self = GeneticParameters(kvargs)
            %GENETICPARAMS Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                kvargs.Strict (1, 1) logical = ...
                    lhp.algo.stochastic.genetic.GeneticParameters.STANDARD_STRICT;
                kvargs.InitializationAlgorithms (1, :) double {mustBeNonnegative} = ...
                    lhp.algo.stochastic.genetic.GeneticParameters.STANDARD_INIT_HEURISTICS;
                kvargs.Popsize (1, 1) double {...
                    mustBePositive(kvargs.Popsize), ...
                    mustBeInteger(kvargs.Popsize)} = ...
                    lhp.algo.stochastic.genetic.GeneticParameters.STANDARD_POPSIZE;
                kvargs.T_Max (1, 1) double {...
                    mustBePositive(kvargs.T_Max), ...
                    mustBeInteger(kvargs.T_Max)} = ...
                    lhp.algo.stochastic.genetic.GeneticParameters.STANDARD_T_MAX;
                kvargs.Mutation_Param (1, 1) double {...
                    mustBePositive(kvargs.Mutation_Param), ...
                    mustBeNumeric(kvargs.Mutation_Param)} = ...
                    lhp.algo.stochastic.genetic.GeneticParameters.STANDARD_MUTATION_PARAM;
                kvargs.Crossover_Param (1, 1) double {...
                    mustBePositive(kvargs.Crossover_Param), ...
                    mustBeNumeric(kvargs.Crossover_Param)} = ...
                    lhp.algo.stochastic.genetic.GeneticParameters.STANDARD_CROSSOVER_PARAM;
                kvargs.Stagnation_Param (1, 1) double {...
                    mustBePositive(kvargs.Stagnation_Param), ...
                    mustBeInteger(kvargs.Stagnation_Param)} = ...
                    lhp.algo.stochastic.genetic.GeneticParameters.STANDARD_STAGNATION_PARAM;
                kvargs.Reinit_Param(1, 1) double {...
                    mustBePositive(kvargs.Reinit_Param), ...
                    mustBeNumeric(kvargs.Reinit_Param)} = ...
                    lhp.algo.stochastic.genetic.GeneticParameters.STANDARD_REINIT_PARAM;
            end
            self.Strict = kvargs.Strict;
            self.InitializationAlgorithms = kvargs.InitializationAlgorithms;
            self.Popsize = kvargs.Popsize;
            self.T_Max = kvargs.T_Max;                          % Number of steps taken on top level
            self.Mutation_Param = kvargs.Mutation_Param;        % Maximum number of mutated genes per step
            self.Crossover_Param = kvargs.Crossover_Param;      % Minimal probability of crossover
            self.Stagnation_Param = kvargs.Stagnation_Param;    % Parameter to influence stagnation behaviour
            self.Reinit_Param = kvargs.Reinit_Param;
        end
    end

    methods(Access = public, Static)
        function gui(genp, kvargs)
            %% GUI to generate GeneticParameters objects
            %
            %   Opens a GUI window that allows the user to configure an object
            %   of type GeneticParameters graphically. This is used in
            %   conjunction with the other GUI applications that operate the LHP
            %   to encapsulate the configuration of the GeneticParameters object
            %   in this very class (instead of hard-coding it in the other
            %   GUIs).
            %
            %   Parameters
            %   ----------
            %   beep: GeneticParameters, default: GeneticParameters()
            %       An object of type GeneticParameters. If supplied, the given
            %       object is configured/modified through the GUI (i.e. it's
            %       values are filled into the GUI fields). If not supplied, the
            %       GUI is populated with the default values.
            %
            %   Key-Value Parameters
            %   --------------------
            %   'Callback': function_handle, optional
            %       A callback function that is invoked with the newly created
            %       GeneticParameters object. The function must take exactly one
            %       parameter of type GeneticParameters. If no callback is
            %       provided, the GeneticParameters object is added to the base
            %       workspace in the variable 'genparams'.
            %   'Modal': logical, default: false
            %       If set to true, the UI window is opened as a modal dialog.
            %       This means that no other windows can be interacted with
            %       unless the window has been closed.
            arguments
                genp (1, 1) lhp.algo.stochastic.genetic.GeneticParameters = ...
                    lhp.algo.stochastic.genetic.GeneticParameters();
                kvargs.Callback (1, 1) function_handle
                kvargs.Modal (1, 1) logical = false;
            end
            if ~isfield(kvargs, "Callback")
                kvargs.Callback = @(x) assignin('base', 'genparams', x);
            end

            fig = uifigure(...
                'Name', 'GeneticParameters konfigurieren');
            fig.Position(3:4) = [320, 480];
            cur_height = fig.Position(4) - 30;

            if kvargs.Modal
                fig.WindowStyle = 'modal';
            end

            OFFSET = 14;
            LABEL_HEIGHT = 24;
            LABEL_WIDTH = 200;
            UIEDIT_XPOS = OFFSET + LABEL_WIDTH + 6;
            UIEDIT_WIDTH = 80;
            ROW_SPACING = 6;
            cur_label_pos = @(height) [OFFSET, height, LABEL_WIDTH, LABEL_HEIGHT];
            cur_spinner_pos = @(height) [UIEDIT_XPOS, height, UIEDIT_WIDTH, LABEL_HEIGHT];
            parameters = struct("attr", [], "handle", []);

            import('lhp.algo.stochastic.genetic.GeneticParameters');

            % We hardcode the fields here, because they aren't many, they aren't
            % expected to change at will, and they have very different needs
            % each.
            % --- Strict ---
            GeneticParameters.make_label(fig, ...
                cur_label_pos(cur_height), "Strikte Bewertung", ...
                "Wenn deaktiviert, wird bei der Berechnung der Gesamtkosten" ...
                + " innerhalb des Algorithmus die Kosten durch unproduktive" ...
                + " Wege vernachlaessigt. Spart viel Zeit auf Kosten " ...
                + "potenziell schlechterer Ergebnisse");
            uis = GeneticParameters.make_checkbox(fig, ...
                cur_spinner_pos(cur_height), genp, "Strict");
            parameters(1).attr = "Strict";
            parameters(1).handle = uis;
            cur_height = cur_height - (LABEL_HEIGHT + ROW_SPACING);

            % --- InitializationAlgorithms ---
            GeneticParameters.make_label(fig, ...
                cur_label_pos(cur_height), "Startalgorithmen", ...
                "Algorithmen, mit denen die Startloesungen erzeugt werden." + ...
                " Komma-separierte Liste von Indizes nach" + ...
                " LHT_HeuristicData.gather(), Parameter 'Range'." + ...
                " Auf 0 setzen, um Startloesungen randomisiert" + ...
                " zu erzeugen.");
            cur_height = cur_height - LABEL_HEIGHT;
            uis = uitextarea(fig, ...
                "Value", strjoin(string(genp.InitializationAlgorithms), ","), ...
                "Position", [OFFSET, cur_height, 292, LABEL_HEIGHT]);
            parameters(2).attr = "InitializationAlgorithms";
            parameters(2).handle = uis;
            cur_height = cur_height - (LABEL_HEIGHT + ROW_SPACING);

            % --- Popsize ---
            GeneticParameters.make_label(fig, ...
                cur_label_pos(cur_height), "Populationsgroesse", ...
                "Anzahl Individuen (Loesungen) innerhalb der Population");
            uis = GeneticParameters.make_spinner(fig, ...
                cur_spinner_pos(cur_height), genp, "Popsize", ...
                "Limits", [1, Inf]);
            parameters(3).attr = "Popsize";
            parameters(3).handle = uis;
            cur_height = cur_height - (LABEL_HEIGHT + ROW_SPACING);

            % --- T_Max ---
            GeneticParameters.make_label(fig, ...
                cur_label_pos(cur_height), "Maximale Anz. Iterationen", "");
            uis = GeneticParameters.make_spinner(fig, ...
                cur_spinner_pos(cur_height), genp, "T_Max", ...
                "Limits", [1, Inf]);
            parameters(4).attr = "T_Max";
            parameters(4).handle = uis;
            cur_height = cur_height - (LABEL_HEIGHT + ROW_SPACING);

            % --- Mutation_Param ---
            GeneticParameters.make_label(fig, ...
                cur_label_pos(cur_height), "Max. Anzahl Mutationen", ...
                "Maximale Anzahl mutierter Gene pro Schritt");
            uis = GeneticParameters.make_spinner(fig, ...
                cur_spinner_pos(cur_height), genp, "Mutation_Param", ...
                "Format", "%.2f", "Round", "off");
            parameters(5).attr = "Mutation_Param";
            parameters(5).handle = uis;
            cur_height = cur_height - (LABEL_HEIGHT + ROW_SPACING);

            % --- Crossover_Param ---
            GeneticParameters.make_label(fig, ...
                cur_label_pos(cur_height), "Min. Crossover Wahrscheinlichkeit", ...
                "Wahrscheinlichkeit, dass ein Crossover stattfindet.");
            uis = GeneticParameters.make_spinner(fig, ...
                cur_spinner_pos(cur_height), genp, "Crossover_Param", ...
                "Limits", [0, 1], ...
                "Format", "%.2f", "Round", "off");
            parameters(numel(parameters)+1).attr = "Crossover_Param";
            parameters(numel(parameters)).handle = uis;
            cur_height = cur_height - (LABEL_HEIGHT + ROW_SPACING);

            % --- Stagnation_Param ---
            GeneticParameters.make_label(fig, ...
                cur_label_pos(cur_height), "Stagnationsparameter", ...
                "Beeinflusst die Stagnation des Algorithmus.");
            uis = GeneticParameters.make_spinner(fig, ...
                cur_spinner_pos(cur_height), genp, "Stagnation_Param", ...
                "Limits", [1, Inf]);
            parameters(numel(parameters)+1).attr = "Stagnation_Param";
            parameters(numel(parameters)).handle = uis;
            cur_height = cur_height - (LABEL_HEIGHT + ROW_SPACING);

            % --- Reinit_Param ---
            GeneticParameters.make_label(fig, ...
                cur_label_pos(cur_height), "Anteil zufaelliger Chromosomen", ...
                "Relativer Anteil zufaellig initialisierter Chromosomen an der Gesamtpopulation");
            uis = GeneticParameters.make_spinner(fig, ...
                cur_spinner_pos(cur_height), genp, "Reinit_Param", ...
                "Limits", [0, 1], ...
                "Format", "%.2f", "Round", "off");
            parameters(numel(parameters)+1).attr = "Reinit_Param";
            parameters(numel(parameters)).handle = uis;
            cur_height = cur_height - (LABEL_HEIGHT + ROW_SPACING);

            uibutton(fig, ...
                "Text", "OK", ...
                "Position", [220, cur_height, 60, 24], ...
                "ButtonPushedFcn", @(btn, event) ...
                    (lhp.algo.stochastic.genetic.GeneticParameters.make_genp_from_gui(...
                        fig, parameters, kvargs.Callback)));

            return;
        end
    end

    % helper-functions for the UI.
    methods (Access = private, Static)
        function make_label(parent, pos, text, tooltip)
            % Convenienvce function to construct text labels for the GUI.
            uilabel(parent, ...
                'Position', pos, ...
                'Text', text, ...
                'HorizontalAlignment', 'right', ...
                'Tooltip', tooltip);
        end

        function spin = make_spinner(parent, pos, obj, attr, kvargs)
            % Create a spinner.
            arguments
                parent (1, 1)
                pos (1, 4) double
                obj (1, 1) lhp.algo.stochastic.genetic.GeneticParameters
                attr (1, 1) string
                kvargs.Limits (1, 2) double = [0, Inf];
                kvargs.Format (1, 1) string = "%.0f";
                kvargs.Round (1, 1) string = 'on';
            end
            spin = uispinner(parent, ...
                "Value", obj.(attr), ...
                "Limits", kvargs.Limits, ...
                "RoundFractionalValues", kvargs.Round, ...
                "ValueDisplayFormat", kvargs.Format, ...
                "Position", pos);
        end

        function box = make_checkbox(parent, pos, obj, attr)
            % Create a checkbox.
            arguments
                parent (1, 1)
                pos (1, 4) double
                obj (1, 1) lhp.algo.stochastic.genetic.GeneticParameters
                attr (1, 1) string
            end
            box = uicheckbox(parent, ...
                "Value", obj.(attr), ...
                "Position", pos, ...
                "Text", "");
        end

        function make_genp_from_gui(fig, parameters, callback)
            %% Make a GeneticParameters object from a GUI.
            %
            %   Parameters
            %   ----------
            %   fig: UIFigure
            %       The UIFigure that this callback was invoked from. The figure
            %       is closed before the callback (see below) is called.
            %   parameters: struct
            %       An array of structs, where each struct has two members:
            %
            %       - 'attr': Name of the GeneticParameters attribute to assign
            %         value to.
            %       - 'handle': Handle to a UI element whose 'Value' is to be
            %         assigned to 'attr' of GeneticParameters.
            %
            %   callback: function_handle
            %       Callback function to execute with the newly created
            %       GeneticParameters instance.
            arguments
                fig (1, 1)
                parameters (1, :) struct
                callback (1, 1) function_handle
            end
            % Object that is "returned"
            genp = lhp.algo.stochastic.genetic.GeneticParameters();

            for hidx = 1:numel(parameters)
                cur_handle = parameters(hidx);
                switch (cur_handle.attr)
                    case "InitializationAlgorithms"
                        % Handle specially
                        genp.InitializationAlgorithms = str2double(strsplit(...
                            cur_handle.handle.Value{1}, ","));
                    otherwise
                        genp.(cur_handle.attr) = cur_handle.handle.Value;
                end
            end

            % Invoke the callback.
            callback(genp);
            % Close the figure.
            close(fig);
        end
    end
end

