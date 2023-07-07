function s = sucClust_NW_FIFO_NW(problem_data)
%% Sukzessive Clusterbildung - Spezialisierung NW FIFO NW
%
%   Spezialisierter Aufruf der Funktion 'successive_cluster()' mit
%   vordefinierten Parametern fuer die Key-Value Parameter.
%   Siehe Funktionsdokumentation von successive_cluster fuer mehr Informationen.
%
%       help successive_cluster
    s = lhp.algo.deterministic.successive_cluster.successive_cluster(problem_data, ...
        "CandidateSelection", "NW", ...
        "CandidatesListType", "FIFO", ...
        "ClusterSelection", "NW");
    return;
end
