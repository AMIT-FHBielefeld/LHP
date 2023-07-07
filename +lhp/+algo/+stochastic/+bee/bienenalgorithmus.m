%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%                   BIENENALGORITHMUS         %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [s, pop] = bienenalgorithmus(pdata, beeparams)
arguments
    pdata (1, 1) lhp.ProblemData
    beeparams (1, 1) lhp.algo.stochastic.bee.BeeParameters
end

AnzElem  = numel(pdata.Garden);
Bees     = floor(sqrt(size(pdata.GMatrix,1))/4);

% n           = 3*Bees;
% m           = 3*Bees;
% nsp         = beeparams.NumBestSolutionNeighbors;
% e           = 1*Bees;
% nep         = beeparams.NumEliteSolutionNeighbors;
n           = beeparams.NumScoutBees;
m           = beeparams.NumBestSolutions;
nsp         = beeparams.NumBestSolutionNeighbors;
e           = beeparams.NumEliteSolutions;
nep         = beeparams.NumEliteSolutionNeighbors;
MaxIter     = beeparams.MaxIter;
MaxStag     = sqrt(AnzElem);
debug       = beeparams.Debug;
ProbabilityToChooseWorseNeighbor = beeparams.ProbabilityToChooseWorseNeighbor;

useHeuristics = true;
% Definiert das Verhalten von "parfor". Auf 0 lassen, um parfor zu
% deaktivieren.
%
% .. todo:: Mit ins BeeParameters GUI aufnehmen
parallelBees = 0;

if beeparams.Algorithms == 0
    % Don't use heuristics at all!
    verfahren = [];
    useHeuristics = false;
else
    verfahren = lhp.algo.DeterministicWrapper.gather("StoreResults", false, ...
        "Range", beeparams.Algorithms);
end
%%%%%%%%%%% Vordefinierte zus�tzliche Arrays %%%%%%%%%%
%loesung=zeros(AnzElem+2,MaxIter-1);
t=0; % Iterationsvariable

%Bienen-Algorithmus

%1) Die n Scoutbienen erzeugen jeweils eine zuf�llige L�sung (Hilfsalgorithmus)
for i = 1:n
    if useHeuristics
%        [~, result] = verfahren(randi([1 length(verfahren)])).add_new_data(...
%            pdata);
        [~, result] = verfahren(i).add_new_data(pdata);
        s = lhp.utils.skip_zero_hubs(pdata, result.s);
        s = lhp.utils.hz(pdata,s,'Median');
        s = lhp.utils.skip_zero_hubs(pdata, s);
        hdata = lhp.algo.stochastic.HarkData(s, pdata);
        if debug
            fprintf("%d.) Beste Lösung: HA = %d,  WA = %d, TA = %d, K = %d.\n", i, hdata.costs(1:4));
        end
    else
        hdata = lhp.algo.stochastic.HarkData([], pdata);
    end
    alle_loesungen{i}=hdata; % in die Matrix eintragen
    alle_loesungen_K(i)=hdata.costs(4);
end
[~, idx] = min(alle_loesungen_K); %Minimum bestimmen
best=alle_loesungen{idx};
if debug
    fprintf("%d.) Beste Lösung: HA = %d,  WA = %d, TA = %d, K = %d.\n", t, best.costs(1:4));
end

%%
k_act_best = Inf;
k_best = best.costs(4);
zaehler = 0;
while t<MaxIter+1
    t = t + 1;

    [~,indices] = sort(alle_loesungen_K);
    alle_loesungen = {alle_loesungen{indices}};
    alle_loesungen_K = alle_loesungen_K(indices);
    k_best = alle_loesungen_K(1);

    if k_act_best > k_best
        zaehler = 0;
        k_act_best = k_best;
    else
        zaehler = zaehler+1;
        if (zaehler>MaxStag), break; end
    end
    % 2)e Elite-Loesungen aus n L�sungen bestimmen
    for eliteSide = 1:e
        hdata_elite=alle_loesungen{eliteSide};
        K_elite = alle_loesungen_K(eliteSide);
        for j=1:nep
            fdata = hdata_elite.find_neighbor(pdata);
            if (K_elite > fdata.costs(4)) || (rand() < ProbabilityToChooseWorseNeighbor && K_elite < fdata.costs(4) && eliteSide~=1)
                alle_loesungen{eliteSide} = fdata;
                alle_loesungen_K(eliteSide) = fdata.costs(4);
                hdata_elite = fdata;
                K_elite = fdata.costs(4);
            end
        end
    end
    % 3)m Beste-Loesungen aus n L�sungen bestimmen
    for bestSide = e+1:m
        hdata_best=alle_loesungen{bestSide};
        K_best = alle_loesungen_K(bestSide);
        for j=1:nsp
            fdata = hdata_best.find_neighbor(pdata);
            if (K_best > fdata.costs(4)) || (rand() < ProbabilityToChooseWorseNeighbor && K_best < fdata.costs(4))
                alle_loesungen{bestSide} = fdata;
                alle_loesungen_K(bestSide) = fdata.costs(4);
                hdata_best = fdata;
                K_best = fdata.costs(4);
            end
        end
    end

    % n-m neue L�sungen berechnen
    for actSide = m+1:n
        if useHeuristics
%        [~, result] = verfahren(randi([1 length(verfahren)])).add_new_data(...
%            pdata);
            [~, result] = verfahren(i).add_new_data(pdata);
            s = lhp.utils.skip_zero_hubs(pdata, result.s);
            s = lhp.utils.hz(pdata,s,'Median');
            s = lhp.utils.skip_zero_hubs(pdata, s);
            hdata = lhp.algo.stochastic.HarkData(s, pdata);
        else
            hdata = lhp.algo.stochastic.HarkData([], pdata);
        end
        % .. todo:: Das kam ebenfalls aus dem Merge-conflict... Welches nehmen wir??
        %
        %         parfor actSide=m+1:n
        %            hdata = HarkData.initialHarkData(verfahren, pdata, useHeuristics);
        alle_loesungen{actSide}=hdata; % in die Matrix eintragen
        alle_loesungen_K(actSide)=hdata.costs(4);
    end
    if debug && rem(t,1)==0
        [~, idx] = min(alle_loesungen_K); %Minimum bestimmen
        best=alle_loesungen{idx};
        fprintf("%d.) Beste Lösung: HA = %d,  WA = %d, TA = %d, K = %d.\n", t, best.costs(1:4));
    end
end
%Die best-gefundene Lösung ausgeben
[~, idx] =  min(alle_loesungen_K); %Minimum bestimmen
best=alle_loesungen{idx};
K_best = best.costs(4);

% Erzeuge verschiedene Hubzentrierung,und überprüfe, ob
% Verbesserungen auftreten
s1 = lhp.utils.hz(pdata,best.s,'MaxLaub');
[~, ~, ~, K1] = lhp.rating.get_costs(s1, pdata);
s2 = lhp.utils.hz(pdata,best.s,'MinKompost');
[~, ~, ~, K2] = lhp.rating.get_costs(s2, pdata);
if (K1 < K_best) && (K1 < K2)
    s = s1;
elseif (K2 < K_best) && (K2 < K1)
    s = s1;
else
    s = best.s;
end

% Shim for compatibility with LHT_GeneticData
pop = [];
end
