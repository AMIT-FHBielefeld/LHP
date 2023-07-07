classdef testScriptUtils
    %TESTSCRIPTUTILS Utilities for the testScript.
    %
    %   This class is a wrapper around some utility function for the testScript.
    %   Currently it mainly serves the purpose of loading/saving testresults for
    %   the user in a uniform and reproducible manner. The class isn't meant to
    %   be instantiated, it can be thought of as a sort of namespace like in
    %   Python or C++ that contains functions to use.
    %
    %   It's main purpose as of currently is guarding test executions like
    %   this:
    %
    %   .. code-block:: matlab
    %
    %       % If returns true, test results for test x.y have been loaded
    %       if ~testScriptUtils.loadTest(x, y)
    %           % Resutls don't exist yet, execute test x.y
    %           % Save all data that will be needed by the evaluation
    %           testScriptUtils.saveTest(x, y, "Names", "of", "Variables");
    %       end
    %       % Perform evaluations such as plotting the data here
    %
    %   This allows the user to easily prevent the testScript from running all
    %   tests unless necessary. The users can exchange test results and store
    %   them for later reuse. This allows the quick generation of the
    %   interactive MATLAB plots, as well as introspection into the test
    %   results without having to perform the full test in advance (Which,
    %   depending on the test, may run for several hours).
    %
    %   These actions could, in theory, be performed manually through "save" and
    %   "load" statements, but this approach can become a burden to the user
    %   quickly, especially if naming conventions don't exist and the files are
    %   scattered around multiple places in the filesystem. It is thus advisable
    %   to use this function.

    properties (Constant, Access=private)
        % Path in which to store results/load results from.
        % The path mustn't have a trailing "/" character!
        testresult_path = "Ergebnisse/testScript_tests";
        % Names of global variables for persistent storage
        global_donotload        = "TESTSCRIPTUTILS_DONOTLOAD";
        global_loadmostrecent   = "TESTSCRIPTUTILS_LOADMOSTRECENT";
    end

    methods (Static)
        function filename = saveTest(major, minor, varargin)
            %SAVETEST Store variables to a given test on disk.
            %
            %   This function is invoked similar to the regular 'save()' Matlab
            %   function. It acts as a wrapper around the call to save to enable
            %   functions to store data that don't have direct access to the
            %   base workspace. It also makes sure that all stored datasets have
            %   a sensible filename.
            %
            %   Parameters
            %   ----------
            %   major: unsigned int
            %       A major number that identifies a set of tests. Refer to the
            %       testScript.mlx.
            %   minor: unsigned int
            %       A minor number that uniquely identifies a specific test in a
            %       major number test group. Refer to the testScript.mlx.
            %   varargin: string
            %       An arbitrarily long list of strings, where each string is
            %       the name of a variable that exists in the Matlab 'base'
            %       workspace.
            %
            %   Returns
            %   -------
            %   filename: string
            %       The name of the file where the data was stored. The default
            %       storage directory in which the files are created is stored
            %       in the 'testresult_path' variable in this class.
            %
            %   Example
            %   -------
            %   >> testScriptUtils.saveTest(2, 3, "var1", "var2", "var3", ...);
            arguments
                major (1, 1) double {mustBePositive, mustBeInteger}
                minor (1, 1) double {mustBePositive, mustBeInteger}
            end
            arguments (Repeating)
                varargin (1, :) string
            end

            args = [];
            for varg_idx = 1:numel(varargin)
                varstr = varargin{varg_idx};
                if ~evalin('base', sprintf("exist('%s', 'var')", varstr))
                    error("Variable '%s' doesn't exist in base workspace!\n", ...
                        varstr);
                end

                vartype = evalin('base', sprintf("class('%s')", varstr));
                switch (vartype)
                    case 'TestManager'
                        % If we get a reference to a TestManager we flatten it
                        % to reduce the memory consumption.
                        evalin('base', sprintf("%s.flatten()", varstr));
                    otherwise
                        % pass
                end

                args = [args, varstr]; %#ok<AGROW>
            end

            % Compose a filename out of the test major/minor numbers and the
            % current date/time.
            filename = strcat(...
                sprintf("Test-%d-%d_", major, minor), ...
                datestr(now, "yyyy.mm.dd-HH.MM"), ...
                ".mat");

            % Store data in the v7.3 format to allow for arbitrarily sized
            % data to be stored/restored on 64 Bit Systems.
            evalin('base', sprintf("save('%s/%s', '%s', '-v7.3')", ...
                testScriptUtils.testresult_path, filename, strjoin(args, "', '")))

            return;
        end

        function true_false = loadTest(major, minor)
            %LOADTEST Load variables for a given test, if possible.
            %
            %   This function reads in mat files that were previously created
            %   with the saveTest() method of this class and restores them to
            %   the Matlab 'base' workspace. If a given test major/minor number
            %   doesn't exist, it fails gracefully. If, for a given major/minor
            %   test, multiple mat-files have been created, it prompts the user
            %   to select one.
            %   The specific behavior of this function can be modified through
            %   the 'loadTestSettings()' function in various ways. The user is
            %   encouraged to read the documentation.
            %
            %   Parameters
            %   ----------
            %   major: unsigned int
            %       A major number that identifies a set of tests. Refer to the
            %       testScript.mlx.
            %   minor: unsigned int
            %       A minor number that uniquely identifies a specific test in a
            %       major number test group. Refer to the testScript.mlx.
            %
            %   Returns
            %   -------
            %   true if a valid .mat file has been found and loaded into the
            %   workspace, false otherwise.
            arguments
                major (1, 1) double {mustBePositive, mustBeInteger}
                minor (1, 1) double {mustBePositive, mustBeInteger}
            end

            if testScriptUtils.get_global(testScriptUtils.global_donotload, true)
                true_false = false;
                return;
            end

            true_false = true;
            % FIXME: Due to the callback structure we can't avoid passing data
            % around. However, because this is a static class (i.e. we don't use
            % objects), we can't store data in here. Thus we store a variable in
            % global workspace.
            clearvars("-global", "file_table"); % Make sure it's empty.
            global file_table;

            filename_prefix = sprintf("Test-%d-%d_", major, minor);
            files = dir(strcat(testScriptUtils.testresult_path, ...
                filesep , filename_prefix, "*"));

            if isempty(files)
                % We haven't stored results for that test yet.
                true_false = false;
                return;
            end

            if numel(files) == 1
                chosen_file = strcat(files.folder, filesep , files.name);
                testScriptUtils.loadTestImport(chosen_file);

                return;
            elseif numel(files) > 1
                % We have more than one file for this test.
                file_table = struct2table(files);
                try
                    file_table.date = datetime(file_table.date);
                catch
                    file_table.date = datetime(file_table.date, ...
                        "Locale", "system");
                end
                % Sort the table such that the most recent result is up top.
                file_table = sortrows(file_table, "date", 'descend');
                % Check if user wants to read only the most recent files...
                if testScriptUtils.get_global(...
                        testScriptUtils.global_loadmostrecent, true)
                    chosen_file = strcat(file_table.folder{1}, filesep , ...
                        file_table.name{1});
                    testScriptUtils.loadTestImport(chosen_file);

                    return;
                end

                % Create an empty column in the table that stores previously
                % determined descriptions.
                file_table.Descriptions = repmat("", size(file_table, 1), 1);

                % Open a dialog and let the user choose one.
                uifig = uifigure('Name', 'Select a file', ...
                    'CloseRequestFcn', ...
                        @(uifig, event) testScriptUtils.loadTestCloseUifig(...
                        uifig, file_table));
                uifig.Position(3:4) = [480, 320];

                grid = uigridlayout(uifig);
                grid.RowHeight = {40, '1x'};
                grid.ColumnWidth = {200, '1x'};

                % For the text area we need some monospaced font, otherwise
                % the formatting goes haywire and we can't read anything.
                all_fonts = listfonts();
                mono_fonts = all_fonts(~cellfun(@isempty, ...
                    regexpi(all_fonts, "\smono")));
                if isempty(mono_fonts)
                    error("Couldn't find monospaced fonts on your system!\n");
                end

                txa = uitextarea(grid, ...
                    'Editable', 'off', ...
                    'FontName', mono_fonts{1});
                txa.Layout.Row = 2;
                txa.Layout.Column = [1, 2];

                dd = uidropdown(grid, ...
                    'Items', file_table.name, ...
                    'Value', 1, ...
                    'ItemsData', (1:size(file_table, 1)), ...
                    'ValueChangedFcn', ...
                        @(dd, event) testScriptUtils.update_text(dd, txa, file_table));
                dd.Layout.Row = 1;
                dd.Layout.Column = 1;

                panel = uipanel(grid, ...
                    'BorderType', 'none');
                panel.Layout.Row = 1;
                panel.Layout.Column = 2;
                uibutton(panel, ...
                    'Text', 'Import', ...
                    'ButtonPushedFcn', @(btn, event) close(uifig), ...
                    'Position', [5, 5, 100, 25]);

                % Trigger the first reload.
                testScriptUtils.update_text(dd, txa, file_table);

                uiwait(uifig);
            end
        end

        function str = testInfo(filename)
            %TESTINFO Print some information about a specific .mat testfile.
            %
            %   Given a filename of filepath to a .mat file that was previously
            %   created with this class, this function will print some useful
            %   info about the matfile such as:
            %
            %   - The path to the file
            %   - The creation date and time
            %   - The total site of the file
            %   - The variables that are stored inside
            %
            %   Parameters
            %   ----------
            %   filename: string
            %       A full path to a .mat file that is to be inspected.
            %
            %   Returns
            %   -------
            %   str: string
            %       A formatted string that gives the user information about a
            %       chosen file. Can be passed to fprintf() for display in the
            %       command window or similar.
            arguments
                filename (1, 1) string
            end

            if ~exist(filename, "file")
                error("File %s doesn't exist?!", filename);
            end
            try
                myfile = dir(filename);
            catch
                % That didn't work... Try with the filepath appended?
                filename = strcat(testScriptUtils.testresult_path, "/", ...
                    filename);
                myfile = dir(filename);
            end
            str = "";
            str = str + sprintf(...
                " Filename: %s \n" + ...
                " Directory: %s \n" + ...
                " Creation Date: %s \n" + ...
                " Filesize: %d Bytes \n", ...
                myfile.name, myfile.folder, myfile.date, myfile.bytes);

            % Open matfile read-only
            mf = matfile(filename, "Writable", false);
            varinfo = whos(mf);
            % Get longest var name
            longest_name = max(cellfun(@strlength, {varinfo.name}));

            str = str + sprintf("\n Contents: \n");
            str = str + sprintf(" %*s |  Size   |    Bytes     | Class \n", ...
                longest_name, "Name");
            str = str + sprintf(" %s-+---------+--------------+-------\n", ...
                strjoin(repmat("-", 1, longest_name), ""));
            for idx = 1:numel(varinfo)
                varsize = varinfo(idx).size;
                if isempty(varsize)
                    varsize = [0, 0];
                end

                str = str + sprintf(...
                    " %*s | %-3dx%-3d | %12d | %s \n", ...
                    longest_name, varinfo(idx).name, varsize(1), varsize(2), ...
                    varinfo(idx).bytes, varinfo(idx).class);
            end
        end

        function loadTestSettings(kvargs)
            %LOADTESTSETTINGS Modify settings for test loading behavior.
            %
            %   This function modifies the behavior/settings for loading tests
            %   through the laodTest() function. All settings are stored in
            %   global variables, thus a call to 'clear all' or 'clearvars
            %   -global' or similar WILL ERASE ALL SETTINGS. Use these commands
            %   with care.
            %   The global variables are necessary as this class only
            %   facilitates static functions and isn't meant to be used in an
            %   object-like fashion.
            %
            %   Keyword Arguments
            %   -----------------
            %   'LoadMostRecent': logical, default: false
            %       If set to true, and the user requests to load a test for
            %       which multiple datasets exist, the most recently created
            %       dataset will be loaded without asking the user to specifiy a
            %       dataset to load. This will prevent the selection UI from
            %       opening and is thus suitable for batch-mode applications
            %       where applications run unsupervised.
            %       If set to false (default), the UI dialog will be opened to
            %       ask the user which dataset to load.
            %   'DoNotLoad': logical, default: false
            %       It set to true, a call to 'loadTest()' will always return
            %       false unconditionally. This can be used to rerun tests in
            %       batch mode for which datasets already exist.
            %       If set to false, the 'loadTest()' function will be executed
            %       as expected.
            arguments
                % Linked to: TESTSCRIPTUTILS_LOADMOSTRECENT
                kvargs.LoadMostRecent (1, 1) logical
                % Linked to: TESTSCRIPTUTILS_DONOTLOAD
                kvargs.DoNotLoad (1, 1) logical
            end
            global TESTSCRIPTUTILS_LOADMOSTRECENT;
            global TESTSCRIPTUTILS_DONOTLOAD;

            if isfield(kvargs, "LoadMostRecent")
                TESTSCRIPTUTILS_LOADMOSTRECENT = kvargs.LoadMostRecent;
            end
            if isfield(kvargs, "DoNotLoad")
                TESTSCRIPTUTILS_DONOTLOAD = kvargs.DoNotLoad;
            end
        end
    end

    methods (Access=private, Static)
        function update_text(drop_down, text_area, ~)
            %UPDATE_TEXT Callback function for loadTest UIWindow.
            %
            %   This callback belongs to the UIwindow that is opened by the
            %   loadTest() function when more than one .mat file for a given
            %   test exists already. The callback is triggered whenever the user
            %   selectes a different file from the Drop-Down menu.
            %
            %   It updates the text area in the UI with the information about
            %   the queried test. The information is taken directly from the
            %   testInfo() function return value. Upon first lookup of
            %   information for a test it queries the function and then stores
            %   the result for faster subsequent access.
            %
            %   Parameters
            %   ----------
            %   drop_down: uidropdown
            %       The Dropdown menu that the user has interacted with.
            %   text_area: uitextarea
            %       The text area where text is to be displayed.
            %   unused: unused
            %
            %   Note
            %   ----
            %   For fast subsequent access this function accesses the
            %   "file_table" variable that is (as of currently) stored as a
            %   global variable to allow access across functions. It was
            %   initially supposed to be the third function parameter, but as
            %   Matlab doesn't have a concept of pointers, we use global
            %   variables instead.
            entry = drop_down.Value;
            if ~isnumeric(entry)
                fprintf("Not a number: %s \n", entry);
            end

            % Import current table from calling workspace.
            global file_table;

            if strlength(file_table.Descriptions(entry)) > 0
                text_area.Value = file_table.Descriptions(entry);
            else
                % The data isn't present yet. We must load it first.
                % This process takes time, so display a loading bar to the user
                % so they know the app hasn't died.
                text_area.Visible = 'off';
                parent_uifig = text_area.Parent.Parent;
                progbar = uiprogressdlg(parent_uifig, ...
                    'Title', 'Retrieving data...', ...
                    'Indeterminate', 'on');

                desc = testScriptUtils.testInfo(...
                    strcat(file_table.folder{entry}, "/", ...
                    file_table.name{entry}));

                % Laoding is done, restore the text area.
                close(progbar);
                text_area.Visible = 'on';

                file_table.Descriptions(entry) = desc;
                text_area.Value = desc;
            end
        end

        function loadTestCloseUifig(uifig, file_table)
            %LOADTESTCLOSEUIFIG Called when the user closes the UI in loadTest()
            %
            %   This function reads out the file the user chose and closes the
            %   uiwindow properly. It is called upon invocation of the close()
            %   function on the uifig. This means that it is also called when
            %   the user clicks the 'x' button of the UIWindow. This can only be
            %   circumvented by calling 'delete(uifig)' directly.
            chosen_idx = uifig.Children.Children(2).Value;
            chosen_file = strcat(file_table.folder{chosen_idx}, "/", ...
                            file_table.name{chosen_idx});
            testScriptUtils.loadTestImport(chosen_file);

            % Data imported, close the UI.
            delete(uifig);

            return;
        end

        function loadTestImport(file)
            %LOADTESTIMPORT  Import a given .mat file in 'base' workspace.
            %
            %   Given a valid filename + path, this function imports the .mat
            %   file into the base workspace.
            evalin('base', sprintf('load("%s")', file));
            return;
        end

        function true_false = get_global(name, value)
            %IS_GLOBAL Check if a global variable exists and it's value.
            %
            %   Checks if a global variable with a given name exists and if so,
            %   which value it has.
            %
            %   Parameters
            %   ----------
            %   name: string
            %       The name of the variable to check for.
            %   value:
            %       A value for which to check a variable.
            %
            %   Returns
            %   -------
            %   true_false: logical
            %       Returns false if either a global variable by the given name
            %       doesn't exist, or if the variables value doesn't match the
            %       expected value.
            %       Returns true only if the specific variable exists and has
            %       the expected value.
            arguments
                name (1, 1) string
                value (1, 1)
            end

            true_false = false;
            var_struct = whos("global", name);

            if ~isempty(var_struct)
                % Variable exists
                if strcmpi(class(value), var_struct.class)
                    % Variable types match
                    eval(sprintf("global %s", name));
                    globvar_value = eval(sprintf("%s", name));
                    true_false = (globvar_value == value);
                    return;
                end
            end

            return;
        end
    end
end

