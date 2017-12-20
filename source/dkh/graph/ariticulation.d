module dkh.graph.ariticulation;

import dkh.graph.dfstree;

struct AriticulationInfo {
    bool[] isArit; // is Ariticulation point
    bool[] isDiv; // is Div when parent remove
};

AriticulationInfo ariticulation(T)(T g) {
    return ariticulation(g, dfsTree(g));
}

AriticulationInfo ariticulation(T)(T g, DFSTreeInfo info) {
    AriticulationInfo arit;
    arit.isArit.length = g.length;
    arit.isDiv.length = g.length;
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

unittest {
    import std.algorithm : equal;
    import std.typecons;
    alias E = Tuple!(int, "to");
    E[][] g = new E[][4];
    g[0] ~= E(1); g[1] ~= E(0);
    g[0] ~= E(2); g[2] ~= E(0);
    g[1] ~= E(2); g[2] ~= E(1);
    g[1] ~= E(3); g[3] ~= E(1);
    auto ai = g.ariticulation;
    import std.stdio;
    writeln(dfsTree(g));
    writeln(ai);
    assert(equal(ai.isArit, [false, true, false, false]));
}
