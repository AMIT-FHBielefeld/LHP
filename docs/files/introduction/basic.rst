Einführung
==========

.. contents::
   :local:


Beschreibung des Laubharkproblems
---------------------------------

Das Laubharkproblem ist ein kombinatorisches Optimierungsproblem, das sich an
dem realen Vorgang des Laubharkes als ein spezielles Entsorgungsproblem
orientiert. Ausgehend von einem Garten, der als beliebig fein gerasterte Matrix
dargestellt wird, gilt es, das im Garten verteilte Laub auf möglichst
kosteneffiziente Art und Weise auf einem Kompost zu entsorgen. Kosten entstehen
dabei durch:

- Das Harken von Laub von einem Feld zum nächsten,
- Das Abtransportieren der Laubhaufen zu einem Kompost, sowie
- Das Zurücklegen unproduktiver Wege, die weder dem Harken noch dem direkten
  Abtransport dienlich sind.

Bei der Lösung des Laubharkproblems ergeben sich mehrere Fragestellungen
(Wörtlich übernommen aus QUELLE):

- Soll das zu entsorgende Laub auf viele kleine oder wenige große Laubhaufen
  zusammengeharkt werden?
- Wo sollen diese Laubhaufen gebildet werden?
- Von welchen Feldern soll zu welchen Laubhaufen geharkt werden?
- In welcher Reihenfolge sollen dabei die einzelnen Felder bearbeitet werden?
- Welcher Aufwand ergibt sich dabei einerseits beim Harkprozess, andererseits
  beim Transportprozess (Abtransport der Laubhaufen mit einem Laubwagen zu
  einer oder zu mehreren Kompoststellen).
- Wie lassen sich dabei unproduktive Wege möglichst vermeiden?

Für eine detailliertere Einführung in die Thematik des Laubharkens, sowie eine
Beleuchtung der mathematischen Grundlagen, wird der interessierte Leser auf das
Manuskript von Hermann-Josef Kruse verwiesen [Quelle-1]_.

.. [Quelle-1] Hallo Andi!


Beschreibung des Aufgabenfeldes
-------------------------------

Im Rahmen des Projektes sind die folgenden Kerninhalte behandelt worden:

1. Implementierung heuristischer Lösungsverfahren nach Hermann-Josef Kruse
2. Entwurf und Implementierung einer Testumgebung für das Laubharkproblem

Darüber hinaus sind während der Arbeit an den Kerninhalten die folgenden 
Nebenaufgaben behandelt worden:

- Aufbereitung und Effizienzsteigerung vorhandenen Quellcodes
- Schaffung und Vereinheitlichung von Interfaces zwischen Programmteilen
- Reduktion der Code-komplexität durch Aggregation von verwandten Teilfunktionen
  in übergeordnete Funktionen
- Implementierung einer Klassenstruktur, zur Objekt-orientierten Handhabung und 
  Bedienung des Projekts
- Neugestaltung eines mit MATLABs veraltetem GUIDE erstellten GUI zur 
  Nutzerinteraktion
- Vollständige Dokumentation der Quellcodes nach Pythons NumPy Standard

Dieses Dokument stellt keine Ausführliche Beschreibung aller im Detail
vorgenommenen Veränderungen am Projekt dar. Der interessierte Nutzer sei zu
diesem Zweck auf die Dokumentation der Quellcodes und die Git-Historie (von
commit 2f326a6 bis 6cbcb7e ) des Projektes verwiesen. Sinn und Zweck dieses
Skriptes ist es, den aktuellen Stand des Projektes zu dokumentieren und Nutzer,
die mit der Arbeit am Laubharkproblem nicht vertraut sind, in die Bedienung der
Quellcodes einzuführen. Die folgenden Unterkapitel widmen sich daher
systematisch einzelnen Teilaspekten des Projektes, begonnen bei der Erzeugung
eines Gartens zur Durchführung von Tests, über die Erstellung eines ProblemData
Objektes zur Verwaltung des Gartens samt einiger Metadaten und über die
eingesetzten Algorithmen bis hin zum TestManager, mit dem parallelisiert Tests
durchgeführt werden können.

.. code-block:: matlab

  % Zeigt die Dokumentation im Command-Window an
  help lhp.Garden.random
  % Alternativ kann man sich die Dokumentation auch im Documentation-Browser ansehen
  doc lhp.Garden.random

  % Besonders interessant ist letzterer Fall fuer Klassen
  doc lhp.utils.TestManager
  % Oder fuer eine explizite Methode
  doc lhp.utils.TestManager.runAllTests
  

Voraussetzungen
---------------

.. important::
   
   Folgende Programme werden benötigt:
   
   - MATLAB in Version 2019b **oder neuer**
   - Parallel Computing Toolbox (Matlab Add-On)
   - varycolor (Matlab Add-On, nur für das testScript.mlx)
