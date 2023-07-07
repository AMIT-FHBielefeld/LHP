%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%                   BIENENALGORITHMUS         %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [s, pop] = SimulatedAnnealing(pdata, simanparams)
arguments
    pdata (1, 1) lhp.ProblemData
    simanparams (1, 1) lhp.algo.stochastic.siman.SimAnParameters
end

AnzElem     = numel(pdata.Garden);
MaxIter     = simanparams.MaxIter;
MaxStag     = AnzElem;
debug       = simanparams.Debug;

n           = simanparams.NumSimAn;

t=0; % Iterationsvariable

parallelSimAn = 0;

%Simmulated Annealing-Algorithmus
%1) Erzeugung einer zufaelligen Loesung (Hilfsalgorithmus)
parfor (i = 1:n, parallelSimAn)
    hdata = lhp.algo.stochastic.HarkData([], pdata);
    alle_loesungen{i}=hdata; % in die Matrix eintragen
    alle_loesungen_K(i)=hdata.costs(4);
end

[~, idx] = min(alle_loesungen_K); %Minimum bestimmen
best=alle_loesungen{idx};
k_best = best.costs(4);

if debug
    fprintf("%d.) Start-Lösung: HA = %d,  WA = %d, TA = %d, K = %d.\n", t, best.costs(1:4));
end

Temp = best.costs(4);
alpha = 0.97;
%%
k_act_best = Inf;
while t<MaxIter
    if k_act_best > k_best
        zaehler = 0;
        act_best = best;
        k_act_best = k_best;
        if debug
            fprintf("%d.%d) Beste Lösung: Temp = %12.9g, K = %12.9g.\n", t, zaehler, Temp, k_act_best);
        end
    else
        zaehler = zaehler+1;
        if (Temp<1e-8 && zaehler>MaxStag), break; end
    end
    t = t + 1;
    parfor (i = 1:n, parallelSimAn)
        fdata=alle_loesungen{i};
        K = alle_loesungen_K(i);
        fdata = fdata.find_neighbor(pdata);
        df = fdata.costs(4) - K;
        if (df<0) || (rand() < exp(-df/Temp))
            alle_loesungen{i} = fdata;
            alle_loesungen_K(i) = fdata.costs(4);
        end
    end
    Temp = alpha*Temp;
    [~, idx] = min(alle_loesungen_K); %Minimum der aktuellen Population bestimmen
    best=alle_loesungen{idx};
    k_best = best.costs(4);
end
s = act_best.s;

% Shim for compatibility with LHT_GeneticData
pop = [];
end
