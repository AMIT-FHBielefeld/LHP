function s = simClust_KPmin_NW_LMmin(problem_data)
%% Simultane Clusterbildung -Spezialisierung KP_min, NW, MinLaub
%
%   Spezialisierter Aufruf der Funktion 'simultaneous_cluster()' mit
%   vordefinierten Parametern fuer die Key-Value Parameter.
%   Siehe Funktionsdokumentation von simultaneous_cluster fuer mehr
%   Informationen.
%
%       help simultaneous_cluster
    s = lhp.algo.deterministic.simultaneous_cluster.simultaneous_cluster(problem_data, ...
        "AssignmentCandidateSelection", "KP_min", ...
        "ContactCandidateSelection", "NW", ...
        "HubStrategy", "MinLaub");
    return;
end
