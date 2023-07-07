function s = simClust_LMmax_LMmin_Impl(problem_data)
%% Simultane Clusterbildung -Spezialisierung LM_max, LM_min, SmallestIndex
%
%   Spezialisierter Aufruf der Funktion 'simultaneous_cluster()' mit
%   vordefinierten Parametern fuer die Key-Value Parameter.
%   Siehe Funktionsdokumentation von simultaneous_cluster fuer mehr
%   Informationen.
%
%       help simultaneous_cluster
    s = lhp.algo.deterministic.simultaneous_cluster.simultaneous_cluster(problem_data, ...
        "AssignmentCandidateSelection", "LM_max", ...
        "ContactCandidateSelection", "LM_min", ...
        "HubStrategy", "SmallestIndex");
    return;
end
