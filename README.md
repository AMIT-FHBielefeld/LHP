# Das Laubharkprojekt

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

Bei der Lösung des Laubharkproblems ergeben sich mehrere Fragestellungen:

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
Manuskript von Hermann-Josef Kruse verwiesen [1].

## Veröffentlichung zu diesem Projekt

Deterministische und bionische Heuristiken zur Lösung von Entsorgungsproblemen

Am Beispiel des Laubharkproblems von Karim Abdelhak, Bernhard Bachmann, Ralf Derdau, Andreas Hartmann und Hermann-Josef Kruse, lizenziert unter CC BY-SA 4.0 International Public License.
ISSN: 2196-6192
[DOI] (https://doi.org/10.57720/3321)

## Voraussetzungen

Um mit dem Laubharkprojekt arbeiten zu können, ist folgendes notwendig:

- MATLAB in Version 2019b oder neuer (*Ältere Versionen funktionieren NICHT!*)
- Parallel Computing Toolbox Add-On
- Statistics and Machine Learning Toolbox (für das `testScript.mlx`)
- varycolor Add-On (für das `testScript.mlx`)


## Verwendung

Eine Einführung in das arbeiten mit dem Code des Laubharkprojekts gibt die
[Projektarbeit von Andreas Hartmann][10] ([PDF Version][11]).

Weiterführende Anwendungen befinden sich im
[testScript.mlx](LHT/testScript.mlx).


## Struktur

Die Quellcodes befinden sich im Unterordner [LHT](LHT/). Literatur rund um das
Laubharkprojekt befindet sich im Ordner [Literatur](Literatur/).


[1]: Literatur/Projektarbeit_Hartmann/Quellen/Manuskript.pdf
[10]: Literatur/Projektarbeit_Hartmann/Projektbericht_Andreas_Hartmann.mlx
[11]: Literatur/Projektarbeit_Hartmann/Projektbericht_Andreas_Hartmann.pdf

## Lizenz

lhp ist open-source software verfügbar unter the GNU General Public License v3 
(GPL-3) auf: https://github.com/AMIT-HSBI/LHP

