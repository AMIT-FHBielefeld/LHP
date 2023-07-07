function s = simClust_LMmax_LMmax_LMmin(problem_data)
%% Simultane Clusterbildung -Spezialisierung LM_max, LM_max, MinLaub
%
%   Spezialisierter Aufruf der Funktion 'simultaneous_cluster()' mit
%   vordefinierten Parametern fuer die Key-Value Parameter.
%   Siehe Funktionsdokumentation von simultaneous_cluster fuer mehr
%   Informationen.
%
%       help simultaneous_cluster
    s = lhp.algo.deterministic.simultaneous_cluster.simultaneous_cluster(problem_data, ...
        "AssignmentCandidateSelection", "LM_max", ...
        "ContactCandidateSelection", "LM_max", ...
        "HubStrategy", "MinLaub");
    return;
end
