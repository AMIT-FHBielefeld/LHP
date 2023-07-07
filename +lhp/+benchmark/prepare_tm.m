function tm = prepare_tm()
    %% Prepare an empty TestManager with gardens for testing
    tm = lhp.utils.TestManager();
    pg = lhp.benchmark.ProblemGenerator();
    
    filters = {{"TreeDensity", 0.05}, ...
               {"TreeDensity", 0.1}};
    % Rake, Transport, Walking
    work_factors = [1, 1, 1; 1, 2, 0.5; 1, 3, 0.25];

    problems = [];
    filter_strings = [];
    for f_idx = 1:numel(filters)
        cur_filt = filters{f_idx};
        [pd, fstr] = pg.retrieve(cur_filt{:});
        
        problems = cat(1, problems, pd');
        filter_strings = cat(1, filter_strings, fstr');
    end
    
    for nentry = 1:numel(filter_strings)
        for abg = work_factors'
            pd = problems(nentry);
            fs = filter_strings(nentry);

            % Apply alpha, beta, gamma
            pd.Rake_Param = abg(1);
            pd.Trans_Param = abg(2);
            pd.Unprod_Param = abg(3);
            fs = sprintf("%s, RP: %.2f, TP: %.2f, UP: %.2f", fs, ...
                pd.Rake_Param, pd.Trans_Param, pd.Unprod_Param);

            tm.addTestCase(pd, fs);
        end
    end
end

