function s = sucClust_LMmax_LIFO_LMmax(problem_data)
%% Sukzessive Clusterbildung - Spezialisierung LM_max LIFO LM_max
%
%   Spezialisierter Aufruf der Funktion 'successive_cluster()' mit
%   vordefinierten Parametern fuer die Key-Value Parameter.
%   Siehe Funktionsdokumentation von successive_cluster fuer mehr Informationen.
%
%       help successive_cluster
    s = lhp.algo.deterministic.successive_cluster.successive_cluster(problem_data, ...
        "CandidateSelection", "LM_max", ...
        "CandidatesListType", "LIFO", ...
        "ClusterSelection", "LM_max");
    return;
end
