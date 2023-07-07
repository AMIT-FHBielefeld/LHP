function s = successive_cluster(problem_data, kvargs)
%% Sukzessive Clusterorienterte Laubhark-Verfahren.
%
%   Fuer eine Beschreibung des Verfahrens, siehe "Auszug aus Hermanns
%   Erlaeuterungen" weiter unten in dieser Dokumentation.
%
%   Parameters
%   ----------
%   problem_data: ProblemData()
%       An instance of class ProblemData that fully defines a garden to be
%       worked on and all of the constraints required.
%       This is used as the sole source of all information.
%
%   Keyword Arguments
%   -----------------
%   'CandidateSelection': {'NW', 'LM_max', 'LM_min'}
%       Criterium to sort candidates of the current node by. Equivalent to the
%       items in the second enumeration in the text below,
%       "Reihenfolgekriterium der Nachfolgerknoten". Possible values are:
%
%       - 'NW': Sort candidates by their node index alone (Always choose the
%         most "northwestern" one first).
%       - 'LM_max': Sort candidate nodes by their amount of leaves in descending
%         order, i.e. the node with the highest amount of leaves is handled
%         first.
%       - 'LM_min': Like LM_max but sorts in ascending order, i.e. the node with
%         the smallest amount of leaves if handled first.
%   'CandidatesListType': {'FIFO', 'LIFO'}
%       Type of list in which candidates are stored for later use. Possible
%       values are:
%
%       - 'FIFO': Use a first-in-first-out list (Queue)
%       - 'LIFO': Use a last-in-first-out list (Stack)
%   'ClusterSelection':
%       Specifies which node in the created clusters to use as cluster hub.
%       Equivalent to the items in the third enumeration in the text below.
%
%       - 'NW': Use the node with the lowest index.
%       - 'LM_max': Use the node with the highest amount of leaves.
%       - 'KP_min': Use the node with the shortest distance to the compost.
%
%   Returns
%   -------
%   s: Vector
%       A 2-column vector that defines the ..Nachfolgerfunktion''.
%       The first column enumerates all the field indices of the garden
%       defined in problem_data (interpreted as 1-D Vector), the second
%       column describes from which field the leaves are raked to the first
%       field.
%
%   Notes
%   -----
%   **Auszug aus Hermanns Erlaeuterungen**:
%   Bei der sukzessiven Clusterbildung wird zunaechst durchgaengig ein aktuelles
%   Cluster betrachtet, welches durch die Zuweisung von geeigneten Knoten
%   ,,vervollstaendigt'' wird, bevor ein neues Cluster in Augenschein genommen
%   wird (,,1-Open-Type''). Hierbei wird ein noch nicht zugewiesener Knoten als
%   Repraesentant ausgewaehlt [1]_, welcher das Cluster ,,eroeffnet''. Dann
%   werden schrittweise ,,passende'' Knoten dem aktuellen Cluster hinzugefuegt,
%   bis kein solcher Knoten mehr zu finden ist. Ob ein Knoten fuer die Aufnahme
%   in das aktuelle Cluster ,,passend'' ist oder nicht, wird anhand der
%   folgenden ,,Fit-Kriterien'' ueberprueft:
%
%   (1) Der Aufnahmekandidat ist noch keinem Cluster zugewiesen.
%   (2) Der Aufnahmekandidat muss mit einem im aktuellen Cluster befindlichen
%       Knoten benachbart sein.
%   (3) Durch die Hinzunahme der Laubmenge des Aufnahmekandidaten zur bisherigen
%       Laubmengensumme im Cluster darf die maximal erlaubte Laubmenge M nicht
%       ueberschritten werden.
%
%   Wenn mehrere Knoten diese Fit-Kriterien erfuellen und somit mehrere
%   Aufnahmekandidaten in Frage kommen, muss ein eindeutiges Aufnahmekriterium
%   ueber die konkrete Zuweisung entscheiden. Hier bietet sich das eindeutige
%   ,,Kleinster-Index-Kriterium'' an, d.h. unter allen Aufnahmekandidaten wird
%   der Knoten mit dem kleinsten Knotenindex gewaehlt. Aber auch die
%   Laubmengengroesse kann ein Kriterium sein.
%
%   Fuer die Implementierung dieser Kriterien bietet es sich an, dafuer eine
%   Kandidatenliste aufzustellen und abzuarbeiten. Die folgenden Vorgehensweisen
%   werden im VBA-Programm praktiziert: Sobald ein Kandidat dem aktuellen
%   Cluster zugewiesen worden ist [2]_, werden alle Nachbarknoten des Kandidaten
%   in einer bestimmten Reihenfolge geprueft, ob sie bereits einem Cluster
%   zugewiesen sind. Wenn nicht, werden sie der Kandidatenliste zugefuegt. Dabei
%   sind mehrere Reihenfolgekriterien implementiert:
%
%   (1) nach aufsteigendem Knotenindex (Nordwest-Ecken- oder
%       Kleinster-Index-Regel, kurz: NW )
%   (2) nach absteigenderLaubmengengroesse ( LM_max )
%   (3) nach aufsteigender Laubmengengroesse ( LM_min )
%
%
%   Zudem ist zu unterscheiden, ob es sich um eine Schlangenliste (FIFO =
%   First In - First Out) oder um eine eine Stapelliste (LIFO = Last In -
%   First Out) handelt. Mit der Verwendung einer Schlangen- bzw. Stapelliste
%   geht eine Breiten- bzw. Tiefensuche ( BS bzw. TS ) einher, wodurch sich
%   Cluster in ,,Kugelform'' bzw. ,,Sternform'' bilden. Je nach Listentyp wird
%   der naechste Kandidat der Liste entnommen und auf das dritte Fit-Kriterium
%   hin geprueft [3]_. Sobald die Kandidatenliste leer ist, aber noch nicht
%   alle Knoten eine Clusterzuweisung erhalten haben, wird ein neues Cluster
%   eroeffnet.  Schliesslich spielt bei der Clusterbildung [4]_ auch die
%   Repraesentantenwahl eine wesentliche Rolle. Hier bieten sich drei
%   Moeglichkeiten an [5]_: Gewählt wird unter den noch nicht zugewiesenen
%   Knoten
%
%   (1) der ,,nordwestlichste'' Knoten ( NW ). [6]_
%   (2) der Knoten mit der groessten Laubmenge ( LM_max ). [7]_
%   (3) der Knoten mit der geringsten Entfernung zum Kompostknoten ( KP_min ).
%       [8]_
%
%
%   References
%   ----------
%   .. [1] Durch die Wahl dieser Repraesentanten erfolgt eine implizite
%       Hubbestimmung, da diese ausgewaehlten Knoten die Rolle von vorlaeufigen
%       Hubs annehmen.
%   .. [2] Dies gilt anfaenglich für den Repraesentanten. Der zugewiesene
%       Kandidat wird aus der Kandidatenliste entfernt.
%   .. [3] Man beachte, dass die Ueberpruefung der ersten beiden Fit-Kriterien
%       bereits bei der Aufnahme in die Kandidatenliste erfolgt ist.
%
%   .. [4] Dies betrifft sowohl die sukzessive als auch bei die simultane
%       Clusterbildung.
%   .. [5] Die hier vorgestellten Moeglichkeiten werden im VBA-Programm
%       eingesetzt. Weitere Moeglichkeiten sind denk- und realisierbar.
%   .. [6] Gemeint ist der am meisten westlich liegende unter den am meisten
%       noerdlich liegenden Knoten. Aufgrund der vereinbarten Knotenindizierung
%       ist diese ,,Nordwestecken-Regel'' (NW) identisch mit der
%       Kleinster-Index-Regel.
%   .. [7] Die Eindeutigkeit wird ggf. durch die Kleinster-Index-Regel als
%       Sekundaerkriterium hergestellt.
%   .. [8] Auch hier wird die Eindeutigkeit ggf. durch die Kleinster-Index-Regel
%       als Sekundaerkriterium sichergestellt.
    arguments
        problem_data (1, 1) lhp.ProblemData
        kvargs.CandidateSelection (1, 1) string {mustBeMember(...
            kvargs.CandidateSelection, ["NW", "LM_max", "LM_min"])} = "NW";
        kvargs.CandidatesListType (1, 1) string {mustBeMember(...
            kvargs.CandidatesListType, ["FIFO", "LIFO"])} = "FIFO";
        kvargs.ClusterSelection (1, 1) string {mustBeMember(...
            kvargs.ClusterSelection, ["NW", "LM_max", "KP_min"])} = "NW";
    end


    %% Vorbereitung
    % Initialisiere Nachfolgerfunktion
    s = zeros(numel(problem_data.Garden), 2);
    % Besetze die erste Spalte der Nachfolgerfunktion (Indizes)
    s(:, 1) = 1:size(s, 1);

    % V ist die Menge aller Knoten, die geharkt werden muessen.
    % Hindernisse sind hier explizit ausgeschlossen!
    V = find(problem_data.Garden' >= 0);


    %% 1. Schritt
    % Knoten mit dem kleinsten Index wird zum Hub bestimmt und als aktueller
    % Knoten a betrachtet.
    idx = get_next_cluster(problem_data, V, kvargs.ClusterSelection);
    a = idx;
    % Streiche den Knoten aus der Liste
    V(V == idx) = [];
    % Vermerke den Hub in der Nachfolgerfunktion
    s(a, 2) = a;


    %% 2. Schritt
    % Alle Nachbarknoten des aktuellen Knotens werden gemaess der
    % Indexreihenfolge als ,,Kandidaten'' ueberprueft. Falls der Harkprozess
    % von einem Nachbarknoten zum aktuellen Knoten unter Beachtung der
    % maximal erlaubten Laubmenge zulaessig ist, wird dieser Harkschritt
    % registriert und der Nachbarknoten in eine ,,Kandidatenliste'' (K)
    % aufgenommen, welche als Schlangenspeicher betrachtet wird (FIFO-Prinzip).

    while ~isempty(V)
        % Hole Laubmenge fuer aktuellen Hub.
        M = problem_data.GMatrix(a, 4);
        % Alloziere eine leere Kandidatenliste
        K = [];

        % Breche ab, entweder wenn Liste der Knoten leer ist.
        while ~isempty(V)
            %% 2. Schritt
            % Suche alle Nachbarn, die das Kriterium der Laubmenge nicht
            % verletzen
            neighbors = find(problem_data.Adjacency(a, :));
            % Schmeiss alle Nachbarn raus, die nicht in V stehen
            neighbors = neighbors(ismember(neighbors, V));
            % Sammle Nachbarn in Liste
            neighbors = sort_neighbors(neighbors, problem_data, ...
                kvargs.CandidateSelection);

            for candidate = neighbors
                % Berechne die neue Laubmenge mit diesem Kandidaten
                leafs = M + problem_data.GMatrix(candidate, 4);
                % Pruefe, ob Bedingung nicht verletzt wird
                if leafs <= problem_data.Max_Val
                    % Fuege gueltigen Kandidaten an Kandidatenliste an
                    K = append_new_candidates(K, candidate, ...
                        kvargs.CandidatesListType);
%                     K = [K, candidate]; %#ok<AGROW>
                    % Und ,,fuehre den Harkschritt aus''
                    % Streiche den Nachfolger aus der Knotenliste
                    V(V == candidate) = [];
                    % Vermerke den Kandidaten in der Nachfolgerfunktion
                    s(candidate, 2) = a;
                    % Aktualisiere die Laubmenge auf dem Hub
                    M = leafs;
                end

                % Falls Laubmaximum erreicht, beende Schleife
                if M == problem_data.Max_Val
                    break;
                end
            end

            %% 3. Schritt
            % Falls alle Nachbarn des aktuellen Knoten behandelt wurden,
            % wird der naechste Knoten entweder:
            % 1.) Aus der Kandidatenliste ausgesucht, sofern diese nicht
            %     leer ist
            % -- ODER --
            % 2.) Aus der Knotenmenge ausgesucht, wenn keine Kandidaten
            % mehr da sind.
            if ~isempty(K)
                a = K(1);
                % Werfe Nachfolger aus der Liste
                K(1) = [];
            else
                % Keine Nachfolger mehr, Hub wird nicht ganz voll.
                % Hole neuen Knoten aus dem Knotenvektor und starte mit
                % einem neuen Hub.
                a = get_next_cluster(problem_data, V, kvargs.ClusterSelection);
                V(V == a) = [];
                s(a, 2) = a;
                break;
            end
        end
    end

    s(s == 0) = -1;
    return;
