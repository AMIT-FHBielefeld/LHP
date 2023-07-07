.. _einfuehrung-heuristiken:

Deterministische Lösungsverfahren
=================================

.. contents::
   :local:


Die deterministischen Lösungsverfahren, enthalten im Modul
:mod:`+lhp.+algo.+deterministic`, erzeugen auf deterministische Art und Weise
Lösungen für das Laubharkproblem.  Dabei lassen sich zwei übergeordnete
Algorithmentypen unterscheiden: Die simultanen Clusterverfahren und die
sukzessiven Clusterverfahren. Die weiteren im Modul
:mod:`+lhp.+algo.+deterministic` enthaltenen Funktionen stammen aus dem Projekt
vorangegangenen Überlegungen zur Lösung des Laubharkproblems. Jedes der
Verfahren ist samt seiner Funktionsweise im Quellcode dokumentiert, daher wird
an dieser Stelle auf eine Erörterung der Algorithmen verzichtet. Der
interessierte Leser wird auf die Beschreibungen von Hermann-Josef Kruse
verwiesen.

Alle Verfahren haben ein fest definiertes Interface: Sie erhalten ein Objekt
vom Typ |pdata| und erzeugen daraus eine Nachfolgerfunktion ``s``, die die
ermittelte Harkvorschrift zur Lösung des Problems beschreibt. Da die
Grundalgorithmen (|zz|, |SimC|, |SucC|) noch weitere Parameter zur
Festlegung interner Entscheidungskriterien erhalten, sind für jeden der
Grundalgorithmen spezifische Wrapper-Funktionen implementiert worden, die die
Anforderungen an das Interface erfüllen.

Zum Zeitpunkt der Projektabgabe umfasst das Laubharkprojekt :ref:`87
verschiedene deterministische Heuristiken <docs-heuristiken>`. Zur Ermittlung,
welche der Heuristiken besonders gute Ergebnisse liefern, ist ein eigenes
Testszenario entwickelt worden, dass im ``testScript`` zu finden ist.

Eine deterministische Heuristik lässt sich zwar direkt aufrufen:

.. code-block:: matlab

    s = lhp.algo.deterministic.zickzack(pdata)

Allerdings ist diese Art des Aufrufs nicht vorgesehen. Um eine Kompatibilität
zu den :ref:`genetischen Algorithmen <docs-bio>` herzustellen, die unter
anderem weitere Rückgabeparameter als die deterministischen Heuristiken
liefern, gibt es die Wrapper-Klasse |dw| die von der Klasse |bw| erbt.
Daher sollten die deterministischen Heuristiken in die Wrapper-Klasse
"gewickelt" werden, die zusätzliche Komfortfunktionen liefert, wie gleich
ersichtlich wird:


Die |dw|-Klasse
---------------

.. code-block:: matlab

    zz = lhp.algo.DeterministicWrapper(...
        @lhp.algo.deterministic.zickzack, "Zickzack")

Um eine Berechnung durchzuführen, wird ein |pdata|-Objekt übergeben:

.. code-block:: matlab

    [index, result] = zz.add_new_data(pdata)
    
Die Variable ``result`` enthält ein Struct mit den Ergebnissen der Berechnung.
Alle auf diese Weise durchgeführten Berechnungen werden objekt-intern
gespeichert. Der Index index gibt einerseits an, wie viele Ergebnisse bereits
gespeichert worden sind. Auf der anderen Seite kann mit diesem Index das
gewünschte Ergebnis aus der internen Ergebnisetabelle ermittelt werden:


Datenzugriff in |dw|
--------------------

.. code-block:: matlab

    table_row = zz.get(index)
    
Ein Aufruf der :meth:`~+lhp.+algo.BaseWrapper.get`-Methode ohne
Parameter liefert die gesamte Tabelle zurück. Dazu füllen wir erst noch einige
Ergebnisse ein:

.. code-block:: matlab

    for idx = 1:5
        zz.add_new_data(lhp.ProblemData(15+idx, 15+idx));
    end
    zz.get()

Alternativ lassen sich auch gezielte Bereiche ausgeben:

.. code-block:: matlab

    zz.get([2, 4])

Um sich die Anzahl an Ergebnissen in der Tabelle nicht merken zu müssen, kann
mit Inf als Ersatz für das "end" in 
Arrays das letzte Element der Tabelle indexiert werden:

.. code-block:: matlab

    zz.get(Inf)

