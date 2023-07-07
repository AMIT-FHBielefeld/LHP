classdef ProgressBar < handle
    %PROGRESSBAR A class for monitoring arbitrary progresses.
    %
    %   This class prints a progress bar to the current STDOUT or a graphical
    %   uiprogressdlg (See constructor-parameter 'UI'), that shows the progress
    %   on some arbitrary process. The main loop responsible for providing the
    %   output takes 2 arguments: The current "iteration", and the final value,
    %   and displays information based on the result of
    %
    %       current iteration / final value
    %
    %   So please make sure that the current iteration steadily increases until
    %   it reaches the final value.
    %
    %   This class is made to display proper textual progress in the command
    %   window as well as in live scripts. It uses the '\b' character to achieve
    %   this by deleting exactly the characters the class itself printed out
    %   previously. This is the reason why the "WidestNumber" parameter should
    %   be populated with sensible values, otherwise the progressbar will
    %   "destroy" its own formatting.
    %
    %   Due to the way it is implemented, it is recommended to create a fresh
    %   instance of this class for every progress bar that is to be printed. In
    %   other words: Don't use one and the same class instance (object) to print
    %   multiple progress bars that don't relate to each other.

    properties (SetAccess = private)
        % Width of the window, defines the space for the progress bar. May be
        % less than the actual available window width.
        window_width;
        % Style of the bar (fill-chars)
        bar_style;
        % UNUSED
        percentage_show;
        % String that is displayed on each "update".
        update_string;
        % Biggest width (in digits) of the current and final values.
        widest_number;
        % A time in seconds after which to update the bar
        update_every;
        % Maximum value up until which this progress bar counts
        max_value;
    end

    properties (GetAccess = private)
        % Point in time of the last update performed
        last_update_t;
        % Boolean value marks if it's the first call or not.
        first_run;
        % UI component to paint to, if any.
        ui;
        % Last state of the progress bar, useful with "increment()"
        last_count;
        % Number of bytes written last time
        bytes_written;
        % Number of newlines written last time
        lines_written;
    end


    methods
        function self = ProgressBar(kvargs)
            %PROGRESSBAR Construct an instance of this class
            %
            %   Instance of the progressbar.
            %
            %   Optional Key-Value Parameters
            %   -----------------------------
            %   'WindowWidth':
            %       The maximum width of the window. This determines the width
            %       of the actual progress bar. May be less or equal to the
            %       actual window space to preserve proper formatting. If left
            %       empty, the current command window width is used.
            %   'BarStyle': char
            %       Characters to print for the completion-bar. Can be one of
            %       '-', '=', '#', '+', '>'.
            %       Default: '#'
            %   'ShowPercentage': UNUSED
            %   'MaxValue': double
            %       The maximum integer up to which the progress bar should
            %       count. Useful only in conjunction with :meth:`increment`.
            %   'WidestNumber': double
            %       Maximum number of digits of the biggest number supplied to
            %       the "update" method. This is needed to make sure the
            %       formatting remains consistent.
            %       Default: 8
            %   'UpdateString': string
            %       A string that is printed before the actual progress state.
            %       Set this to a custom string that describes which progress is
            %       monitored. A ": " is added after the string automatically
            %       for you.
            %       Default: 'Current progress'
            %   'UpdateEvery': double
            %       A dead-time, specified in seconds. If the last print of this
            %       class was less than 'UpdateEvery' seconds ago, no new print
            %       is done. This is to prevent Matlab from creating many many
            %       print requests when update is called very frequently. By
            %       default, the progress bar is updated every time "update" is
            %       invoked.
            %       Default: 0
            %   'UI': matlab.ui.dialog.ProgressDialog
            %       If supplied, the progress will be shown on the respective
            %       graphical progress dialog. A graphical progress dialog is
            %       created through the function uiprogressdlg(). This is useful
            %       for GUIs. If not provided, text-based output is used.
            arguments
                kvargs.WindowWidth (1, 1) double {mustBePositive}
                kvargs.BarStyle (1, 1) char {mustBeMember(kvargs.BarStyle, ...
                    ['-', '=', '#', '+', '>'])} = "#";
                kvargs.ShowPercentage (1, 1) logical = true;
                kvargs.MaxValue (1, 1) double {mustBePositive, mustBeInteger}
                kvargs.WidestNumber (1, 1) double {mustBePositive} = 6;
                kvargs.UpdateString (1, 1) string = ...
                    "Current progress";
                kvargs.UpdateEvery (1, 1) double {mustBeNonnegative}
                kvargs.UI (1, 1) matlab.ui.dialog.ProgressDialog
            end

            if ~isfield(kvargs, "WindowWidth")
                cw_size = matlab.desktop.commandwindow.size;
                self.window_width = cw_size(1);
            else
                self.window_width = kvargs.WindowWidth;
            end

            if ~isfield(kvargs, "UpdateEvery")
                self.update_every = 0;
            else
                self.update_every = kvargs.UpdateEvery;
            end

            if isfield(kvargs, "MaxValue")
                self.max_value = kvargs.MaxValue;
                self.last_count = 0;
            end

            self.last_update_t = uint64(0);
            self.bar_style = kvargs.BarStyle;
            self.percentage_show = kvargs.ShowPercentage;
            self.update_string = kvargs.UpdateString;
            self.widest_number = kvargs.WidestNumber;
            self.first_run = true;
            self.bytes_written = 0;
            self.lines_written = 0;

            if isfield(kvargs, "UI")
                self.ui = kvargs.UI;
            end
        end

        function init(self, value)
            %% Initialize progress bar with some value.
            %
            %   So the user knows that something is about to happen.
            arguments
                self (1, 1) lhp.utils.ProgressBar
                value (1, 1) double {mustBeInteger, mustBeNonnegative} = 0;
            end

            if isempty(self.max_value)
                self.update(value, 1);
            else
                self.last_count = value;
                self.update(value, self.max_value);
            end
        end

        function increment(self)
            %% Increment the progress bar by one.
            %
            %   Useful when it is known in advance that the progress bar will be
            %   updated on every increment. The "MaxValue" option must be
            %   specified in the constructor for this to work!
            %
            %   Nothing will happen if attempting to increment beyond the
            %   maximum value.
            if isempty(self.max_value)
                error("Increment only works when 'MaxValue' was specified.");
            end

            self.last_count = self.last_count + 1;
            if self.last_count <= self.max_value
                self.update(self.last_count, self.max_value);
            end
        end

        function update(self, cur_val, max_val)
            %% Update the progress bar as specified.
            %
            %   Prints an updated progress bar. The completion of the bar is
            %   determined based on the input parameters. Note that if you want
            %   to use this class repeatedly for printing progresses for
            %   entirely different processes, you must call "reset()" in
            %   between.
            %
            %   Parameters
            %   ----------
            %   cur_val: integer
            %       The "current value" of the progress that is monitored.
            %   max_val: integer
            %       The final value that the progress will reach upon
            %       completion.

            % Sanity checks
            assert(max_val > 0, ...
                "Final value must be bigger than 0!");
            assert(max_val >= cur_val, ...
                "Can't count progress beyond 100 %%!");

            complete_perc = (cur_val / max_val);

            if (toc(self.last_update_t) < self.update_every)
                if (complete_perc < 1)
                    return;
                end
            end
            self.last_update_t = tic();

            % This line contains numerical information
            first_line = sprintf("%s: %5.2f %%   (%*d / %*d)\n", ...
                self.update_string, complete_perc * 100, ...
                self.widest_number, cur_val, ...
                self.widest_number, max_val);

            if ~isempty(self.ui)
                % UI-based output
                % Remove double "%"
                self.ui.Message = first_line;
                self.ui.Value = complete_perc;
            else
                % Text-based output
                % This is the actual bar
                bar_width = floor((self.window_width - 2) * complete_perc);
                bar = repmat(self.bar_style, 1, bar_width);
                padding = repmat(' ', 1, self.window_width - 2 - bar_width);
                second_line = sprintf("[%s%s]\n", bar, padding);

                % Combine both lines to create the complete progress bar output.
                output = strcat(first_line, second_line);

                self.cli_write_text(output);
            end
        end

        function reset(self)
            self.first_run = true;
            fprintf("%s", self.cli_clear_text());
        end

        function cli_write_text(self, text)
            %% Wrapper around fprintf to write text to CLI.
            %
            %   In order to provide a reasonable terminal UI, we do not just
            %   clear the entire screen every time we update the texts. Instead
            %   we clear only those characters that we ourselves have written
            %   out. In order to accomplish this we must keep track of the
            %   number of characters/newlines written. We differ between
            %   characters and newlines since:
            %
            %   - Matlabs command window is a rather "dumb" terminal in that it
            %     doesn't understand ANSI escape sequences and such. Instead,
            %     here we delete characters using the ASCII backspace '\b',
            %     which deleted exactly one character. Thus we must count how
            %     many characters have been written, which we do here.
            %   - POSIX terminals on the other hand understand ANSI escape
            %     sequences and handle the backspace '\b' differently: A '\b'
            %     can **never** delete a line-break. In other words: Sending an
            %     infinite number of '\b' to a POSIX terminal will only delete
            %     the current line, but never any lines before it. Therefore we
            %     must work with ANSI escape sequences here, and to do this
            %     correctly we need to keep track of how many newlines we've
            %     written, rather than single characters.
            %
            %   This function is tightly coupled with `cli_clear_text`.
            %
            %   See Also
            %   --------
            %   * :meth:`ProgressBar.cli_clear_text`
            erase = self.cli_clear_text();
            self.bytes_written = self.bytes_written ...
                + fprintf("%s%s", erase, text) ...
                - strlength(erase);
            % Get number of newlines for lines_written
            self.lines_written = self.lines_written + ...
                sum(char(text) == newline());
        end
    end

    methods (Access = private)
        function erase = cli_clear_text(self)
            %% Clear text from the Terminal UI.
            %
            %   Clears all text that we have previously printed to the terminal,
            %   and **only this text**. It doesn't delete text that was written
            %   to the TUI before! To clear the text we must adapt the behavior
            %   depending on whether we output to Matlabs command window or a
            %   POSIX terminal.
            %
            %   Matlabs command window can be cleared simply by printing '\b'
            %   for every character previously written by us. Thus we keep track
            %   of the number of characters written in :meth:`cli_write_text`.
            %
            %   POSIX terminals don't allow us to delete line breaks using '\b',
            %   so we use the ANSI escape codes:
            %
            %   * [2K: Clear entire line
            %   * [A: Move line up
            %
            %   to delete as many lines as we have previously written.
            %
            %   To query whether we're running on the Matlab command window, we
            %   query ``usejava('dektop')`` to find out whether matlab is
            %   running in desktop mode.
            %
            %   See Also
            %   --------
            %   * :meth:`ProgressBar.cli_write_text`
            if usejava('desktop')
                erase = repmat(sprintf('\b'), 1, self.bytes_written);
            else
                ESC = char(27);
                DEL_LINE = [ESC, '[2K'];
                LINE_UP = [ESC, '[A'];
                LINE_START = [ESC, '[G'];
                erase = [DEL_LINE, ...
                    repmat([LINE_UP, DEL_LINE], 1, self.lines_written), ...
                    LINE_START];
            end
            %fprintf(erase);
            self.bytes_written = 0;
            self.lines_written = 0;
        end
    end
end

