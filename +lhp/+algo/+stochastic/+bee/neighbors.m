function nodes = neighbors(node, pdata)
arguments
    node (1, 1) double;
    pdata (1, 1) lhp.ProblemData;
end
    nodes = find(pdata.Adjacency(node, :))';
return;
