Arbeiten mit Lösungen (Nachfolgerfunktionen)
============================================

.. contents::
   :local:


Kosten einer Lösung
-------------------

Um die erzeugten Lösungen verschiedener Algorithmen zu vergleichen, bedarf es
einer Bewertung der Lösungen. Diese Bewertung erfolgt, indem zu einer
berechneten Lösung (Nachfolgerfunktion :math:`s`) der gesamte Vorgang des
Laubharkens simuliert wird.

Bei dieser Simulation entstehen Kosten aus drei verschiedenen Kategorien:

1. Kosten durch das zurücklegen von Wegen
2. Kosten durch das Harken von Laub
3. Kosten durch den Abtransport von Laub zum Gartenkompost

Wie genau diese Kosten aus einer Lösung berechnet werden, entnimmt man am
besten der Funktionsdokumentation weiter unten auf dieser Seite.


.. module:: +lhp.+rating
.. autofunction:: get_costs


Strukturmerkmale einer Lösung ermitteln
---------------------------------------

Hiermit ist eine ,,leichtgewichtige'' Analyse der Lösungen gemeint. Damit wird
ermittelt, welche Felder in der Lösung Quellen oder Senken sind, und wie die
Zugehörigkeit der einzelnen Knoten zu Clustern ist. Viele der Algorithmen rund
um das Laubharkproblem benötigen diese Information.

.. module:: +lhp.+utils
.. autofunction:: +lhp.+utils.analyze_s


Verbesserung der Kosten einer Lösung
------------------------------------

Im Laubharkprojekt sind einige Heuristiken implementiert, die die Kosten einer
erzeugten Lösung im Nachhinein verbessern können. Dazu zählt die Hubzentrierung
(|hz|), die die Harkwege und Laubsenken innerhalb der Cluster nach einer
vorgegebenen Methode neu ausrichtet, und das überspringen leerer Cluster mit
:func:`~+lhp.+utils.skip_zero_hubs`.


.. tip::

   Die Hubzentrierung kann mit dem |bw|-Konstruktorparameter ``'PostOptimize'``
   für alle Algorithmen direkt bei der Ermittlung der Lösungen hinzugeschaltet
   werden. Siehe :ref:`features in bw` für weitere Informationen.

.. autofunction:: +lhp.+utils.hz


.. tip::

   Die Entfernung leerer Cluster kann für die heuristischen Deterministiken mit
   dem |dw|-Konstruktorparameter ``'RemoveEmptyNodes'`` direkt bei der
   Ermittlung der Lösungen hinzugeschaltet werden. Siehe 
   :ref:`features in dw` für weitere Informationen.

.. autofunction:: +lhp.+utils.skip_zero_hubs


Grafische Darstellung einer Lösung
----------------------------------

Diese Funktion erzeugt eine grafische Darstellung einer Nachfolgerfunktion. Mit
den Parametern kann das Erscheinungsbild weiter verfeinert werden, die
grundlegende Idee ist jedoch:

- Alle Cluster werden farblich markiert, sodass benachbarte Cluster niemals die
  selbe Farbe haben (visuelle Unterscheidbarkeit)
- Cluster werden zusätzlich durch "Grenzlinien" von einander getrennt
- Innerhalb der Cluster geben die Pfeile die Richtung der Harkvorgänge an
- Blockierte Felder (Beispiel: Baum) werden entsprechend ihrer Definition in
  :class:`+lhp.@Garden.Garden` farblich hervorgehoben

Weitere mögliche Änderungen am Erscheinungsbild sind der folgenden Dokumentation
zu entnehmen.


.. autofunction:: +lhp.+utils.cluster_plot



.. include:: ../replacements.rst
