% Dieses Skript generiert die einzelnen MATLAB Wrapper-Funktionen fuer den
% simultaneous_cluster Algorithmus. Die Wrapper rufen stets eine spezialisierte
% Variante des Grundalgorithmus (mit fixen Parametern) auf.

FileBaseName = "simClust";
% For the print_heuristics_entry function, the first ID of the algorithm in the
% file.
startEntry = 24;

%% Definition der Parameter
AssCanSel = ["NW", "LM_max", "LM_min", "KP_min"];   % Assignment Candidates
ConCanSel = ["NW", "LM_max", "LM_min", "KP_min"];   % Contact Candidates

% These are the function parameters for hub strategy
HubStrat  = ["SmallestIndex", "MaxLaub", "MinLaub", "MinKompost"];
% These are the names we use in the filenames
HubStratNames = ["Impl", "LM_max", "LM_min", "KP_min"];

%% Varianten der Namen Erzeugen
for acs = AssCanSel
    for ccs = ConCanSel
        for hs_idx = 1:numel(HubStrat)
            func_name = get_func_name(FileBaseName, acs, ccs, HubStratNames(hs_idx));
            fd = make_file(func_name);

            make_header(fd, func_name);
            make_comment(fd, acs, ccs, HubStrat(hs_idx));
            make_function_call(fd, acs, ccs, HubStrat(hs_idx));
            make_footer(fd);

            fclose(fd);

            startEntry = print_heuristics_entry(startEntry, ...
                func_name, acs, ccs, HubStratNames(hs_idx));
        end
    end
end

function func_name = get_func_name(fbn, acs, ccs, hsn)
    func_name = strcat(fbn, "_");
    func_name = strcat(func_name, strrep(acs, "_", ""), "_");
    func_name = strcat(func_name, strrep(ccs, "_", ""), "_");
    func_name = strcat(func_name, strrep(hsn, "_", ""));
    return;
end

function fd = make_file(filename)
    fd = fopen(strcat(filename, ".m"), "w");
    return;
end

function make_header(fd, func_name)
    fprintf(fd, "function s = %s(problem_data)\n", func_name);
    return;
end

function make_comment(fd, acs, ccs, hst)
    fprintf(fd, "%%%% Simultane Clusterbildung -Spezialisierung %s, %s, %s\n", acs, ccs, hst);
    fprintf(fd, "%%\n");
    fprintf(fd, "%%   Spezialisierter Aufruf der Funktion 'simultaneous_cluster()' mit\n");
    fprintf(fd, "%%   vordefinierten Parametern fuer die Key-Value Parameter.\n");
    fprintf(fd, "%%   Siehe Funktionsdokumentation von simultaneous_cluster fuer mehr\n");
    fprintf(fd, "%%   Informationen.\n");
    fprintf(fd, "%%\n");
    fprintf(fd, "%%       help simultaneous_cluster\n");
end

function make_function_call(fd, acs, ccs, hst)
    fprintf(fd, "    s = simultaneous_cluster(problem_data, ...\n");
    fprintf(fd, "        ""AssignmentCandidateSelection"", ""%s"", ...\n", acs);
    fprintf(fd, "        ""ContactCandidateSelection"", ""%s"", ...\n", ccs);
    fprintf(fd, "        ""HubStrategy"", ""%s"");\n", hst);
end

function make_footer(fd)
    fprintf(fd, "    return;\n");
    fprintf(fd, "end\n");
end

function new_id = print_heuristics_entry(id, func_name, acs, ccs, hsn)
    func_readable_name = strcat("SimC-", acs, "-", ccs, "-", hsn);
    fprintf("%d, %s, %s\n", id, func_name, func_readable_name);
    new_id = id + 1;
    return;
end
