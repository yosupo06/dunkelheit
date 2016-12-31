module dcomp.graph.ariticulation;

import dcomp.graph.dfsinfo;

struct Ariticulation {
    bool[] isArit; // is Ariticulation point
    bool[] isDiv; // is Div when parent remove
};

Ariticulation ariticulation(T)(T g) {
    return ariticulation(g, dfsInfo(g, -1));
}

Ariticulation ariticulation(T)(T g, DFSInfo info) {
    Ariticulation arit;
    size_t V = g.length;
    arit.isArit.length = V;
    arit.isDiv.length = V;
    foreach (p ; info.vlis) {
        if (info.par[p] == -1) {
            //root
            arit.isArit[p] = (info.tr[p].length >= 2);
            foreach (d; info.tr[p]) {
                arit.isDiv[d] = true;
            }
        } else {
            arit.isArit[p] = false;
            foreach (d; info.tr[p]) {
                if (info.low[d] >= info.ord[p]) {
                    arit.isArit[p] = true;
                    arit.isDiv[d] = true;
                }
            }
        }
    }    
    return arit;
}
