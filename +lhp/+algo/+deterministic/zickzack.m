function s = zickzack(pdata)
% pdata: ProblemData
GMatrix = pdata.GMatrix;
ZE = size(pdata.Garden, 1);
SP = size(pdata.Garden, 2);
AnzElem = ZE * SP;
MaxLaub = pdata.Max_Val;

% Nachfolgerfunktion initialisieren
s = zeros(AnzElem, 2);

%Nummerierung der Felder in s einf�gen, Nachfolger vorerst 0
for i=1:AnzElem
    s(i)=i;
end

%nicht betretbare Felder erhalten Nachfolger -1
for i=1:AnzElem
    if GMatrix(i,4) < 0
        s(i,2)=-1;
    end
end

shilf = s;                              %Hilfsvariable um s nicht zu ver�ndern
shilf(AnzElem+1,1) = AnzElem+1;
shilf(AnzElem+1,2) = -1;                %F�gt zus�tzliches Element ein um �bertretungen zu vermeiden
Menge = 0;                              %Wert der aktuell angeh�uften Laubmenge
GMatrixhilf = GMatrix;                  %Hilfsvariable um GMatrix nicht zu ver�ndern
GMatrixhilf(AnzElem+1,4) = 0;

for i=1:ZE
    for j=1:SP
        k = (i-1)*SP+j;                       %Feldnummer bestimmen
        if shilf(k,2) ~= -1
            Menge = Menge+GMatrixhilf(k,4);
            if k ~= AnzElem
                if mod(i,2)~=0                      %i= ungerade ->
                    potnachf = k+1;                 %potentieller Nachfahre liegt rechts vom aktuellen feld
                    if mod(k,SP) == 0               %falls aktuelles Feld am Zeilenende ist
                        potnachf = k+SP;            %potentieller Nachfahre unter dem aktuellen
                    end
                    s(k,2) = potnachf;
                    if shilf(potnachf,2) == -1    %falls Nachfahre nicht betretbar
                        s(k,2) = k;                   %bekommt das aktuelle Feld sich selbst als Nachfolger
                        Menge = 0;
                    end
                else                                %i= gerade <-
                    potnachf = k-1;                 %potentieller Nachfahre liegt links vom aktuellen Feld
                    if mod(k-1,SP) == 0             %Falls aktuelles Feld am Zeilenanfang ist
                        potnachf =k+SP;             %potentieller Nachfahre unter dem aktuellen
                    end
                    s(k,2) = potnachf;
                    if shilf(potnachf,2) == -1    %falls Nachfahre nicht betretbar
                        s(k,2) = k;                   %bekommt das aktuelle Feld sich selbst als Nachfolger
                        Menge = 0;
                    end
                end
            else
                s(k,2) = k;
            end
        end
    end
end

% Wenn die Kapazit�tsfunktion die maximale Laubmenge �bersteigt, wird das aktuelle Feld zu einem Hub

% Eingangsvalenzen initialisieren
delta = zeros(AnzElem, 2);

%Nummerierung der Felder in delta einf�gen, Valenzen vorerst 0
for i=1:AnzElem
    delta(i)=i;
end

deltahilf = delta;

%%Eingangsvalenzen ermitteln
for i=1:AnzElem
    if s(i,2)~=-1
        if s(i,1) ~= s(i,2)
            nachfolger = s(i,2);
            deltahilf(nachfolger,2) = deltahilf(nachfolger,2)+1;
        end
    end
end

Q = [];
Qhilf = Q;

%%Harkquellen ermitteln
nachfolger = 0;
for i=1:AnzElem
    if s(i,2)~=-1
        if deltahilf(i,2) == 0
            nachfolger = nachfolger+1;
            Qhilf(nachfolger) = i;
        end
    end
end


% Kapazit�tsfunktion initialisieren
Mkumanfang = zeros(AnzElem,2);
for i=1:AnzElem
    Mkumanfang(i) = i;
end

for i=1:AnzElem
    Mkumanfang(i,2) = GMatrix(i,4);
end
Mkumhilf = Mkumanfang;

%Geht jeden Schritt der Nachfolgerfunktion durch und �berpr�ft, ob die maximale Laubmenge �berschritten wird. Ist dies der Fall, so wird der Vorg�nger des aktuellen Feldes zum Hub

Menge = 0;
k = Qhilf(1);
Menge = Menge+Mkumhilf(k,2);
Mkumhilf(k,2) = 0;
Qhilf = Qhilf(Qhilf~=k);

while isempty(Qhilf) == false
    Qhilf = Qhilf(Qhilf~=k);
    nachfolger = s(k,2);

    if k == nachfolger
        if isempty(Qhilf)==true
%             fprintf('Ermittlung der Nachfolgerfunktion ist abgeschlossen\n')
            break
        else
            Menge = 0;
            k = Qhilf(1);
            Menge = Menge+Mkumhilf(k,2);
            Mkumhilf(k,2) = 0;
        end
    else
        deltahilf(nachfolger,2) = deltahilf(nachfolger,2)-1;
        if deltahilf(nachfolger,2)~=0
            fprintf('Es handelt sich nicht um eine g�ltige Zickzack-Funktion\n')
        else
            vorgaenger = k;
            k = nachfolger;
            Menge = Menge+Mkumhilf(k,2);
            Mkumhilf(k,2) = 0;
            if Menge > MaxLaub
                s(vorgaenger,2) = vorgaenger;
                Menge = GMatrix(k,4);
            end
            Qhilf=[Qhilf nachfolger];
        end
    end
end
