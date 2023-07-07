function s = sucClust_LMmin_FIFO_KPmin(problem_data)
%% Sukzessive Clusterbildung - Spezialisierung LM_min FIFO KP_min
%
%   Spezialisierter Aufruf der Funktion 'successive_cluster()' mit
%   vordefinierten Parametern fuer die Key-Value Parameter.
%   Siehe Funktionsdokumentation von successive_cluster fuer mehr Informationen.
%
%       help successive_cluster
    s = lhp.algo.deterministic.successive_cluster.successive_cluster(problem_data, ...
        "CandidateSelection", "LM_min", ...
        "CandidatesListType", "FIFO", ...
        "ClusterSelection", "KP_min");
    return;
end
