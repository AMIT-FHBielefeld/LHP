classdef SimAnParameters
    %SIMANPARAMETERS Summary of this class goes here
    %   Detailed explanation goes here

    properties (Access=public)
        NumSimAn;
        MaxIter;
        Debug;
    end

    methods
        function self = SimAnParameters(kvargs)
            %SIMANPARAMETERS Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                kvargs.NumSimAn (1, 1) double {...
                    mustBePositive(kvargs.NumSimAn), ...
                    mustBeInteger(kvargs.NumSimAn)} = 30;
                kvargs.MaxIter (1, 1) double {...
                    mustBePositive(kvargs.MaxIter), ...
                    mustBeInteger(kvargs.MaxIter)} = 10000;
                kvargs.Debug (1, 1) logical = false;
            end

            self.NumSimAn = kvargs.NumSimAn;
            self.MaxIter = kvargs.MaxIter;
            self.Debug = kvargs.Debug;
        end
    end

%     methods(Access = public, Static)
%         function gui(beep, kvargs)
%             %% GUI to generate BeeParameters objects
%             %
%             %   Opens a GUI window that allows the user to configure an object
%             %   of type BeeParameters graphically. This is used in conjunction
%             %   with the other GUI applications that operate the LHP to
%             %   encapsulate the configuration of the BeeParameters object in
%             %   this very class (instead of hard-coding it in the other GUIs).
%             %
%             %   Parameters
%             %   ----------
%             %   beep: BeeParameters, default: BeeParameters()
%             %       An object of type BeeParameters. If supplied, the given
%             %       object is configured/modified through the GUI (i.e. it's
%             %       values are filled into the GUI fields). If not supplied, the
%             %       GUI is populated with the default values.
%             %
%             %   Key-Value Parameters
%             %   --------------------
%             %   'Callback': function_handle, optional
%             %       A callback function that is invoked with the newly created
%             %       BeeParameters object. The function must take exactly one
%             %       parameter of type BeeParameters. If no callback is provided,
%             %       the BeeParameters object is added to the base workspace in
%             %       the variable 'beeparams'.
%             %   'Modal': logical, default: false
%             %       If set to true, the UI window is opened as a modal dialog.
%             %       This means that no other windows can be interacted with
%             %       unless the window has been closed.
%             arguments
%                 beep (1, 1) lhp.algo.stochastic.bee.BeeParameters = ...
%                     lhp.algo.stochastic.bee.BeeParameters();
%                 kvargs.Callback (1, 1) function_handle
%                 kvargs.Modal (1, 1) logical = false;
%             end
%             if ~isfield(kvargs, "Callback")
%                 kvargs.Callback = @(x) assignin('base', 'beeparams', x);
%             end
% 
%             fig = uifigure(...
%                 'Name', 'BeeParameters konfigurieren');
%             fig.Position(3:4) = [320, 480];
%             cur_height = fig.Position(4) - 30;
% 
%             if kvargs.Modal
%                 fig.WindowStyle = 'modal';
%             end
% 
%             OFFSET = 14;
%             LABEL_HEIGHT = 24;
%             LABEL_WIDTH = 200;
%             UIEDIT_XPOS = OFFSET + LABEL_WIDTH + 6;
%             UIEDIT_WIDTH = 80;
%             ROW_SPACING = 6;
%             cur_label_pos = @(height) [OFFSET, height, LABEL_WIDTH, LABEL_HEIGHT];
%             cur_spinner_pos = @(height) [UIEDIT_XPOS, height, UIEDIT_WIDTH, LABEL_HEIGHT];
%             parameters = struct("attr", [], "handle", []);
% 
%             import('lhp.algo.stochastic.bee.BeeParameters');
% 
%             % We hardcode the fields here, because they aren't many, they aren't
%             % expected to change at will, and they have very different needs
%             % each.
%             % --- NumScoutBees ---
%             BeeParameters.make_label(fig, ...
%                 cur_label_pos(cur_height), "Anzahl Scout-Bienen", "");
%             uis = BeeParameters.make_spinner(fig, ...
%                 cur_spinner_pos(cur_height), beep, "NumScoutBees", ...
%                 "Limits", [1, Inf]);
%             parameters(1).attr = "NumScoutBees";
%             parameters(1).handle = uis;
%             cur_height = cur_height - (LABEL_HEIGHT + ROW_SPACING);
% 
%             % --- NumBestSolutions ---
%             BeeParameters.make_label(fig, ...
%                 cur_label_pos(cur_height), "Anzahl bester Loesungen", "");
%             uis = BeeParameters.make_spinner(fig, ...
%                 cur_spinner_pos(cur_height), beep, "NumBestSolutions");
%             parameters(2).attr = "NumBestSolutions";
%             parameters(2).handle = uis;
%             cur_height = cur_height - (LABEL_HEIGHT + ROW_SPACING);
% 
%             % --- NumBestSolutionNeighbors ---
%             BeeParameters.make_label(fig, ...
%                 cur_label_pos(cur_height), "Anz. Nachbarn pro bester Loesung", ...
%                 "Anzahl Bienen, die in der Nachbarschaft jeder 'besten Loesung' nach weiteren Loesungen suchen");
%             uis = BeeParameters.make_spinner(fig, ...
%                 cur_spinner_pos(cur_height), beep, "NumBestSolutionNeighbors");
%             parameters(3).attr = "NumBestSolutionNeighbors";
%             parameters(3).handle = uis;
%             cur_height = cur_height - (LABEL_HEIGHT + ROW_SPACING);
% 
%             % --- NumEliteSolutions ---
%             BeeParameters.make_label(fig, ...
%                 cur_label_pos(cur_height), "Anzahl Elite-Bienen", "");
%             uis = BeeParameters.make_spinner(fig, ...
%                 cur_spinner_pos(cur_height), beep, "NumEliteSolutions");
%             parameters(4).attr = "NumEliteSolutions";
%             parameters(4).handle = uis;
%             cur_height = cur_height - (LABEL_HEIGHT + ROW_SPACING);
% 
%             % --- NumEliteSolutionNeighbors ---
%             BeeParameters.make_label(fig, ...
%                 cur_label_pos(cur_height), "Anz. Nachbarn pro elite Loesung", ...
%                 "Anzahl Bienen, die in der Nachbarschaft jeder 'elite-Loesung' nach weiteren Loesungen suchen");
%             uis = BeeParameters.make_spinner(fig, ...
%                 cur_spinner_pos(cur_height), beep, "NumEliteSolutionNeighbors");
%             parameters(5).attr = "NumEliteSolutionNeighbors";
%             parameters(5).handle = uis;
%             cur_height = cur_height - (LABEL_HEIGHT + ROW_SPACING);
% 
%             % --- MaxIter ---
%             BeeParameters.make_label(fig, ...
%                 cur_label_pos(cur_height), "Maximale Anz. an Iterationen", ...
%                 "Abbruchkriterium");
%             uis = BeeParameters.make_spinner(fig, ...
%                 cur_spinner_pos(cur_height), beep, "MaxIter", ...
%                 "Limits", [1, Inf]);
%             parameters(6).attr = "MaxIter";
%             parameters(6).handle = uis;
%             cur_height = cur_height - (LABEL_HEIGHT + ROW_SPACING);
% 
%             % --- Algorithms ---
%             BeeParameters.make_label(fig, ...
%                 cur_label_pos(cur_height), "Startalgorithmen", ...
%                 "Algorithmen, mit denen die Scout-Bienen nach neuen Loesungen" + ...
%                 " suchen. Komma-separierte Liste von Indizes nach" + ...
%                 " LHT_HeuristicData.gather(), Parameter 'Range'." + ...
%                 " Auf 0 setzen, um Loesungen der Scout-Bienen randomisiert" + ...
%                 " zu erzeugen.");
%             cur_height = cur_height - LABEL_HEIGHT;
%             uis = uitextarea(fig, ...
%                 "Value", strjoin(string(beep.Algorithms), ","), ...
%                 "Position", [OFFSET, cur_height, 292, LABEL_HEIGHT]);
%             parameters(7).attr = "Algorithms";
%             parameters(7).handle = uis;
%             cur_height = cur_height - (LABEL_HEIGHT + ROW_SPACING);
% 
%             % --- Debug ---
%             BeeParameters.make_label(fig, ...
%                 cur_label_pos(cur_height), "Debug-Modus", ...
%                 "Wenn aktiviert, werden Informationen ueber den Status des Algorithmus im Command Window ausgegeben.");
%             uib = BeeParameters.make_checkbox(fig, ...
%                 cur_spinner_pos(cur_height), beep, "Debug");
%             parameters(8).attr = "Debug";
%             parameters(8).handle = uib;
%             cur_height = cur_height - (LABEL_HEIGHT + ROW_SPACING);
% 
%             uibutton(fig, ...
%                 "Text", "OK", ...
%                 "Position", [220, cur_height, 60, 24], ...
%                 "ButtonPushedFcn", @(btn, event) ...
%                 (lhp.algo.stochastic.bee.BeeParameters.make_beep_from_gui(...
%                 fig, parameters, kvargs.Callback)));
% 
%             return;
%         end
%     end
% 
%     % helper-functions for the UI.
%     methods (Access = private, Static)
%         function make_label(parent, pos, text, tooltip)
%             % Convenienvce function to construct text labels for the GUI.
%             uilabel(parent, ...
%                 'Position', pos, ...
%                 'Text', text, ...
%                 'HorizontalAlignment', 'right', ...
%                 'Tooltip', tooltip);
%         end
% 
%         function spin = make_spinner(parent, pos, obj, attr, kvargs)
%             % Create a spinner.
%             arguments
%                 parent (1, 1)
%                 pos (1, 4) double
%                 obj (1, 1) lhp.algo.stochastic.bee.BeeParameters
%                 attr (1, 1) string
%                 kvargs.Limits (1, 2) double = [0, Inf];
%                 kvargs.Format (1, 1) string = "%.0f";
%                 kvargs.Round (1, 1) string = 'on';
%             end
%             spin = uispinner(parent, ...
%                 "Value", obj.(attr), ...
%                 "Limits", kvargs.Limits, ...
%                 "RoundFractionalValues", kvargs.Round, ...
%                 "ValueDisplayFormat", kvargs.Format, ...
%                 "Position", pos);
%         end
% 
%         function box = make_checkbox(parent, pos, obj, attr)
%             % Create a checkbox.
%             arguments
%                 parent (1, 1)
%                 pos (1, 4) double
%                 obj (1, 1) lhp.algo.stochastic.bee.BeeParameters
%                 attr (1, 1) string
%             end
%             box = uicheckbox(parent, ...
%                 "Value", obj.(attr), ...
%                 "Position", pos, ...
%                 "Text", "");
%         end
% 
%         function make_beep_from_gui(fig, parameters, callback)
%             %% Make a BeeParameters object from a GUI.
%             %
%             %   Parameters
%             %   ----------
%             %   fig: UIFigure
%             %       The UIFigure that this callback was invoked from. The figure
%             %       is closed before the callback (see below) is called.
%             %   parameters: struct
%             %       An array of structs, where each struct has two members:
%             %
%             %       - 'attr': Name of the BeeParameters attribute to assign
%             %         value to.
%             %       - 'handle': Handle to a UI element whose 'Value' is to be
%             %         assigned to 'attr' of BeeParameters.
%             %
%             %   callback: function_handle
%             %       Callback function to execute with the newly created
%             %       BeeParameters instance.
%             arguments
%                 fig (1, 1)
%                 parameters (1, :) struct
%                 callback (1, 1) function_handle
%             end
%             % Object that is "returned"
%             beep = lhp.algo.stochastic.bee.BeeParameters();
% 
%             for hidx = 1:numel(parameters)
%                 cur_handle = parameters(hidx);
%                 switch (cur_handle.attr)
%                     case "NeighborAlgorithms"
%                         % Handle specially
%                         beep.NeighborAlgorithms = cellfun(@str2func, ...
%                             cur_handle.handle.Value, 'UniformOutput', false);
%                     case "Algorithms"
%                         % Handle specially
%                         beep.Algorithms = str2double(strsplit(...
%                             cur_handle.handle.Value{1}, ","));
%                     otherwise
%                         beep.(cur_handle.attr) = cur_handle.handle.Value;
%                 end
%             end
% 
%             % Invoke the callback.
%             callback(beep);
%             % Close the figure.
%             close(fig);
%         end
%     end
end

