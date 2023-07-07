function s = sucClust_LMmax_FIFO_LMmax(problem_data)
%% Sukzessive Clusterbildung - Spezialisierung LM_max FIFO LM_max
%
%   Spezialisierter Aufruf der Funktion 'successive_cluster()' mit
%   vordefinierten Parametern fuer die Key-Value Parameter.
%   Siehe Funktionsdokumentation von successive_cluster fuer mehr Informationen.
%
%       help successive_cluster
    s = lhp.algo.deterministic.successive_cluster.successive_cluster(problem_data, ...
        "CandidateSelection", "LM_max", ...
        "CandidatesListType", "FIFO", ...
        "ClusterSelection", "LM_max");
    return;
end
