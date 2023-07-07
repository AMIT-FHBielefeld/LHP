function s = simClust_LMmax_KPmin_LMmin(problem_data)
%% Simultane Clusterbildung -Spezialisierung LM_max, KP_min, MinLaub
%
%   Spezialisierter Aufruf der Funktion 'simultaneous_cluster()' mit
%   vordefinierten Parametern fuer die Key-Value Parameter.
%   Siehe Funktionsdokumentation von simultaneous_cluster fuer mehr
%   Informationen.
%
%       help simultaneous_cluster
    s = lhp.algo.deterministic.simultaneous_cluster.simultaneous_cluster(problem_data, ...
        "AssignmentCandidateSelection", "LM_max", ...
        "ContactCandidateSelection", "KP_min", ...
        "HubStrategy", "MinLaub");
    return;
end
