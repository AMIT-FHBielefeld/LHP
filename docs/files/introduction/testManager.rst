Die TestManager-Klasse
======================

.. contents::
   :local:
   

Der |tm| ist die Hauptkomponente der Projektarbeit. Seine Aufgabe ist es, jeden
durchzuführenden Test mit jedem zu testenden Algorithmus auszuführen und die
Ergebnisse dem Nutzer zugänglich zu machen. Dazu hat der |tm| eine interne
Tabelle, in der die Testszenarien die Zeilen und die zu testenden Algorithmen
die Spalten darstellen. Er erfüllt zum aktuellen Zeitpunkt die folgenden
Aufgaben:

- Aufnahme beliebig vieler zu testender Algorithmen
- Aufnahme beliebig vieler durchzuführender Testszenarien
- Parallelisierte Durchführung aller vorbereiteten Tests
- Zugriff auf den gesamten Ergebnisdatensatz
- Zugriff auf bestimmte Teile des Ergebnisdatensatzes (Filterung der Daten)
- Speicherung und spätere Wiederherstellung des TestManagers mit Matlabs save
  und load

Durch das Code-Design ist es beispielsweise möglich, eine zuvor gespeicherte
Instanz des |tm| wiederherzustellen und neue Tests und Algorithmen einzufügen
und ausführen zu lassen. Dabei ist zu beachten, dass nur diejenigen Tests
ausgeführt werden, die noch nicht vorher ausgeführt worden sind. Außerdem ist
es möglich, den |tm| im Betrieb zu unterbrechen und zu einem späteren Zeitpunkt
an der abgebrochenen Stelle mit dem Testen fortfahren zu lassen. All diese
Anwendungsszenarien werden in den folgenden Beispielen gezeigt.

Der Konstruktor des |tm| ist immer leer:
    
.. code-block:: matlab

    tm = lhp.utils.TestManager()

Die Tests sind Objekte vom Typ |pdata|. Dabei stellt jedes Objekt einen eigenen
durchzuführenden Test (Testszenario) dar. Nun fügen wir einige zufällig
erzeugte Tests ein:
    
.. code-block:: matlab

    for idx = 1:5
        pdata = lhp.ProblemData(15, 15, "PopulationSize", 15);
        info_str = sprintf("Testcase %d", idx);
        tm.addTestCase(pdata, info_str);
    end

Das zweite Argument der Funktion ist ein optionaler String, mit dem das
jeweilige Testszenario beschrieben werden kann. Das macht es in der
Ergebnistabelle leichter, den Überblick über die Bedeutung der Tests zu
behalten. Die Methode :meth:`~+lhp.+utils.TestManager.get_results`
zeigt uns die gesamte Ergebnistabelle an:

.. code-block:: matlab

    tm.get_results()

Hier sehen wir nun die eingefügten Testszenarien. Es fehlen noch einige zu
testende Algorithmen:

.. code-block:: matlab

    for alg = lhp.algo.DeterministicWrapper.gather("Range", 1:5)
        tm.addAlgorithm(alg);
    end
    tm.addAlgorithm(lhp.algo.StochasticWrapper(...
        @lhp.algo.stochastic.genetic.genetic, "Genetic"))

Rufen wir das Objekt in der Kommandozeile ohne Methode auf, erfahren wir, wie
der Status aussieht:

.. code-block:: matlab

    tm

Aber wir können uns ebenso die Ergebnistabelle ansehen:

.. code-block:: matlab

    tm.get_results()

Sind die Vorbereitungen getroffen, kann das Testen beginnen. Wie bereits
erwähnt werden die Tests parallelisiert ausgeführt. Spätestens hier ist also
die Parallel Computing Toolbox erforderlich:

.. code-block:: matlab

    tm.runAllTests()

Wie man sieht, informiert uns der |tm| während der Ausführung der Tests über
den aktuellen Status. Der Ladebalken wird bewusst nur alle 2 Sekunden
aktualisiert, um möglichst viele CPU-Ressourcen für das Ausführen der Tests
übrig zu lassen.

