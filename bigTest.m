%% Big benchmarking testset.
%
%   This script runs the tests for all available deterministic heuristics on all
%   of the benchmarking problems defined in the `lhp.benchmark` module. Please
%   note that running all of these tests will take a very long time.

clearvars();

fprintf("Generating problems...");
pg = lhp.benchmark.ProblemGenerator("SameStartPerGarden", true, "Seed", 12816);
[problems, filters] = pg.retrieve();
fprintf(" DONE!\n");

%%
opt_max_laub = [false, true];
remove_empty_nodes = [false, true];
post_optimize = ["NONE", "MaxLaub", "MinLaub", "Median", "MinKompost", ...
    "SmallestIndex", "KeepHubs"];

for oml_idx = 1:numel(opt_max_laub)
    oml = opt_max_laub(oml_idx);
    for ren_idx = 1:numel(remove_empty_nodes)
        ren = remove_empty_nodes(ren_idx);
        for po_idx = 1:numel(post_optimize)
            po = post_optimize(po_idx);
            alg_suffix = get_algorithm_suffix(oml, ren, po);
            clc();

            % See if we ran this previously and skip if necessary.
            files = string(strsplit(ls()));
            match = contains(files, alg_suffix);
            if any(match)
                fprintf("\nSkipping test for '%s', as it's already" ...
                    + " available in file '%s'.\n", ...
                    alg_suffix, files(match));
                continue;
            end
            clearvars("files", "match");

            fprintf("Benchmarking for OML: %d; REN: %d; PO: %s\n", ...
                oml, ren, po);

            % Get all deterministic heuristics.
            if po == post_optimize(1)
                det = lhp.algo.DeterministicWrapper.gather(...
                    "OptimizeMaxLaub", oml, ...
                    "RemoveEmptyNodes", ren, ...
                    "StoreResults", false, ...
                    "NameSuffix", alg_suffix);
            else
                det = lhp.algo.DeterministicWrapper.gather(...
                    "OptimizeMaxLaub", oml, ...
                    "RemoveEmptyNodes", ren, ...
                    "PostOptimize", po, ...
                    "StoreResults", false, ...
                    "NameSuffix", alg_suffix);
            end

            % Prepare the TestManager
            tm = lhp.utils.TestManager();

            for p_idx = 1:numel(problems)
                tm.addTestCase(problems(p_idx), filters(p_idx));
            end

            for d_idx = 1:numel(det)
                tm.addAlgorithm(det(d_idx));
            end

            tm.runAllTests();
            tm.flatten();
            filename = sprintf("%s-%s.mat", ...
                datestr(now, "yyyy.mm.dd-HH.MM"), alg_suffix);
            save(filename, "tm", "pg");
        end
    end
end


function suffix = get_algorithm_suffix(oml, ren, po)
    suffix = "";

    suffix = strcat(suffix, "-OML_", string(double(oml)));
    suffix = strcat(suffix, "-REN_", string(double(ren)));
    if isempty(po)
        suffix = strcat(suffix, "-PO_none");
    else
        suffix = strcat(suffix, "-PO_", po);
    end

    return;
end
