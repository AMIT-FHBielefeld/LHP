.. Laubharkproblem documentation master file, created by
   sphinx-quickstart on Fri Dec 11 11:45:07 2020.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Willkommen zur Dokumentation des Laubharkprojektes
==================================================

.. toctree::
   :maxdepth: 2
   :caption: Inhalte:

   files/introduction/index
   files/code/index
   files/gui/index


Punkte zur Diskussion beim nächsten mal
=======================================

Zeitmessung der Algorithmen sollte überarbeitet werden
    Im Moment misst die Zeitmessung die reine Ausführungszeit der Algorithmen,
    **exklusive** nachgelagerter Optimierungen (Wie von :func:`PostOptimize
    <lhp.algo.DeterministicWrapper.DeterministicWrapper>`). Das sollte ggf.
    überarbeitet werden... ?


Projektweite TODOs
==================

.. todolist::


Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