Nun, da die Ergebnisse vorliegen, können wir anfangen, die Daten auszuwerten.
Das geht entweder per Hand direkt in der Ergebnistabelle, oder wir nutzen die
angebotenen Methoden zum Filtern der Daten. Dafür ist die Methode
:meth:`~+lhp.+utils.TestManager.extract` zuständig. Die Methode ist
komplex in der Bedienung, aber sehr mächtig hinsichtlich des Nutzen zur
Datenauswertung. Am besten ist es, sich hier mit der Dokumentation vertraut zu
machen, bevor das nächste Beispiel eingeführt wird:

.. code-block:: matlab

    help tm.extract

Nehmen wir an, wir möchten die Gesamtkosten des Algorithmus "|zz|" für jeden
Garten in jedem Test ermitteln.

- Der Algorithmus ist "Zickzack".
- Die Variable ist "Kosten", hier "K".
- Wir sortieren die Daten nicht, weil es für ein und den selben Garten jeweils
  nur einen Test und damit nichts zum sortieren gibt.
- Wir gruppieren die Daten nach den verschiedenen Gärten (Bezeichner für Gärten
  in |pdata| ist "Garden").

Der Aufruf sieht dann wie folgt aus:

.. code-block:: matlab

    [data, grouped_by] = tm.extract("Zickzack", "K", "GroupBy", "Garden")

Nun könnten wir die erhaltenen Daten direkt plotten. Die Daten in ``data(1, 1,
3)`` gehören zu dem Test des dritten Gartens, also ``grouped_by{3}``. Die
Selektion der Daten lässt sich, zum Beispiel mit dem Parameter ``"From"``,
weiter verfeinern. So könnten wir die Ergebnisse spezifisch für Gärten
abfragen, in denen der Index des Kompost (``ProblemData.Target``) kleiner als
100 ist:

.. code-block:: matlab

    selection = tm.where("Target", "<", 100)
    [data, grouped_by] = tm.extract("Zickzack", "K", "GroupBy", "Original", "From", selection)

Weiterführende Beispiele und sonstige Anwendungen des |tm| sind in der Datei
testScript zu sehen, in welcher der |tm| einige Testszenarien berechnet. Um den
TestManager abzuspeichern, verwendet man Matlabs ``save()``-Befehl. 

.. code-block:: matlab

    save mytm_save tm
    clear tm
    load mytm_save
    tm.get_results()

Wie man sieht sind nach dem Speichern, Löschen und erneuten Laden des |tm| alle
Informationen noch erhalten.

Von den Erläuterungen zu |pdata| sollte bekannt sein, dass die Metadaten
(Distanz-, Adjazenz- und GMatrix) den großen Teil des Speichers benötigen. Zu
diesem Zweck lassen sich alle Metadaten der |pdata|-Objekte in der Tabelle vor
dem Speichern entfernen:

.. code-block:: matlab

    tm.flatten();
    save mytm_save_compressed tm
    clear tm
    load mytm_save_compressed
    tm.unflatten();
    tm.get_results()

Und nach dem Speichern wiederherstellen. Bei der Betrachtung der von Matlab
erzeugten Speicherdateien sollte auffallen, dass die "komprimierte" Variante
weniger Speicher braucht. Gerade bei großen Gärten von 50 x 50 Feldern und mehr
fällt dieser Unterschied sehr groß aus. Abschließend ist zu zeigen, dass ein
späteres Hinzufügen neuer Tests und Algorithmen kein Problem für den |tm|
darstellt:

.. code-block:: matlab

    tm.addAlgorithm(lhp.algo.DeterministicWrapper.gather("Range", 12));
    tm.addTestCase(lhp.ProblemData(20, 20, "PopulationSize", 15));
    tm.runAllTests();
    tm.get_results()



..
  Replacements for text above.

.. include:: ../replacements.rst

