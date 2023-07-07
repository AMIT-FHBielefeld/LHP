Testumgebung für das Laubharkprojekt
====================================

.. contents::
   :local:


Die hier beschriebene Testumgebung meint keine Testumgebung, wie man sie aus
der klassischen Softwareentwicklung zum testen von Softwarekomponenten
(*Stichwort: Unit-Tests, etc.*) kennt. Stattdessen handelt es sich bei der
Testumgebung um eine Sammlung von Codes, mit der die verschiedenen
implementierten Algorithmen in verschiendenen Testszenarien getestet und
hinterher gegen einander verglichen werden können.
Es geht hierbei also mehr um ein Vergleichen der Effizienz der Algorithmen, als
um das finden und beheben von Programmierfehlern.

Das Herzstück der Testumgebung ist der |tm|. Er wird auch im ``testScript``
vielfach verwendet.


Der |tm|
--------

Der |tm| erfüllt im Projekt mehrere Aufgaben:

- Parallelisierte Durchführung von Tests
- Strukturierte Speicherung von Testergebnissen
- Einheitlicher Umgang mit |dw|, sowie |sw|
- Aufnahme nahezu beliebig vieler zu testender Algorithmen
- Aufnahme nahezu beliebig vieler durchzuführender Testszenarien
- Zugriff auf den gesamten Datensatz, mit optionaler Filterung nach
  festgelegten Kriterien
- Speicherung und spätere Wiederherstellung des |tm| mit Matlabs ``save`` und
  ``load``

Aufgrund seines Designs kann eine zu einem früheren Zeitpunkt abgespeicherte
Instanz des |tm| zu einem späteren Zeitpunkt mit neuen zu testenden Algorithmen
oder Testszenarien erweitert werden. Darüber hinaus kann ein laufender
Testdurchlauf ohne Datenverluste mit ``<Ctrl + C>`` abgebrochen, und zu einem
späteren Zeitpunkt fortgeführt werden.

.. module:: +lhp.+utils
.. autoclass:: TestManager
   :members:


Die |tsu|
---------

Die |tsu| kommen vorrangig im ``testScript`` zum Einsatz und sollen dem Nutzer
dabei helfen, das Speichern und Laden von Testergebnissen zu vereinfachen.
Dazu werden Testergebnisse nur dann erzeugt, wenn noch keine gespeicherten
Ergebnisse vorliegen. Liegen gespeicherte Werte vor, werden diese in den
Workspace geladen. Andernfalls werden die notwendigen Werte erzeugt und an
einer definierten Stelle im Projekt (im Moment unter
``LHT/Ergebnisse/testScript_tests/``) abgelegt.

Dieser Vorgang funktioniert nicht voll automatisch. Anwendungen für den Umgang
findet man im ``testScript`` genügend. 

Hier ist eine kurze Anleitung:

.. code-block:: matlab

   if ~testScriptUtils.loadTest(1, 1)
       % Tests vorbereiten und durchführen
       % ...
       tm.runAllTests();

       % Speichern der Daten. Hier werden die Namen der zu speichernden
       % Variablen als Strings übergeben. Es können beliebig viele sein.
       testScriptUtils.saveTest(1, 1, "tm"); 
   end

Sollten ein Datensatz mit dem Namen ``Test-1-1_....`` existieren, so wird
dieser Datensatz geladen und der Körper der ``if``-Bedingung nicht weiter
ausgeführt. Andernfalls werden die Tests durchgeführt und ein Datensatz
angelegt.

.. warning::
   Die Nummern der Datensätze müssen eindeutig sein! Zahlenkombinationen wie 1,
   1 sollten nicht für mehrere unterschiedliche Tests verwendet werden, da alle
   Tests in dem selben Verzeichnis gespeichert werden!

.. module:: Ergebnisse.testScript_tests
.. autoclass:: testScriptUtils
   :members:


.. |tsu| replace:: :class:`testScriptUtils <Ergebnisse.testScript_tests.testScriptUtils>`

.. include:: ../replacements.rst

