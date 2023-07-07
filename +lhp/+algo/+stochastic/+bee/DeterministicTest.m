%% Matrix aus Excel einlesen
% rng(1)
% addpath(genpath("../."));
import('lhp.*');
import('lhp.utils.*');
import('lhp.rating.*');
import('lhp.algo.*');

clear all;

format long g     %um Rundungsfehler zu vermeiden

% pdata = lhp.ProblemData(10, 10);

%load Tests/tm_13_13.mat;
load('C:\UserData\SVNsIntern\BB_Projekte\Laubhark_Problem\Programm\Ergebnisse\Huge-benchmark\20230209-huge-benchmark-oml0-262.mat')
A=tm.get_results;
B=A(4,:);
KK = zeros(size(B,2)-3,1);
for i=4:size(B,2)
  KK(i-3) = B(1,i).(1){1}.K;
end
min(KK)
