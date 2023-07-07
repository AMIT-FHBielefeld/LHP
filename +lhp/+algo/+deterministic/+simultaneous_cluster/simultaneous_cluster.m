function s = simultaneous_cluster(problem_data, kvargs)
%SIMULTANEOUS_CLUSTER Simultaneous cluster algorithm.
%
%   This is a heuristic algorithm that was originally thought of and designed by
%   Hermann-Josef Kruse. For a detailed explanation refer to the "Auszug aus
%   Hermanns Erlaeuterungen" section below.
%
%   Parameters
%   ----------
%   problem_data: ProblemData
%       A description of the Problem to be solved.
%
%   Keyword Arguments
%   -----------------
%   'AssignmentCandidateSelection': {'NW', 'LM_max', 'LM_min', 'KP_min'}
%       Criterion for determining the next assignment candidate. Can be one of:
%
%       - 'NW': Take most-northwestern node as assignment candidate
%       - 'LM_max': Take node with most leaves as assignment candidate
%       - 'LM_min': Take node with least leaves as assignment candidate
%       - 'KP_min': Take node with smallest distance to compost as assignment
%         candidate
%   'ContactCandidateSelection': {'NW', 'LM_max', 'LM_min', 'KP_min'}
%       Criterion for determining the next contact candidate. Can be one of:
%
%       - 'NW': Take most-northwestern node as contact candidate
%       - 'LM_max': Take node with most leaves as contact candidate
%       - 'LM_min': Take node with least leaves as contact candidate
%       - 'KP_min': Take node with smallest distance to compost as contact
%         candidate
%   'HubStrategy': {'NW', 'LM_max', 'LM_min', 'KP_min'}
%       Strategy for hub selection in the created node clusters. Can be one of:
%
%       - 'SmallestIndex': Equal to most-northwestern node
%       - 'MaxLaub': Node with most leaves in a cluster becomes hub
%       - 'MinLaub': Node with least leaves in a cluster becomes hub
%       - 'MinKompost': Node with least distance to compost becomes hub
%
%   Returns
%   -------
%   s: vector of double
%       A valid successor-function.
%
%   Notes
%   -----
%   **Auszug aus Hermanns Erlaeuterungen**:
%   Bei der simultanen Clusterbildung bleiben alle zwischenzeitlich entstandenen
%   Cluster durchgehend zur Aufnahme von weiteren Knoten offen
%   ("More-Open-Type"). Dabei wird jeder Knoten genau einmal erfasst und
%   behandelt, wonach sich der jeweilige Erfassungszustand aendert ("noch nicht
%   erfasst" --> "erfasst"). In jedem Schritt wird unter den noch nicht
%   erfassten Knoten [10]_ ein Zuweisungskandidat bestimmt. Als Auswahlkriterium
%   sind viele Moeglichkeiten denkbar. Im VBA-Programm wird der Knoten mit der
%   geringsten Laubmenge unter den noch nicht erfassten Knoten ausgewaehlt
%   (Sekundaerkriterium: Kleinster Index). Dadurch findet eine Knotenabarbeitung
%   nach aufsteigenden Laubmengengroessen statt ( LM min ). Anschliessend wird
%   ein Nachbarknoten des Zuweisungskandidaten als Kontaktkandidat ausgewaehlt.
%   Hierfuer sind ebenfalls verschiedene Auswahlkriterien moeglich. Im
%   VBA-Programm wird der Nachbarknoten mit der groessten Laubmenge als
%   Kontaktkandidat ausgewaehlt (Sekundaerkriterium: Kleinster Index); dabei
%   wird geprueft, ob die Laubmengenobergrenze eingehalten wird; ansonsten wird
%   der Nachbar mit der naechstkleineren Laubmenge geprueft. Wird ein passender
%   Nachbarknoten gefunden, sind fuer das ausgewaehlte Knotenpaar
%   (Zuweisungskandidat & Kontaktkandidat) vier Faelle hinsichtlich ihrer
%   Clusterzugehoerigkeit moeglich:
%
%   (1) Beide Knoten sind noch keinem Cluster zugewiesen.
%       Beide Knoten werden einem neuen Cluster zugewiesen. Entsprechende
%       Zulaessigkeitspruefung: Die beiden Laubmengen zusammen ueberschreiten
%       nicht die Laubmengenobergrenze.
%   (2) Nur der Kontaktkandidat ist einem Cluster zugewiesen. Der
%       Zuweisungskandidat wird dem Cluster des Kontaktkandidaten zugewiesen.
%       Entsprechende Zulaessigkeitspruefung: Die Hinzunahme der Laubmenge des
%       Zuweisungskandidaten zur kumulierten Laubmenge des Clusters vom
%       Kontaktkandidaten ueberschreitet nicht die Laubmengenobergrenze.
%   (3) Nur der Zuweisungskandidat ist einem Cluster zugewiesen.
%       Der Kontaktkandidat wird dem Cluster des Zuweisungskandidaten
%       zugewiesen. Entsprechende Zulaessigkeitspruefung: Die Hinzunahme der
%       Laubmenge des Kontaktkandidaten zur kumulierten Laubmenge des Clusters
%       vom Zuweisungskandidat ueberschreitet nicht die Laubmengenobergrenze.
%   (4) Beide Knoten sind bereits einem Cluster zugewiesen.
%       Im trivialen Fall, dass beide Knoten zum selben Cluster gehoeren, findet
%       keine weitere Zuweisungshandlung statt (ebenso keine
%       Zulaessigkeitspruefung). Andernfalls wird geprueft, ob die kumulierten
%       Laubmengen der beiden Cluster in der Summe die Laubmengenobergrenze
%       nicht ueberschreitet. Dann werden die beiden Cluster vereint; in praxi
%       werden die Knoten aus dem Cluster nicht dem kleineren Clusterindex dem
%       Cluster mit dem groesseren Clusterindex zugewiesen. [11]_
%
%   Falls in einem Erfassungsschritt fuer den aktuellen Zuweisungsknoten kein
%   passender Kontaktkandidat gefunden werden kann, allerdings bereits eine
%   Clusterzuweisung vorliegt, wird keine Zuweisungshandlung vorgenommen.
%   Andernfalls wird ein neues Cluster eroeffnet, bei dem der Zuweisungsknoten
%   als Repraesentant fungiert. Das Verfahren endet, wenn jeder Knoten erfasst
%   worden ist.
%
%   Zur Klasse der Verfahren mit simultaner Clusterbildung gehoeren auch die
%   folgenden modifizierten Fit-Strategien, welche die bekannten Fit-Strategien
%   zur Loesung von eindimensionalen Bin-Packing-Problemen nachahmen ( First
%   Fit, Best Fit ). Hierbei werden die Cluster als Bins, die Knoten als Items
%   und die zugehoerigen Laubmengen als Laengen aufgefasst. Die Bins haben die
%   Laubmengenobergrenze als einheitliche Laenge. [12]_
%
%   Die modifizierte First-Fit-Strategie ( FF_mod ) hat folgenden Ablauf:
%   Jeder Knoten wird in Knotenindexreihenfolge einem Cluster zugewiesen. Dabei
%   wird zunaechst jedes bereits vorhandene Cluster in Clusterindexreihenfolge
%   ueberprueft, ob dafuer genuegend Gap [13]_ im Cluster vorhanden ist. Wenn
%   ja, wird geprueft, ob der aktuelle Knoten zu einem Clusterelement
%   benachbart ist. [14]_ Wenn beide Pruefkriterien erfuellt sind, wird der
%   aktuelle Knoten dem ersten Cluster, fuer das es passt, zugewiesen ("first
%   fit"). Wenn kein Cluster passend ist, wird ein neues Cluster geoeffnet. Bei
%   der Decrease-Variante ( FFD_mod ) werden die Knoten nach absteigender
%   Laubmengengroesse aufgenommen. Ansonsten wird wie beim First-Fit verfahren.
%   [15]_
%
%   Die modifizierte Best-Fit-Strategie ( BFD_mod ) hat folgenden Ablauf:
%   Jede Clustereroeffnung erfolgt mit dem aktuell laubmengengroessten Knoten
%   [16]_ als Repraesentant (vorlaeufiges Hub). [17]_ Es wird unter den noch
%   nicht zugewiesenen Knoten derjenige Knoten gesucht, dessen Aufnahme in ein
%   bestehendes Cluster den geringstmoeglichen Harkaufwand nach sich zieht; dies
%   wird gemessen an der Entfernung zum Repraesentanten. Mit anderen Worten:
%   Jeder Knoten wird in absteigender Laubmengengroesse einem Cluster
%   zugewiesen. Dabei wird fuer einen "Aufnahmekandidaten" der Reihe nach jedes
%   offene Cluster ueberprueft, ob dafuer genuegend Gap im Cluster vorhanden
%   ist. Wenn ja, wird geprueft, ob der aktuelle Knoten zu einem Clusterelement
%   benachbart ist. Falls es mehr als einen solchen "Kontaktknoten" gibt, wird
%   derjenige bestimmt, der die kuerzeste Entfernung zum Repraesentanten hat.
%   Als Vergleichsgroesse fuer die "beste" Clusterzuweisung gilt der minimale
%   zusaetzliche Harkaufwand. Insgesamt wird also das beste Tripel
%   (Aufnahmekandidat, Clusterkandidat, Kontaktknoten) bestimmt.
%
%   References
%   ----------
%   .. [10] Dabei wird (noch) nicht unterschieden, ob der Knoten bereits einem
%       Cluster zugewiesen ist oder nicht.
%   .. [11] Die dadurch entstehenden leeren Cluster werden in einem spaeteren
%       Schritt eliminiert, indem die Clusterindizes entsprechend verringert
%       werden.
%   .. [12] Am Rande sei bemerkt, dass diese Vorgehensweise nur fuer den Fall,
%       dass alle Felder dieselbe Laubmengenobergrenze besitzen, konzipiert ist.
%   .. [13] Gemeint ist die Differenz zwischen maximaler und kumulierter
%       Laubmenge des Clusters.
%   .. [14] In diesem zweiten Pruefkriterium steckt die Modifikation gegenueber
%       der First-Fit-Strategie fuer Bin-Packing-Probleme.
%   .. [15] Da von Anfang an alle Knoten bekannt sind, liegt eine Offene
%       Situation vor, die es gerechtfertigt, auch "Decrease Varianten" als
%       Loesungsstrategien einzubinden.
%   .. [16] D.h. unter allen noch nicht zugewiesenen Knoten.
%   .. [17] Demnach handelt es sich um eine "Decrease-Variante".
    arguments
        problem_data (1, 1) lhp.ProblemData
        kvargs.AssignmentCandidateSelection (1, 1) string {mustBeMember(...
            kvargs.AssignmentCandidateSelection, ...
            ["NW", "LM_max", "LM_min", "KP_min"])} = "LM_min";
        kvargs.ContactCandidateSelection (1, 1) string {mustBeMember(...
            kvargs.ContactCandidateSelection, ...
            ["NW", "LM_max", "LM_min", "KP_min"])} = "LM_max";
        kvargs.HubStrategy (1, 1) string {mustBeMember(...
            kvargs.HubStrategy, ["SmallestIndex", "MaxLaub", "MinLaub", ...
            "MinKompost"])} = "SmallestIndex";
    end


    %% Vorbereitung
    % Initialisiere Nachfolgerfunktion
    s = zeros(numel(problem_data.Garden), 2);
    % Besetze die erste Spalte der Nachfolgerfunktion (Indizes)
    s(:, 1) = 1:size(s, 1);

    % V ist die Menge aller Knoten, die geharkt werden muessen.
    % Hindernisse sind hier explizit ausgeschlossen!
    V = find(problem_data.Garden' >= 0);

    is_visited = ones(numel(problem_data.Garden), 1);
    is_visited(V) = 0;

    % Vermerke den Hub in der Nachfolgerfunktion
%     s(a, 2) = a;

    clusters = struct("nodes", [], "leaves", 0);


    %% 2. Schritt
    while any(is_visited == 0)

        %% 1. Schritt
        % Knoten mit dem kleinsten Index wird zum Hub bestimmt und als aktueller
        % Knoten a betrachtet.
        idx = get_assignment_candidate(problem_data, V, ...
            kvargs.AssignmentCandidateSelection);
        assignment_candidate = idx;
        % Streiche den Knoten aus der Liste
        is_visited(idx) = 1;
        V(V == idx) = [];


        % Hole Laubmenge fuer aktuellen Hub.
        M = problem_data.GMatrix(assignment_candidate, 4);
        % Alloziere eine leere Kandidatenliste
        K = [];

        % Suche alle Nachbarn, die das Kriterium der Laubmenge nicht
        % verletzen
        neighbors = find(problem_data.Adjacency(assignment_candidate, :));
        % Schmeiss alle Nachbarn raus, die nicht in V stehen
        neighbors = neighbors(ismember(neighbors, V));

        % Breche ab, entweder wenn Liste der Knoten leer ist.
        while ~isempty(neighbors)
            %% 2. Schritt
            % Sammle Nachbarn in Liste
            neighbors = get_contact_candidate(neighbors, ...
                problem_data, kvargs.ContactCandidateSelection);
            % Hole Kontaktkandidaten aus der Liste
            contact_candidate = neighbors(1);
            % Loesche den potenziellen Nachbarn.
            neighbors(1) = [];

            contact_M = problem_data.GMatrix(contact_candidate, 4);

            % Wird ein passender Nachbarknoten gefunden, sind fuer das
            % ausgewaehlte Knotenpaar (Zuweisungskandidat & Kontaktkandidat)
            % vier Faelle hinsichtlich ihrer Clusterzugehoerigkeit moeglich

            assignment_cluster = in_cluster(clusters, assignment_candidate);
            contact_cluster = in_cluster(clusters, contact_candidate);

            if (assignment_cluster == 0) && (contact_cluster == 0)
                % 1) Beide Knoten sind noch keinem Cluster zugewiesen.
                %   Beide Knoten werden einem neuen Cluster zugewiesen.
                %   Entsprechende Zulaessigkeitspruefung: Die beiden Laubmengen
                %   zusammen ueberschreiten nicht die Laubmengenobergrenze.
                if (M + contact_M) <= problem_data.Max_Val
                    % Gueltig
                    clusters(end + 1).nodes = ...
                        [assignment_candidate, contact_candidate];
                    clusters(end).leaves = (M + contact_M);
                    break;
                else
                    % Geht nicht, brauche neuen Kontaktkandidaten
                    continue;
                end

            elseif (assignment_cluster == 0) && (contact_cluster ~= 0)
                % 2) Nur der Kontaktkandidat ist einem Cluster zugewiesen.
                %   Der Zuweisungskandidat wird dem Cluster des
                %   Kontaktkandidaten zugewiesen. Entsprechende
                %   Zulaessigkeitspruefung: Die Hinzunahme der Laubmenge des
                %   Zuweisungskandidaten zur kumulierten Laubmenge des Clusters
                %   vom Kontaktkandidaten ueberschreitet nicht die
                %   Laubmengenobergrenze.
                if (M + clusters(contact_cluster).leaves) <= problem_data.Max_Val
                    % Gueltig
                    clusters(contact_cluster).nodes = ...
                        [clusters(contact_cluster).nodes, assignment_candidate];
                    clusters(contact_cluster).leaves = ...
                        (clusters(contact_cluster).leaves + M);
                    break;
                else
                    % Geht nicht, brauche neuen Kontaktkandidaten
                    continue;
                end

            elseif (assignment_cluster ~= 0) && (contact_cluster == 0)
                % 3) Nur der Zuweisungskandidat ist einem Cluster zugewiesen.
                %   Der Kontaktkandidat wird dem Cluster des
                %   Zuweisungskandidaten zugewiesen. Entsprechende
                %   Zulaessigkeitspruefung: Die Hinzunahme der Laubmenge des
                %   Kontaktkandidaten zur kumulierten Laubmenge des Clusters vom
                %   Zuweisungskandidat ueberschreitet nicht die
                %   Laubmengenobergrenze.
                if (contact_M + clusters(assignment_cluster).leaves) <= problem_data.Max_Val
                    % Gueltig
                    clusters(assignment_cluster).nodes = ...
                        [clusters(assignment_cluster).nodes, contact_candidate];
                    clusters(assignment_cluster).leaves = ...
                        (clusters(assignment_cluster).leaves + contact_M);
                    break;
                else
                    % Geht nicht, brauche neuen Kontaktkandidaten
                    continue;
                end

            else
                % 4) Beide Knoten sind bereits einem Cluster zugewiesen.
                %   Im trivialen Fall, dass beide Knoten zum selben Cluster
                %   gehoeren, findet keine weitere Zuweisungshandlung statt
                %   (ebenso keine Zulaessigkeitspruefung). Andernfalls wird
                %   geprueft, ob die kumulierten Laubmengen der beiden Cluster
                %   in der Summe die Laubmengenobergrenze nicht ueberschreitet.
                %   Dann werden die beiden Cluster vereint; in praxi werden die
                %   Knoten aus dem Cluster mit dem kleineren Clusterindex dem
                %   Cluster mit dem groesseren Clusterindex zugewiesen.
                if (assignment_cluster == contact_cluster)
                    % Keine weitere Zuweisungshandlung
                    break;
                else
                    if (clusters(assignment_cluster).leaves + ...
                        clusters(contact_cluster).leaves) <= problem_data.Max_Val
                        % Vereine die beiden Cluster
                        % Finde dazu den kleineren Clusterindex
                        cluster_indexes = [assignment_cluster, contact_cluster];
                        min_idx = min(cluster_indexes);
                        max_idx = max(cluster_indexes);

                        clusters(max_idx).nodes = ...
                            [clusters(max_idx).nodes, clusters(min_idx).nodes];
                        clusters(max_idx).leaves = ...
                            (clusters(max_idx).leaves + clusters(min_idx).leaves);

                        % Make the desserted cluster empty
                        clusters(min_idx).nodes = [];
                        clusters(min_idx).leaves = 0;
                    end
                    break;
                end

            end
        end

        if ~in_cluster(clusters, assignment_candidate)
            % Es gab keinen passenden Kontaktkandidaten.
            % Also eroeffnen wir fuer diesen Knoten ein eigenes Cluster.
            clusters(end+1).nodes = assignment_candidate;
            clusters(end).leaves = M;
        end

        continue;
    end

    if ~in_cluster(clusters, assignment_candidate)
        % Es gab keinen passenden Kontaktkandidaten.
        % Also eroeffnen wir fuer diesen Knoten ein eigenes Cluster.
        clusters(end+1).nodes = assignment_candidate;
        clusters(end).leaves = M;
    end

    biggest_cluster = max(arrayfun(@(struct) (numel(struct.nodes)), clusters));
    cluster_mat = zeros(biggest_cluster, numel(clusters));

    cur_clust_idx = 1;
    for cidx = 1:numel(clusters)
        if isempty(clusters(cidx).nodes)
            cluster_mat(:, end) = [];
            continue;
        end
        cluster_mat(1:numel(clusters(cidx).nodes), cur_clust_idx) = ...
            clusters(cidx).nodes';
        cur_clust_idx = cur_clust_idx + 1;
    end

    s = lhp.utils.hz(problem_data, [], kvargs.HubStrategy, ...
        "Cluster", cluster_mat);
    s(s == 0) = -1;
    return;
