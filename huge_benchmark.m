%% Get an empty TestManager with the benchmark gardens

% tm = lhp.benchmark.prepare_tm();
% fprintf("Gardens generated\n");

%% alternatively use a given TestManager
% Datei = "tm_id31"
% load (Datei)

%% Limiting the algorithms to be considered by using a new algorithm.txt
            algfilepath = mfilename("fullpath")
            algfile== [algfilepath filesep '+deterministic' filesep 'algorithms.txt'];
	    newfile== [algfilepath filesep '+deterministic' filesep 'algorithmsneu.txt'];
	    allfile== [algfilepath filesep '+deterministic' filesep 'algorithmsall.txt'];
            copyfile(newfile, algfile);


%% Add the algorithms to the TestManager
ren_range = [false, true];
po_range = ["None", "MaxLaub", "MinLaub", "Median", "MinKompost", "SmallestIndex", "KeepHubs"];
oml_range = [false]; %% Zweiter Durchlauf hier auf true setzen
 
 [a, b, c] = meshgrid(ren_range, po_range, oml_range);
 fact_mat = reshape(cat(4, a, b, c), [], 3)';
 
 for col = fact_mat
     str2bool = @(str) strcmp(str, "true");
     ren = str2bool(col(1));
     po = col(2);
     oml = str2bool(col(3));
     suffix = sprintf("-OML_%d-REN_%d-PO_%s", oml, ren, po);
 
     % Convert PO to proper format
     if strcmp(po, "None")
         po = [];
     end
     
     det = lhp.algo.DeterministicWrapper.gather(...
         "StoreResults", false, ...
         "RemoveEmptyNodes", ren, ...
         "PostOptimize", po, ...
         "OptimizeMaxLaub", oml, ...
         "NameSuffix", suffix);
 
     for idx = 1:numel(det)
         tm.addAlgorithm(det(idx));
     end
 end

%% Run the deterministic tests
 tm.runAllTests();

 tm.flatten();
 save("huge-benchmark-det.mat", "-v7.3", "tm");
 fprintf("Deterministic results stored!\n");

%% Switch to all algorithms 
            algfilepath = mfilename("fullpath")
            algfile== [algfilepath filesep '+deterministic' filesep 'algorithms.txt'];
	    newfile== [algfilepath filesep '+deterministic' filesep 'algorithmsneu.txt'];
	    allfile== [algfilepath filesep '+deterministic' filesep 'algorithmsall.txt'];
            copyfile(allfile, algfile);

%% Add bionic algorithms, rerun
%% Bee-Algorithm

 bee = lhp.algo.stochastic.bee.wrapper("StoreRNG", true, "StorePopulations", false);

 tm.addAlgorithm(bee);

 tm.unflatten();
 ret = tm.runAllTests();
 tm.flatten();

 save("huge-benchmark-bee.mat", "-v7.3", "tm");

fprintf("Bee results stored!\n");

%% Add bionic algorithms, rerun
%% genetic algorithm

 gen = lhp.algo.stochastic.genetic.wrapper("StoreRNG", true, "StorePopulations", false);

 tm.addAlgorithm(gen);

 tm.unflatten();
 ret = tm.runAllTests();
 tm.flatten();

 save("huge-benchmark-gen.mat", "-v7.3", "tm");

fprintf("Genetic results stored!\n");


%% Add heuristic approximation method, rerun
%% Simulated Annealing

 siman = lhp.algo.stochastic.siman.wrapper("StoreRNG", true, "StorePopulations", false);

 tm.addAlgorithm(siman);

 tm.unflatten();
 ret = tm.runAllTests();
 tm.flatten();

 save("huge-benchmark-siman.mat", "-v7.3", "tm");

fprintf("Simulated Annealing results stored!\n");