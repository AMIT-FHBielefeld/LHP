Dokumentation des Quellcodes
============================

.. toctree::
   :maxdepth: 2

   garden
   heuristics
   bio
   wrappers
   costs
   testing
   
Große Teile des Quellcodes sind in den Matlab-Quelldateien dokumentiert. Die
Dokumentation orientiert sich dabei im Moment am NumPy Dokumentationsstandard
[#f1]_.
Dadurch ist die Form der Dokumentation konsistent, und die vorliegende HTML
Dokumentation kann mit Sphinx [#f2]_ automatisiert erzeugt werden. Da Sphinx
ursprünglich für Python entwickelt wurde, wird außerdem die Erweiterung
*matlabdomain* [#f3]_ verwendet. Zuletzt kommt die Sphinx-Erweiterung
*napoleon* [#f4]_ zum Einsatz, die die Numpy-formatierten Dokumentation
verarbeiten kann. Andernfalls würde Sphinx erwarten, dass die Dokumentation im
Quellcode als restructured text formatiert ist. Aus Gründen der Lesbarkeit
(gerade direkt im Quelltext) ist jedoch auf eine reST Formatierung verzichtet
worden.

Der Leser sei vorab noch darauf hingewiesen, dass die Sprache, in der die
Dokumentation verfasst ist, nicht einheitlich ist. Einige Teile von früh im
Projektverlauf implementierten Algorithmen sind auf deutsch dokumentiert (vor
allem die Funktionsbeschreibungen), während die Parameterbeschreibungen etc.
zum großen Teil auf englisch vorliegen.
Gründe, die Dokumentation in englisch zu verfassen, gibt es gleich mehrere:

- Die Dokumentation hat so ein größeres Publikum.
- Im englischen gibt es keine Umlaute (ä, ö, ü, ß), alle geschriebenen Zeichen
  sind mit ASCII darstellbar und somit kommt es nicht zu Darstellungsfehlerin in
  Matlab.
- Sphinx erwartet ohnehin englische Schlüsselwörter für einzelne
  Dokumentations-Abschnitte (z.B. ,,Parameters'').

Mangels Zeit, um das Projekt weiter voran zu treiben, ist auf eine vollständige
Übersetzung aller Kommentare verzichtet worden. Zukünftige Projekte sollten
diesen ,,Fehler'' beheben und die Dokumentation in einer einheitlichen Sprache
verfassen.


Das erzeugen der Dokumentation
------------------------------

Wie erwähnt wird die Dokumentation mit Sphinx erzeugt. Um
Kompatibilitätsprobleme zu vermeiden, wird Sphinx nicht direkt auf dem Rechner
installiert. Stattdessen **muss** eine Container-Umgebung installiert sein. Im
Moment ist das entweder:

- `Docker <https://www.docker.com/>`_, oder
- `Podman <https://podman.io/>`_

Erzeugt wird die Dokumentation in einem selbst-erstellten Container image. Dazu
muss einmal das im Ordner ``LHT/docs/container/`` enthaltene Dockerfile gebaut
werden:

.. code-block:: bash

   docker build --tag mysphinx Dockerfile
   # ODER
   podman build --tag mysphinx Dockerfile


Ist der Container gebaut, wird die Dokumentation aus dem Ordner ``LHT/docs/``
heraus erzeugt:

.. code-block:: bash

   docker run --rm -v ../:/project mysphinx make html
   # ODER
   podman run --rm -v ../:/project:z mysphinx make html

Der oben genannte Befehl erzeugt eine Dokumentation im HTML Format. Aber auch
andere Formate wie PDF oder Latex-Quellcode sind möglich. Siehe `hier
<https://www.sphinx-doc.org/en/master/man/sphinx-build.html?highlight=output%20format#cmdoption-sphinx-build-b>`_.

Die erzeugte Dokumentation kann dann im Ordner ``LHT/docs/_build/html/``
gefunden werden. Um die Dokumentation in Firefox anzusehen, reicht der Befehl:

.. code-block:: bash

   firefox _build/html/index.html


Zeal/Dash Docsets
-----------------

Aus der erzeugten HTML Dokumentation lassen sich Docsets für `Zeal`_ und
`Dash`_ generieren. Dazu wird das Python-tool ``dash2doc`` benötigt, das in dem
erzeugten Container aber bereits enthalten ist. Die Docsets werden dann wie
folgt erzeugt (aus dem Ordner ``LHT/docs/``):

.. code-block:: bash

   docker run --rm -it -v ../:/project mysphinx doc2dash -n Laubharken _build/html
   # ODER
   podman run --rm -it -v ../:/project:z mysphinx doc2dash -n Laubharken _build/html

Das erzeugte Docset befindet sich dann in einem Ordner Namens
``Laubharken.docset`` unter ``LHT/docs/``. Von dort muss es lediglich an die
richtige Stelle kopiert werden, damit `Zeal`_ und `Dash`_ die Dokumentation
auch finden. Wo genau der Ort ist, an dem die Docsets liegen müssen, entnimmt
man am besten der Dokumentation des jeweiligen Programms.


.. [#f1] Numpy Standard: https://numpydoc.readthedocs.io/en/latest/format.html
.. [#f2] Sphinx: https://www.sphinx-doc.org/en/master/
.. [#f3] matlab-contrib: https://github.com/sphinx-contrib/matlabdomain
.. [#f4] napolen: https://www.sphinx-doc.org/en/master/usage/extensions/napoleon.html

.. _Zeal: https://zealdocs.org/
.. _Dash: https://kapeli.com/dash