end


function index = in_cluster(clusters, node)
    %% Determine if node is assigned to a cluster
    %
    %   Out of the list of available clusters, determine whether the given node
    %   is already part of any cluster.
    %
    %   Returns
    %   -------
    %   index: double
    %       The index of the cluster in which the node is assigned. 0 if node
    %       isn't part of any cluster yet.
    index = 0;
    for idx = 1:numel(clusters)
        if any(clusters(idx).nodes == node)
            index = idx;
            return;
        end
    end
end

function index = get_assignment_candidate(problem_data, V, method)
    %% Bestimme naechsten Zuweisungskandidaten aus Knotenmenge.
    %
    %   Aus einer nutzerdefinierten Menge unbearbeiteter Knoten wird derjenige
    %   ausgesucht, der dem Kriterium "method" enspricht.
    %
    % Parameters
    % ----------
    % problem_data: ProblemData()
    %     Eine Instanz der Klasse ProblemData, die das aktuelle Problem
    %     beschreibt.
    % V: vector of double
    %     Menge aller noch unbearbeiteten Knoten
    % method: string
    %     Ein String, der zur Festlegung des Kandidaten dient.
    %     Gueltige Werte sind:
    %       - "NW": Kntoen mit kleinstem Index
    %       - "LM_max": Knoten mit meistem Laub
    %       - "LM_min": Knoten mit wenigstem Laub
    %       - "KP_min": Knoten mit geringster Entfernung zum Kompost
    %
    % Returns
    % -------
    % index
    %     Den Index des naechsten Zuweisungskandidaten

    switch (method)
        case "NW"
            % Hole den naechsten Knoten aus der Knotenliste.
            index = V(1);
        case "LM_max"
            % Hole den Knoten mit dem meisten Laub
            [~, index] = max(problem_data.GMatrix(V, 4));
            index = V(index);
        case "LM_min"
            % Hole den Knoten mit dem wenigsten Laub
            [~, index] = min(problem_data.GMatrix(V, 4));
            index = V(index);
        case "KP_min"
            % Hole Knoten mit kleinster Distanz zum Kompost
            [~, index] = min(problem_data.DMatrix(problem_data.Target, V));
            index = V(index);
        otherwise
            error("Method not implemented!");
    end
    return;
