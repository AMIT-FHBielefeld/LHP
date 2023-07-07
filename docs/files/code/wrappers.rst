.. _docs-wrapper:

Wrapper-Klassen für die Algorithmen
===================================

.. contents::
   :local:


Auf dieser Seite sind die Wrapper-Klassen |bw|, |dw| und |sw|
dokumentiert. Ihr Zweck ist es, einheitliche Interfaces beim Arbeiten mit den
verschiedenen Algorithmentypen zu schaffen. Das wird erreicht, indem sowohl
|dw| wie auch |sw| von der Klasse |bw| erben. Algorithmenspezifische
Codepassagen werden dann von den Kindklassen nach Bedarf überschrieben, bzw.
die Kindklassen können auch weitere (algorithmenspezifische) Methoden
hinzufügen. 

Die Klassen sind so entwickelt worden, dass es dem Nutzer prinzipiell auch
möglich ist, weitere Kindklassen von |dw| und |sw| abzuleiten, wenn
Bedarf besteht.


Notwendigkeit der Klassenstruktur
---------------------------------

Die Notwendigkeit in der Verwendung dieser Klassenstruktur erwuchs aus dem
Bedürfnis heraus, alle Algorithmen in einheitlicher Art und Weise im Code
behandeln zu können. Das ist zwar auch möglich, wenn jeder verwendete
Algorithmus mit einem festen Interface (festgelegte Eingabe- und
Rückgabeparameter) entwickelt wird. Allerdings bieten die Klassen weitere
Komfortfunktionen zur Verwaltung der Algorithmen und können theoretisch auch
Algorithmen ,,verwalten'', die nicht in das festgelegte Interface passen.

Darüber hinaus gibt es fundamentale Unterschiede zwischen den
:ref:`deterministisch-heuristischen <docs-heuristiken>` und den
:ref:`bio-inspirierten <docs-bio>` Algorithmen.

Zwar arbeiten die deterministischen Heuristiken deterministisch und liefern
daher zu ein und dem selben Problem stets das selbe Ergebnis. Allerdings trifft
das auf die bio-inspirierten Algorithmen nicht zu: Sie arbeiten probabilistisch
und können daher zu ein und dem selben Problem stets verschiedene Ergebnisse
liefern.

