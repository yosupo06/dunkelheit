module dcomp.graph.dfsinfo;

struct DFSInfo {
    int r;
    int[] low, ord, par, vlis; //low, ord, parent, visitList
    int[][] tr; //dfs tree
}

DFSInfo dfsInfo(T)(T g, int r) {
    import std.algorithm : min;
    import std.conv : to;
    const size_t V = g.length;
    DFSInfo info;
    info.r = r;
    info.low.length = V;
    info.ord.length = V;
    info.par.length = V;
    info.tr.length = V;
    
    int co = 0;
    bool[] used = new bool[](V);
    void dfs(int p, int b) {
        used[p] = true;
        bool rt = true;
        info.low[p] = info.ord[p] = co++;
        info.par[p] = b;
        info.vlis ~= p; //optimize?

        foreach (e; g[p]) {
            int d = e.to;
            if (rt && d == b) {
                rt = false;
                continue;
            }
            if (!used[d]) {
                info.tr[p] ~= d;
                dfs(d, p);
                info.low[p] = min(info.low[p], info.low[d]);
            } else {
                info.low[p] = min(info.low[p], info.ord[d]);
            }
        }
    }
        
    if (r != -1) {
        dfs(r, -1);
    } else {
        foreach (i; 0..V) {
            if (used[i]) continue;
            dfs(i.to!int, -1);
        }
    }
    return info;
}
