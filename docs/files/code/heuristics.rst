.. module:: +lhp.+algo.+deterministic

.. _docs-heuristiken:

Deterministische heuristische Algorithmen
=========================================
   
.. warning::
   Ein direkter Aufruf der hier aufgeführten Heuristiken ist zwar möglich, wird 
   aber nicht empfohlen. Stattdessen soll, wie in der 
   :ref:`Einführung <einfuehrung-heuristiken>` gezeigt, die 
   |dw| Klasse verwendet werden!

.. contents::
   :local:

Deterministische Heuristiken erarbeiten auf deterministische Weise Lösungen für
das Laubharkproblem. Zum aktuellen Zeitpunkt sind insgesamt 87 Heuristiken
implementiert, die auf dieser Seite dokumentiert sind.

.. tip::

   Aus diesen 83 liefern 5 Algorithmen in 69 % der Fälle die besten Lösungen. 
   Die im folgenden genannten Bezeichner entsprechen im weitesten Sinne den 
   Namen der Matlab-Funktionen, die sie repräsentieren. Die sicherste Methode, 
   die korrekten Algorithmen ,,zu treffen'' ist, die angegebenen Indizes im 
   Zusammenhang mit der Methode :meth:`~+lhp.+algo.DeterministicWrapper.gather`
   zu verwenden.
   
   ======================  ==================  =====
   Name des Algorithmus    Beste Lösungen (%)  Index
   ======================  ==================  =====
   sucC-NW-FIFO-LMmax      21.90 %             19
   SucC-LMmax-FIFO-LMmax   21.19 %             7
   SucC-LMmin-FIFO-LMmax   11.67 %             13
   SucC-LMmin-FIFO-KPmin   8.33 %              12
   simC-LMmin-LMmin-LMmax  5.71 %              65
   ======================  ==================  =====
   
   Diese Ergebnisse wurden mit dem Testszenario 1.3 im ``testScript`` erzeugt.
   
Für alle im folgenden genannten Verfahren (Mit Ausnahme des 
*zickzack*-Algorithmus) gibt es **spezialisierte** Matlab-Funktionen, die die 
hier gezeigten Grundfunktionen mit festgelegten Parametern aufrufen.

Sinn und Zweck dieser Spezialisierungen ist, das Interface zum Arbeiten mit den 
Algorithmen zu vereinfach, sodass nur 1 Parameter (vom Typ 
|pdata|) übergeben wird, und eine Nachfolgerfunktion als 
Rückgabeparameter erhalten wird.


Sukzessive Clusterverfahren
---------------------------

.. note::
   
   Die ,,vollfaktorielle'' Kombination aller unten genannten Funktionsparameter 
   ergibt insgesamt 18 verschieden Varianten dieses Lösungsverfahrens. Nur eine 
   Auswahl aus diesen 18 Varianten liefert auch gute Lösungen.

.. currentmodule:: +lhp.+algo.+deterministic.+successive_cluster
.. autofunction:: successive_cluster


Simultane Clusterverfahren
--------------------------

.. note::
   
   Die ,,vollfaktorielle'' Kombination aller unten genannten Funktionsparameter 
   ergibt insgesamt 64 verschieden Varianten dieses Lösungsverfahrens. Nur eine 
   Auswahl aus diesen 64 Varianten liefert auch gute Lösungen.

.. currentmodule:: +lhp.+algo.+deterministic.+simultaneous_cluster
.. autofunction:: simultaneous_cluster


Zickzack
--------

Der Zickzackalgorithmus beginnt im Feld mit dem kleinsten Index (Links-oben)
und arbeitet sich von dort Zeilenweise bis zum letzten Feld voran. Er häuft so 
lange Laub auf dem jeweils folgenden Feld an, bis die maximale Laubmenge 
erreicht ist oder überschritten werden würde. Dort beginnt er ein neues
Laubcluster und fährt wie beschrieben fort.

.. currentmodule:: +lhp.+algo.+deterministic
.. autofunction:: zickzack


.. include:: ../replacements.rst

