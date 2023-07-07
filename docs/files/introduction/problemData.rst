Die ProblemData-Klasse
======================

.. contents::
   :local:


Die |pdata|-Klasse entstammt ursprünglich Karim Abdelhaks genetischem 
Algorithmus und ist im Rahmen des Projektes adaptiert und erweitert worden, um 
eine allgemeine Verwendbarkeit mit allen Algorithmen zu ermöglichen. Ein Objekt 
vom Typ |pdata| stellt den Garten samt zugehöriger Metadaten zur 
Verfügung. Darüber hinaus sind weitere, algorithmen-spezifische Metadaten für 
die bio-inspirierten Algorithmen hinterlegt. Auf diese Weise beschreibt ein 
Objekt der |pdata|-Klasse immer vollständig eine konkrete 
Problemstellung und ist die zentrale Datenstruktur, mit der alle Algorithmen 
arbeiten.

Um eine einfache Erzeugung von randomisierten Problemen zu ermöglichen, kann 
der zu verwendende Garten von der |pdata|-Klasse zufällig erzeugt 
werden. Dazu gibt man, wie zuvor, die gewünschte Anzahl an Zeilen und Spalten 
an:

.. code-block:: matlab

   lhp.ProblemData(15, 15)
   
Um einen zuvor erstellten Garten in ein Objekt vom Typ |pdata|
einzubetten, wird folgende Syntax verwendet:

.. code-block:: matlab

   pdata = lhp.ProblemData(20, 20, "Garten", Garten)
   
Die ersten beiden Parameter sind auch hier zwingend erforderlich und
beschreiben, wie bei |zg|, die Anzahl Zeilen und Spalten der
Gartenmatrix. Bei dieser Art des Aufrufs werden die Zeilen und Spalten aber
Objektintern mit den entsprechenden Werten für den übergebenen Garten
überschrieben.

Darüber hinaus bietet die |pdata|-Klasse viele weitere Parameter, die der
Nutzer einstellen kann.  Dabei gilt es zu beachten, dass eine Manipulation der
enthaltenen Gartenmatrix (``pdata.Garden``) in einem erzeugten Objekt nicht
erlaubt ist. Eine derartige Manipulation würde nämlich automatisch zu einer
Änderung der Adjazenz, Distanz- und GMatrix führen. In diesem Fall ist es
besser, mit dem manipulierten Garten ein neues Objekt vom Typ |pdata| zu
erzeugen.

Zwei Parameter in der Ausgabe sollen noch besonders hervorgehoben werden. Der
Parameter ``DiagonalWeight`` bestimmt die Kosten (als Wegeinheit) für das
diagonale Gehen. Ein Wert von :math:`\infty` verbietet das diagonale Gehen. Ein
Wert von :math:`\sqrt{2}` entspräche der erwarteten euklydischen Distanz. Der
Parameter ``flattened`` ist nicht vom Nutzer parametrierbar, sondern von der
Struktur fest vorgegeben. Da die Metadaten Adjazenz-, Distanz- und GMatrix aus
der Gartenmatrix berechnet werden können, müssen diese nicht zwingend
abgespeichert werden. Grade für große Gärten von ca. 70 x 70 Feldern ist der
Speicherbedarf dieser Strukturen um einen Faktor 500 größer als der
Speicherbedarf der anderen in |pdata| enthaltenen Parameter. Daher können
Objekte vom Typ |pdata| "komprimiert" werden, wobei die Adjazenz-, Distanz- und
GMatrix gelöscht werden. Diese Komprimierung findet mit der Methode ``flatten``
statt:


Reduzierung des Speicherbedarfs von ProblemData
-----------------------------------------------

.. code-block:: matlab

   pdata = pdata.flatten()
   
In diesem Zustand können die Algorithmen das Problem nicht lösen, da
essenzielle Metadaten fehlen. Daher ist es nötig, ein komprimiertes Objekt vom
Typ |pdata| vorher zu "dekomprimieren":

.. code-block:: matlab

   pdata = pdata.unflatten()
   
Dabei werden die fehlenden Metadaten von neuem berechnet und eingesetzt.


Weitere Methoden von ProblemData
--------------------------------

Des weiteren kann die enthaltene Gartenmatrix direkt geplottet werden:

.. code-block:: matlab

   pdata.plot()
   
oder man lässt sich eine textuelle Beschreibung des Problems ausgeben, zum
Beispiel im Command Window:

.. code-block:: matlab

   pdata.print()

oder in einer Textdatei:

.. code-block:: matlab

   fd = fopen("beispielaufruf_pdata_print.txt", "w");
   pdata.print(fd);
   fclose(fd);

Hierbei ist jedoch zu beachten, dass Algorithmen-spezifische Parameter nicht
mit ausgegeben werden.

Die |pdata|-Klasse akzeptiert noch viele Konstruktor-Key-Value-Parameter, um
sehr spezifische Probleme erzeugen zu können. Mit dieser Problembeschreibung
als Grundlage können wir fortfahren und die Algorithmen zur Lösung der Probleme
betrachten.


.. include:: ../replacements.rst
