function s = simClust_LMmin_KPmin_LMmax(problem_data)
%% Simultane Clusterbildung -Spezialisierung LM_min, KP_min, MaxLaub
%
%   Spezialisierter Aufruf der Funktion 'simultaneous_cluster()' mit
%   vordefinierten Parametern fuer die Key-Value Parameter.
%   Siehe Funktionsdokumentation von simultaneous_cluster fuer mehr
%   Informationen.
%
%       help simultaneous_cluster
    s = lhp.algo.deterministic.simultaneous_cluster.simultaneous_cluster(problem_data, ...
        "AssignmentCandidateSelection", "LM_min", ...
        "ContactCandidateSelection", "KP_min", ...
        "HubStrategy", "MaxLaub");
    return;
end
