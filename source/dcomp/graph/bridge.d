module dcomp.graph.bridge;

import dcomp.graph.dfsinfo;

struct Bridge {
    int gc;
    int[] ig, gpar; // i to group, group parent
    bool[] isRoot;
}

Bridge bridge(T)(T g) {
    return bridge(g, dfsInfo(g, -1));
}

Bridge bridge(T)(T g, DFSInfo info) {
    assert(info.r == -1);
    size_t V = g.length;
    Bridge br;
    
    br.ig.length = V;
    br.isRoot.length = V;

    foreach (p; info.vlis) {
        br.isRoot[p] = (info.low[p] == info.ord[p]);
        if (br.isRoot[p]) {
            br.ig[p] = br.gc++;
            br.gpar ~= ((info.par[p] == -1) ? -1 : br.ig[info.par[p]]);
        } else {
            br.ig[p] = br.ig[info.par[p]];
        }
    }
    return br;
}
