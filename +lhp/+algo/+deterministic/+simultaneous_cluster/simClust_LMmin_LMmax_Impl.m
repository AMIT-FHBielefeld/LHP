function s = simClust_LMmin_LMmax_Impl(problem_data)
%% Simultane Clusterbildung -Spezialisierung LM_min, LM_max, SmallestIndex
%
%   Spezialisierter Aufruf der Funktion 'simultaneous_cluster()' mit
%   vordefinierten Parametern fuer die Key-Value Parameter.
%   Siehe Funktionsdokumentation von simultaneous_cluster fuer mehr
%   Informationen.
%
%       help simultaneous_cluster
    s = lhp.algo.deterministic.simultaneous_cluster.simultaneous_cluster(problem_data, ...
        "AssignmentCandidateSelection", "LM_min", ...
        "ContactCandidateSelection", "LM_max", ...
        "HubStrategy", "SmallestIndex");
    return;
end