end

function neighbors = get_contact_candidate(neighbors, problem_data, method)
    %% Sortiere die Nachbarliste nach einem gegebenen Kriterium.
    %
    %   Das Kriterium bestimmt, wie die Liste sortiert wird.
    %
    %   Parameter
    %   ---------
    %   neighbors: vector
    %       Ein Vektor mit Knoten-Indizes, der gueltige Nachbarn beinhaltet.
    %       Dieser Vektor wird sortiert zurueck gegeben.
    %   problem_data: ProblemData
    %       Problembeschreibung, notwendig zum sortieren der Nachbarn
    %   method: string
    %       'NW': Sortiert die Nachbarknoten nach dem Index aufsteigend, dass
    %           der Knoten mit dem kleinsten Index an erster Stelle steht.
    %       'LM_max': Sortiert die Nachbarknoten nach der Laubmenge absteigend.
    %           Der erste Knoten in der Liste hat somit das meiste Laub
    %       'LM_min': Sortiert die Nachbarknoten nach der Laubmenge aufsteigend.
    %           Der erste Knoten in der Liste hat somit das wenigste Laub
    %       'KP_min': Sortiert die Nachbarknoten nach der Entfernung zum
    %           Kompost aufsteigend
    switch (method)
        case "NW"
            % Sortiere Nachbarn nach kleinstem Index
            neighbors = sort(neighbors, "ascend");
        case "LM_max"
            [~, to_sort] = sort(problem_data.GMatrix(neighbors, 4), "descend");
            neighbors = neighbors(to_sort);
        case "LM_min"
            [~, to_sort] = sort(problem_data.GMatrix(neighbors, 4), "ascend");
            neighbors = neighbors(to_sort);
        case "KP_min"
            [~, to_sort] = sort(problem_data.DMatrix(neighbors, ...
                problem_data.Target), "ascend");
            neighbors = neighbors(to_sort);
        otherwise
            error("Method not implemented!");
    end
    return;
end
