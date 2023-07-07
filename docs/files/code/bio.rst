.. _docs-bio:

Bio-inspirierte Algorithmen
===========================
   
.. warning::
   Ein direkter Aufruf der hier aufgeführten Algorithmen ist zwar möglich, wird 
   aber nicht empfohlen. Stattdessen soll, wie in der 
   :ref:`Einführung <einfuehrung-bio>` gezeigt, die 
   :class:`StochasticWrapper <+lhp.+algo.StochasticWrapper>` Klasse verwendet 
   werden!

.. contents::
   :local:
   

   
Die bio-inspirierten Algorithmen arbeiten in Anlehnung an natürliche Prozesse
bzw. Verhaltensmuster, die in der Natur beobachtbar sind. Dabei geht es nicht
um eine direkte Kopie der Prozesse und Verhaltensmuster, sondern eher um eine
Adaption für technische Anwendungen.

Gegenüber deterministischen heuristischen Verfahren können bio-inspirierte
Verfahren einen Vorteil bieten, wenn:

- Der zu durchsuchende Lösungsraum sehr groß ist.
- Zielfunktionen multimodal sind.
- Das Problem gut parallelisierbar ist.
- Das schnelle auffinden einer guten Lösung wichtiger ist als das auffinden der 
  global optimalen Lösung.
- Wenig vorwissen über das Problem bekannt ist.

Im Kontext des Laubharkproblems wird untersucht, ob die bio-inspirierten
Verfahren in verschiedenen Szenarien gegenüber den deterministischen
Heuristiken einen Vorteil bieten können. Aufgrund ihrer Implementierung sind
bio-inspirierte Verfahren anpassungsfähig, und können daher auch bei Problemen
mit veränderten Rahmenbedingungen gute Ergebnisse liefern. Das ist bei
deterministischen Heuristiken nicht automatisch gegeben.

Zum aktuellen Zeitpunkt sind zwei bio-inspirierte Verfahren implementiert.

- Der genetische Algorithmus von Karim Abdelhak
- Der Bienenschwarm-Algorithmus von Julia Wiebe

Eine Dokumentation zu den Algorithmen ist im Matlab-Quellcode leider nicht
vorhanden. Auf eine Erläuterung der Funktionsweise der Algorithmen wird hier
verzichtet, der interessierte Leser wird stattdessen auf einschlägige Literatur
verwiesen.

Die Verwendung der Algorithmen ist 
:ref:`in der Einführung beschrieben <einfuehrung-bio>`.

