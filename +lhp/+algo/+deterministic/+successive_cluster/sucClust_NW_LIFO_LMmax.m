function s = sucClust_NW_LIFO_LMmax(problem_data)
%% Sukzessive Clusterbildung - Spezialisierung NW LIFO LM_max
%
%   Spezialisierter Aufruf der Funktion 'successive_cluster()' mit
%   vordefinierten Parametern fuer die Key-Value Parameter.
%   Siehe Funktionsdokumentation von successive_cluster fuer mehr Informationen.
%
%       help successive_cluster
    s = lhp.algo.deterministic.successive_cluster.successive_cluster(problem_data, ...
        "CandidateSelection", "NW", ...
        "CandidatesListType", "LIFO", ...
        "ClusterSelection", "LM_max");
    return;
end
