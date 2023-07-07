Erzeugung eines Gartens
=======================

.. contents::
   :local:


Ein Garten ist eine 2-dimensionale Matrix, die beschreibt, wie viel Laub auf je 
einem rechteckigen Abschnitt (Feld) des Gartens liegt. Die Werte der Felder des 
Gartens haben die folgende Bedeutung:

- Feld :math:`> 0` : Auf diesem Feld liegt die angegebene Menge Laub
- Feld :math:`= 0` : Auf diesem Feld liegt kein Laub
- Feld :math:`= (-1)` : Dieses Feld ist blockiert, durch einen Gartenschuppen
- Feld :math:`= (-2)` : Dieses Feld ist blockiert, durch den Baumstamm eines Baums
- Feld :math:`= (-10)` : Dieses Feld ist blockiert, hier steht der Kompost

Das Problem ist so ausgelegt, dass durch blockierte Felder 
("Laubmenge" :math:`< 0`) nicht gegangen und auch nicht geharkt werden kann. 
Die Kennzeichnung dient vor allem der Unterscheidbarkeit zwischen blockierten 
Feldern. So ist zum Beispiel immer klar, wo in einem Garten das Kompostfeld ist 
("Laubmenge" :math:`= (-10)`). Die Bewertungsfunktionen gehen davon aus, dass 
nur ein Kompost in einem Garten existiert, die Algorithmen hingegen 
interpretieren die negativen Laubmengen nicht weiter. Insofern können beliebige 
weitere Markierungen für blockierte Felder definiert werden.

Um einen Garten zu erzeugen, wird die Funktion |zg| aufgerufen. Als Parameter
erwartet die Funktion wenigstens die Anzahl an Zeilen und Spalten des
gewünschten Gartens. Der folgende Aufruf erzeugt also einen Garten mit 15
Zeilen und 15 Spalten:

.. code-block:: matlab

   Garten = lhp.Garden.random(15, 15);
   
Mit Hilfe weiterer Schlüssel-Wert (*Key-Value*) Parameter kann die Funktion 
modifiziert werden. Der Parameter ``'Export'`` speichert den erzeugten Garten in 
einer Datei ab, der Parameter ``'Plot'`` erzeugt zu dem Garten einen heatmap 
plot:

.. code-block:: matlab

   lhp.Garden.random(15, 15, "Plot", true)

In dem Plot sind die Werte der Schuppen- und Baumfelder mit (-10) multipliziert, 
um sie gegenüber Feldern mit Laubmengen nahe 0 hervorzuheben. In der 
Gartenmatrix lauten die Werte wie oben beschrieben. Bei der Erzeugung des 
Gartens wird darauf geachtet, dass keine isolierten Laubfelder existieren 
können. Sollte ein isoliertes Feld vorhanden sein, wird der Garten so lange neu 
erstellt, bis alle laubbesetzten Felder erreichbar sind.

Um mit dem Garten arbeiten zu können, brauchen wir einige Metadaten:

- Einen Startknoten, an dem wir mit der Arbeit beginnen
- Eine maximale Laubmenge, die auf einem Feld aufgehäuft werden kann
- Die maximale Transportkapazität der Schubkarre
- Die Kostenfaktoren für das Harken, Transportieren und unproduktive Wege
- Eine Beschreibung des Gartens (``GMatrix``)
- Eine Beschreibung der Nachbarschaften der Felder (``Adjancency``)
- Die Distanzen der Felder zu einander, unter Berücksichtigung blockierter 
  Felder (``DMatrix``)
  
Die ``GMatrix`` ist ein 4-spaltiger Vektor, dessen erste und zweite Spalte
jeweils die Zeile und Spalte eines Gartenfeldes angeben. Die dritte Spalte
definiert den Index des Feldes bei zeilenweiser Zählung, und die vierte Spalte
beinhaltet die Laubmenge des Feldes. Die Adjazenzmatrix (``Adjacency``)
beschreibt, welche Felder, unter Berücksichtigung blockierter Felder, direkt
mit einander benachbart sind. Die Distanzmatrix (``DMatrix``) beinhaltet die
Entfernungen aller Felder zu einander, berechnet nach Dijkstras Algorithmus.

Um alle Metadaten zusammen mit einem zugehörigen Garten zu verwalten, gibt es 
die |pdata|-Klasse.


.. include:: ../replacements.rst
