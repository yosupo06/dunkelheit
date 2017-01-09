module dcomp.graph.dfsinfo;

struct DFSInfo {
    int[] low, ord, par, vlis; //low, ord, parent, visitList
    int[][] tr; //dfs tree(directed)
    this(int n) {
        low = new int[n];
        ord = new int[n];
        par = new int[n];
        vlis = new int[n];
        tr = new int[][](n);
    }
}

DFSInfo dfsInfo(T)(T g) {
    import std.algorithm : min, each, filter;
    import std.conv : to;
    const int n = g.length.to!int;
    auto info = DFSInfo(n);
    with(info) {
        int co = 0;
        bool[] used = new bool[](n);
        void dfs(int p, int b) {
            used[p] = true;
            low[p] = ord[p] = co++;
            par[p] = b;

            bool rt = true;
            foreach (e; g[p]) {
                int d = e.to;
                if (rt && d == b) {
                    rt = false;
                    continue;
                }
                if (!used[d]) {
                    dfs(d, p);
                    low[p] = min(low[p], low[d]);
                } else {
                    low[p] = min(low[p], ord[d]);
                }
            }
        }
            
        foreach (i; 0..n) {
            if (used[i]) continue;
            dfs(i, -1);
        }
        par.filter!"a!=-1".each!((i, v) => tr[v] ~= i.to!int);
        ord.each!((i, v) => vlis[v] = i.to!int);
    }
    return info;
}