Da oftmals nur ein Bruchteil der Daten einer so erhaltenen Tabellenzeile
benötigt wird, kann man die zu extrahierenden Daten weiter spezifizieren:

.. code-block:: matlab

    zz.get(2, "Kosten")

Welche Daten genau auf diesem Wege extrahiert werden können, verrät die
Dokumentation zu der Methode:

.. code-block:: matlab

    help zz.get


Laubmengenoptimierung der deterministischen Heuristiken
-------------------------------------------------------

Um den deterministischen Heuristiken einen potenziellen Vorteil für
Problemstellungen zu verschaffen, in denen das Verhältnis der maximalen
Laub-Transportmenge und der maximalen Laubmenge pro Feld ungünstig gewählt
sind, kann die Laubmenge der Heuristiken optimiert werden. Bei dieser
Laubmengenoptimierung durchlaufen die deterministischen Heuristiken beim Lösen
des Gartens eine Schleife, in der das Problem mit jeder Laubmenge im Intervall
gelöst und die minimale Lösung ermittelt wird. Das so ermittelte
Laubmengenoptimum wird als zusätzlicher Wert in den "results"-Strukturen
eingepflegt, damit die Ergebnisse nachgerechnet werden können.

Um die Laubmengenoptimierung zu aktivieren, muss ein zusätzlicher
Konstruktorparameter übergeben werden:

.. code-block:: matlab

    lhp.algo.DeterministicWrapper(...
        @lhp.algo.deterministic.co_max, "Cluster_Max", "OptimizeMaxLaub", true);


Weitere Methoden von |dw|
-------------------------

Um die errechneten Daten schnell über der Gartengröße zu plotten, bietet sich
die :meth:`~+lhp.+algo.BaseWrapper.plot`-Methode an:

.. code-block:: matlab

    figure();
    ax = axes();
    zz.plot(ax, "Kosten")

Analog zur print-Methode von |pdata|, kann ein Objekt vom Typ |dw| seine
Lösung ebenfalls textuell darstellen. Dazu muss zwingend der gewünschte
Durchlauf (index) angegeben werden:

.. code-block:: matlab

    zz.print(2)

Um nach einem Durchlauf alle vorhandenen Ergebnisse zu löschen und von neuem
Berechnungen zu beginnen, wird die clear Methode verwendet:

.. code-block:: matlab

    zz.clear()
    zz.add_new_data(pdata)

Zuletzt kann zum Beispiel zur Erzeugung von Legendeneinträgen in Plots der
eingangs übergebene Name des Algorithmus formatiert ausgegeben werden:

.. code-block:: matlab

    zz.get_name("Latex")

Darüber hinaus gibt es weitere Konstruktor- und Methodenparameter. Auch hier
wird der interessierte Leser auf die Dokumentation der Methode verwiesen.


Komfortable Erzeugung von |dw|-Objekten
---------------------------------------

Da, wie eingangs erwähnt, 87 deterministische Heuristiken im Laubharkprojekt
existieren, die alle ihrerseits unterschiedliche Funktionspointer verwenden und
unterschiedliche Bezeichner haben, ist eine Komfortmethode integriert worden,
die die schnelle und einfache Erzeugung von |dw|-Objekten erlaubt. Die
Methode |dw-gather| arbeitet auf Basis der Textdatei
``+lhp/+algo/+deterministic/algorithms.txt``, die für jede deterministische
Heuristik eine textuelle Beschreibung des Funktionshandle und Algorithmennamen
beinhaltet. Die Methode |dw-gather| liest, basierend auf den Eingaben des
Nutzers, die gewünschten Algorithmen aus der Datei aus und erzeugt dafür
Objekte vom Typ |dw|. Dazu muss der Nutzer lediglich die ID des gewünschten
Algorithmus kennen, die der Textdatei zu entnehmen ist:

.. code-block:: matlab

    all_heuristics = lhp.algo.DeterministicWrapper.gather("Range", (1:end))

Um im "großen Stil" mit den Algorithmen zu arbeiten, können der
|dw-gather|-Methode auch Konstruktorparameter übergeben werden, die auf alle
erzeugten Objekte angewendet werden:

.. code-block:: matlab

    lhp.algo.DeterministicWrapper.gather("OptimizeMaxLaub", true, ...
        "StoreResults", false, "NameSuffix", "_TEST", "Range", (1:5))
    
    
..
  Replacements for text above.

.. include:: ../replacements.rst

