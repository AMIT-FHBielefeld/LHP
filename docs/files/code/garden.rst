Gärten und ProblemData
======================

.. contents::
   :local:


Im Laubharkprojekt wird mit Gärten gearbeitet, die als ungerichteter, Kanten-
und Knotengewichteter Graph definiert sind. In Matlab werden die Graphen als
eine 2-Dimensionale Matrix repräsentiert, aus der sich dann Informationen, wie
zum Beispiel Nachbarschaften (*Adjazenzen*) und Distanzen zwischen den Knoten
ableiten lassen.

Die Knoten werden in der Funktionsdokumentation auch als *Felder* oder *Zellen*
bezeichnet, in Anlehnung an die Repräsentation des Gartens als beliebig fein
gerasterte Matrix. Tatsächlich gibt es im Projekt keine festgelegte Definition
dafür, wie groß ein einzelnes Feld in einem Garten ist. Die Einteilung ist
beliebig.


Die :class:`Garden <+lhp.@Garden.Garden>`-Klasse
------------------------------------------------

Um Gärten adäquat verwalten und an projektspezifische Gegebenheiten anpassen zu
können, ist eine Klasse entwickelt worden, die alle Gärten verwaltet.
Ziel dieser Klasse ist es Gärten samt zugehöriger Funktionen, zum Beispiel zum
plotten der Gärten (:meth:`~+lhp.@Garden.Garden.plot`), zu bündeln.

Darüber hinaus ermöglicht es diese Klasse, Diskrepanzen bei der Definition von
Gartenzugriffen zu umgehen. So ist im Rahmen des Projektes definiert, dass
Gartenfelder Zeilenweise, in der ersten Zeile links beginnend und nach rechts
fortlaufend, aufsteigend nummeriert werden.
Matlab hingegen definiert diese *lineare Indexierung* Standardmäßig
spaltenweise.

So ist die Umrechnung zwischen der Angabe eines Felds als
Zeilen/Spalten-Koordinaten und dem linearen Index mit einigem
Implementierungsaufwand verbunden. Um unter anderem diese lösen zu können, gibt
es daher eine eigene Garten-Klasse.
Zufällige Gärten werden im Moment von der Funktion |zg| erzeugt.


.. module:: +lhp.@Garden
.. autoclass:: Garden
   :members:



|pdata|
-------

Die Klasse |pdata| repräsentiert einen Garten samt zugehöriger Metadaten. Dazu
zählen zum Beispiel die Distanzmatrix, die Adjazenzmatrix, aber ebenso die
Position des Komposts oder die Startposition. Eine ausgiebige Auflistung aller
Attribute entnimmt man am einfachsten Matlab selbst.

.. module:: +lhp.@ProblemData
.. autoclass:: ProblemData
   :members:


.. include:: ../replacements.rst