end


function index = get_next_cluster(problem_data, V, method)
    %% Get the next cluster index from V, based on method.
    %
    % Holt den naechsten zu betrachtenden Knoten aus der Liste V. Nach
    % welchem Kriterien die Knoten ausgesucht werden, wird mit dem
    % Parameter method festgelegt.
    %
    % Parameters
    % ----------
    % problem_data: ProblemData()
    %     Eine Instanz der Klasse ProblemData, die das aktuelle Problem
    %     beschreibt.
    % V: vector of double
    %     Menge aller noch unbearbeiteten Knoten
    % method: string
    %     Ein String, der zur Festlegung der Indexsuche dient.
    %     Gueltige Werte sind:
    %       - "nw" : Nordwest-Ecken Regel
    %       - "max": Knoten mit groesster Laubmenge
    %
    % Returns
    % -------
    % index
    %     Den Index des naechsten Hub-Knotens.

    switch (method)
        case "NW"
            % Hole den naechsten Knoten aus der Knotenliste.
            index = V(1);
        case "LM_max"
            % Hole den Knoten mit dem meisten Laub
            [~, index] = max(problem_data.GMatrix(V, 4));
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

function neighbors = sort_neighbors(neighbors, problem_data, method)
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
        otherwise
            error("Method not implemented!");
    end
    return;
end

function K = append_new_candidates(K, new_candidates, method)
% Elements from K are always removed at index 1!!
    switch (method)
        case "LIFO"
            K = [new_candidates, K];
        case "FIFO"
            K = [K, new_candidates];
        otherwise
            error("Method not implemented!");
    end
    return;
end
