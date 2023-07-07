function s = simClust_NW_NW_KPmin(problem_data)
%% Simultane Clusterbildung -Spezialisierung NW, NW, MinKompost
%
%   Spezialisierter Aufruf der Funktion 'simultaneous_cluster()' mit
%   vordefinierten Parametern fuer die Key-Value Parameter.
%   Siehe Funktionsdokumentation von simultaneous_cluster fuer mehr
%   Informationen.
%
%       help simultaneous_cluster
    s = lhp.algo.deterministic.simultaneous_cluster.simultaneous_cluster(problem_data, ...
        "AssignmentCandidateSelection", "NW", ...
        "ContactCandidateSelection", "NW", ...
        "HubStrategy", "MinKompost");
    return;
end
