.. _einfuehrung-bio:

Bio-inspirierte Lösungsverfahren
================================

.. contents::
   :local:


Zum Zeitpunkt des Projektberichts existieren zwei stochastische,
:ref:`bio-inspirierte Lösungsverfahren <docs-bio>` im Laubharkprojekt: Der
genetische Algorithmus von Karim Abdelhak (im Modul
:mod:`+lhp.+algo.+stochastic.+genetic`) und der Bienenschwarm-Algorithmus von
Julia Wiebe (im Modul :mod:`+lhp.+algo.+stochastic.+bee`). Auf eine Erklärung
der Funktionsweise der Algorithmen soll auch hier verzichtet werden.
Stattdessen wird der Nutzer auf die externe Dokumentation hingewiesen.

Wie bereits erwähnt haben die bio-inspirierten Lösungsverfahren ein anderes
Interface als die Heuristiken. Dies ist insbesondere der Tatsache geschuldet,
dass die hier implementierten bio-inspirierten Verfahren mit Populationen von
Individuen arbeiten und in diesem Sinne mehr Rückgabeparameter als nur eine
Nachfolgerfunktion liefern können. Um diesem Umstand gerecht zu werden, stellt
die Wrapper-Klasse |sw| dem Nutzer eine Datenkapselung bereit, mit der die
bio-inspirierten Algorithmen auf die gleiche Weise wie die deterministischen
Heuristiken in |dw| verwendet werden können. Hierdurch werden
Implementierungsunterschiede vor dem Nutzer verborgen und er kann mit einem
einheitlichen Interface arbeiten.

Daher sind viele der im Folgenden demonstrierten Methoden identisch zu denen
der Klasse |dw|. Ein Objekt eines bio-inspirierten Verfahren erzeugt man wie
folgt:


Die |sw|-Klasse
---------------
    
.. code-block:: matlab

    % Fuer den Bienenalgorithmus:
    % lht_bio = lhp.algo.StochasticWrapper(...
    %     @lhp.algo.stochastic.bee.bienenalgorithmus, "Bienen-Algorithmus")
    lht_bio = lhp.algo.StochasticWrapper(...
        @lhp.algo.stochastic.genetic.genetic, "Genetischer-Algorithmus");

Anders als bei den deterministischen Heuristiken, können dem Konstruktor
diverse Parameter übergeben werden:
    
.. code-block:: matlab

    help lhp.algo.StochasticWrapper.StochasticWrapper

Um eine Berechnung durchzuführen, wird auch hier ein |pdata|-Objekt übergeben:
        
.. code-block:: matlab

    pdata.Popsize = 15;  % Damit der genetische Algorithmus nicht so lange rechnet...
    [index, result] = lht_bio.add_new_data(pdata)

Die Variable `result`` enthält ein Struct mit den Ergebnissen der Berechnung.
Alle auf diese Weise durchgeführten Berechnungen werden objekt-intern
gespeichert. Der Index index gibt einerseits an, wie viele Ergebnisse bereits
gespeichert worden sind. Auf der anderen Seite kann mit diesem Index das
gewünschte Ergebnis aus der internen Ergebnisetabelle ermittelt werden:


Datenzugriff in |sw|
--------------------
    
.. code-block:: matlab

    table_row = lht_bio.get(index)

Ein Aufruf der :meth:`~+lhp.+algo.BaseWrapper.get`-Methode ohne
Parameter liefert die gesamte Tabelle zurück. Dazu füllen wir erst noch einige
Ergebnisse ein:
    
.. code-block:: matlab

    % Dieser Schritt dauert eine ganze Weile.
    % Mit dem Konstruktorparameter "NumWorkers" liese er sich durch parallelisierung
    % erheblich Beschleunigen.
    for idx = 1:5
        lht_bio.add_new_data(lhp.ProblemData(15+idx, 15+idx, "PopulationSize", 15));
    end
    lht_bio.get()

Alternativ lassen sich auch gezielte Bereiche ausgeben:
    
.. code-block:: matlab

    lht_bio.get([2, 4])

Um sich die Anzahl an Ergebnissen in der Tabelle nicht merken zu müssen, kann
mit Inf als Ersatz für das "end" in Arrays das letzte Element der Tabelle
indexiert werden:
    
.. code-block:: matlab

    lht_bio.get(Inf)

Da oftmals nur ein Bruchteil der Daten einer so erhaltenen Tabellenzeile
benötigt wird, kann man die zu extrahierenden Daten weiter spezifizieren:
    
.. code-block:: matlab

    lht_bio.get(2, "Kosten")

Anders als bei den Heuristiken ist hierbei zu beachten, dass für jeden
Durchlauf der Monte-Carlo-Simulation ein einzelnes Ergebnis vorliegt. Wird die
Methode :meth:`~+lhp.+algo.BaseWrapper.get` ohne dritten Parameter
aufgerufen, wird das "Beste" Ergebnis (geringste Gesamtkosten) aus allen
Durchläufen ausgegeben. Um die Ergebnisse aller Durchläufe zu sehen:
    
.. code-block:: matlab

    lht_bio.get(2, "Kosten", "All");

Welche Daten genau auf diesem Wege extrahiert werden können, verrät auch hier
die Dokumentation zu der Methode:
    
.. code-block:: matlab

    help lht_bio.get


Weitere Methoden von |sw|
-------------------------

Um die errechneten Daten schnell über der Gartengröße zu plotten, bietet sich
die :meth:`~+lhp.+algo.BaseWrapper.plot`-Methode an:
    
.. code-block:: matlab

    fig = figure();
    ax = axes();
    lht_bio.plot(ax, "Kosten")

Man beachte, dass analog zur :meth:`~+lhp.+algo.BaseWrapper.get`-Methode
auch hier ein dritter Parameter angegeben werden kann, um z.B. die Mittelwerte
aus allen Monte-Carlo-durchläufen zu plotten:
    
.. code-block:: matlab

    lht_bio.plot(ax, "Kosten", "Average")

Analog zur print-Methode von |pdata|, kann ein Objekt vom Typ |sw| seine
Lösung ebenfalls textuell darstellen. Dazu muss zwingend der gewünschte
Durchlauf (index) angegeben werden:
    
.. code-block:: matlab

    lht_bio.print(2)

Die :meth:`~+lhp.+algo.BaseWrapper.print`-Methode verwendet in der
Ausgabe für jeden Kostenfaktor den Wert der Lösung mit den geringsten
Gesamtkosten. Eine Modifikation dieses Verhaltens muss daher direkt im
Quelltext der Methode erfolgen.

Um nach einem Durchlauf alle vorhandenen Ergebnisse zu löschen und von neuem
Berechnungen zu beginnen, wird die
:meth:`~+lhp.+algo.BaseWrapper.clear`-Methode verwendet:
    
.. code-block:: matlab

    lht_bio.clear()
    lht_bio.add_new_data(pdata)

Zuletzt kann zum Beispiel zur Erzeugung von Legendeneinträgen in Plots der
eingangs übergeben Name des Algorithmus formatiert ausgegeben werden:
    
.. code-block:: matlab

    lht_bio.get_name("Latex")


 
..
  Replacements for text above.

.. include:: ../replacements.rst