Um diesem Umstand im Code gerecht zu werden, wird für alle bio-inspirierten
Algorithmen eine Monte-Carlo-Simulation [#f1]_ durchgeführt. Infolgedessen
erzeugen diese Verfahren **mehr als eine Lösung**. In der späteren Auswertung,
zum Beispiel bei Vergleichen zwischen den Algorithmen, können dann statistische
Maße zur Aussagenfindung herangezogen werden. In einer späteren Anwendung
würden die Algorithmen hingegen nur einmal ausgeführt. Auch diesem Umstand kann
die |sw|-Klasse gerecht werden.

Des weiteren arbeiten die bio-inspirierten Algorithmen häufig mit Populationen
von Individuen (Lösungen), während deterministische Heuristiken stets genau
eine Lösung (,,Individuum'') hervorbringen. Darüber hinaus können die
bio-inspirierten Algorithmen vielfältige weitere Eingabe- und Rückgabeparameter
verlangen. Diese Komplexität wird allerdings durch die Kapselung in der
Klassenstruktur vor dem Nutzer verborgen.

Auf diese Weise können alle Algorithmen mit der |bw| Klasse arbeiten, ohne zu
hinterfragen, welcher spezielle Algorithmentyp oder Algorithmus sich im inneren
verbirgt.


.. [#f1] In unserem Fall wird ein Input mehrfach ,,gelöst'', und alle
         unterschiedlichen Ergebnisse werden gespeichert. Erklärung der
         Monte-Carlo-Simulation:
         https://www.ibm.com/cloud/learn/monte-carlo-simulation


|bw|
----

Diese Klasse ist die Elternklasse für |dw|, sowie |sw|. Alle Methoden, die
diese Klasse definiert, sind auch in den Kindklassen vorhanden. Sie schafft das
einheitliche Interface für den Umgang mit den verschiedenen Algorithmen.

.. module:: +lhp.+algo
.. autoclass:: BaseWrapper
   :members:


.. _features in bw:

Besondere Features in |bw|
~~~~~~~~~~~~~~~~~~~~~~~~~~

Die |bw|-Klasse bietet einige Algorithmenunabhängige Konstruktorparameter, die
hier ausführlicher erläutert werden sollen. In der folgenden Aufzählung werden
nicht alle Konstruktorparameter erwähnt, sondern nur solche, die in Art und
Wirkung relativ komplex sind.

'PostOptimize'
    Dieser Parameter erlaubt das nachträgliche Optimieren einer Lösung. Diese
    Optimierung wird mit der |hz|-Funktion durchgeführt. Das Argument zu diesem
    Parameter ist ein Array von Strings, die |hz| als Hubzentierungsmethoden
    versteht. Wenn also nach der Berechnung einer Lösung mit der
    'Median'-methode nachgebessert werden soll, würde der Aufruf von |bw| so
    aussehen::

        lhp.algo.BaseWrapper.gather("Range", 12, "PostOptimize", ["Median"]);
    
    Es ist darüber hinaus auch möglich, mehrere Nachbesserungsmethoden
    anzugeben, diese werden mit in das Array geschrieben. Bei der Ausführung
    werden alle angegebenen Hubzentrierungen durchgerechnet und die Beste Lösung
    (gerigste Gesamtkosten) wird übernommen. Um kenntlich zu machen, welche
    Lösung das beste Ergebnis erzeugt hat, wird die ``results``-Struktur, die
    :meth:`~+lhp.+algo.BaseWrapper.add_new_data` zurückliefert, um ein
    'post_opt'-Feld ergänzt, in dem der Name des verwendeten |hz|-Parameters
    steht. Ein Wert von "none" bedeutet, dass die Lösung ohne Nachbesserung von
    |hz| das beste Ergebnis erzeugte.


|dw|
----

Diese Klasse ist als Wrapper um die :ref:`deterministischen heuristischen
Algorithmen <docs-heuristiken>` entwickelt worden.

.. important::
    **Da sie von** |bw| **erbt, übernimmt sie auch deren Methoden!**

.. autoclass:: DeterministicWrapper
   :show-inheritance:
   :members:


.. _features in dw:

Besondere Features in |dw|
~~~~~~~~~~~~~~~~~~~~~~~~~~

Die |dw|-Klasse bietet einige speziell für deterministische Heuristiken gedachte
Konstruktorparameter, die hier ausführlicher erläutert werden sollen. In der
folgenden Aufzählung werden nicht alle Konstruktorparameter erwähnt, sondern nur
solche, die in Art und Wirkung relativ komplex sind.

'OptimizeMaxLaub'
    Wie in der Dokumentation beschrieben, sorgt dieser Parameter dafür, dass der
    gegebene Garten mit jeder Laubmenge im Interval :math:`[1, pdata.MaxVal]`
    gelöst wird. Dieses Vorgehen sorgt für optimalere Lösungen unter ungünstigen
    Randbedingungen, zum Beispiel wenn die maximale Laubmenge pro Feld ein
    vielfaches der Transportmenge ist. 
    
    Um auch diese Ergebnisse nachvollziehen zu können, wird bei aktivierter
    Laubmengenoptimierung die ``results``-Struktur um ein 'optMaxLaub'-Feld
    ergänzt, in dem die von der maximalen Laubmenge abweichende, optimale
    Laubmenge festgehalten wird. Im Zusammenspiel mit der 'PostOptimize'-Option
    wird zuerst die Laubmenge angepasst und eine neue Lösung berechnet, bevor
    die |hz|-Funktion auf alle Lösungen angewendet wird.

'RemoveEmptyNodes'
    Falls aktiviert, wird nach der Berechnung einer Lösung stets die
    :func:`~+lhp.+utils.skip_zero_hubs`-Funktion aufgerufen. Damit werden alle
    Knoten aus der Nachfolgerfunktion entfernt, die bei deren Abarbeitung keine
    Blätter tragen. Das umschließt Harkquellen mit der Laubmenge 0, sowie
    Knoten, über die zwar laut Nachfolgerfunktion geharkt wird, auf denen aber
    niemals Laub liegt (weil "kein Laub" darüber geharkt wird). Solche leeren
    Knoten werden dann zu Hubs umgewandelt, die bei der Lösung des Problems
    unberücksichtigt bleiben und somit die Gesamtkosten reduizeren. (Da keine
    unnötigen Wege mehr zurückgelegt werden, um leere Knoten zu bearbeiten)

    Empirische Versuche (siehe ``testScript``, Test 1.5) haben gezeigt, dass die
    Entfernung dieser leeren Knoten idealerweise vor der Anwendung von |hz|
    (siehe 'PostOptimize'-Parameter) erfolgen sollte. So ist es im Code auch
    implementiert.


|sw|
----

Diese Klasse ist als Wrapper um die :ref:`bio-inspirierten Algorithmen
<docs-bio>` entwickelt worden. Der Name ist darauf zurückzuführen, dass bei der
ursprünglichen Implementierung nur ein einziger bio-inspirierter Algorithmus im
Projekt vorhanden war: der genetische Algorithmus. Sie ist aber universell für
alle bio-inspirierten Algorithmen anwendbar.

.. important::
    **Da sie von** |bw| **erbt, übernimmt sie auch deren Methoden!**

.. autoclass:: StochasticWrapper
   :show-inheritance:
   :members:


.. _features in sw:

Besondere Features in |sw|
~~~~~~~~~~~~~~~~~~~~~~~~~~

Die |sw|-Klasse bietet einige speziell für stochastische Heuristiken gedachte
Konstruktorparameter, die hier ausführlicher erläutert werden sollen. In der
folgenden Aufzählung werden nicht alle Konstruktorparameter erwähnt, sondern nur
solche, die in Art und Wirkung relativ komplex sind.

'NumWorkers'
    Steuert, ob die Monte-Carlo-Simulation parallelisiert ausgeführt werden
    soll. Dieser Parameter ist insbesondere dann sinnvoll, wenn der Nutzer mit
    einzelnen |sw|-Objekten direkt interagiert, statt sie im |tm| zu verwenden.
    Wird hingegen der |tm| verwendet, ist von der Verwendung dieses Parameters
    abzusehen, da der |tm| selbst bereits Parallelisierung zur schnelleren
    Ausführung der Tests verwendet. Eine Hinzunahme von weiteren Worker-Threads
    zur vermeintlichen Beschleunigung der Berechnung erfüllt dann den
    gegenteiligen Zweck: Da sich die Worker-Threads des |tm|, sowie die
    Worker-Threads von |sw| die Ressourcen des Betriebssystems teilen müssen,
    werden diese vom Scheduler der Reihe nach "aktiviert". Diese ständigen
    Prozesswechsel sind sehr teuer und verschwenden viel Zeit, die mit
    Berechnungen sinnvoll genutzt werden könnte.

'StoreRNG'
    Wird diese Option aktiviert, wird der Zustand des Zufallszahlengenerators
    vor jeder Ergebnisberechnung gespeichert. Das erlaubt es zum Beispiel,
    während der Tests duchgeführte Berechnungen zu einem späteren Zeitpunkt im
    Detail nachzuvollziehen (zum Beispiel mit dem Matlab Debugger), oder aber
    weitere Berechnungsergebnisse zu erhalten. Beispielsweise könnte man im
    Rahmen des Tests auf das Speichern der Populationen verzichten
    ('StorePopulations'), und dann für ausgewählte Durchläufe alle Ergebnisse,
    damit Populationen, im Nachgang berechnen.

    Um diese Berechnungen nicht von Hand anstoßen zu müssen, gibt es die
    :meth:`~+lhp.+algo.StochasticWrapper.replay`-Methode.


.. include:: ../replacements.rst
