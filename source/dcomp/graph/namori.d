module dcomp.graph.namori;

import dcomp.graph.dfsinfo;

struct Namori {
    bool[] isCycle;
    int[][] cycles;
    int[] root;
    this(int n) {
        isCycle = new bool[n];
        root = new int[n];
    }
}

Namori namori(T)(T g) {
    import std.algorithm : find, each;
    import std.range;
    import std.conv : to;
    int n = g.length.to!int;
    auto info = dfsInfo(g);
    auto nmr = Namori(n);
    with (nmr) {
        //find self loop
        foreach (i; 0..n) {
            if (g[i].find!(e => e.to == i).empty) continue;
            isCycle[i] = true;
            cycles ~= [i];
        }
        foreach (p; info.vlis) {
            if (info.low[p] == info.ord[p]) continue;
            if (g[p].length == info.tr[p].length+1) continue;
            int[] v;
            int nw = p;
            while (info.ord[nw] != info.low[p]) {
                v ~= nw;
                nw = info.par[nw];
            }
            v ~= nw;
            v.each!(i => isCycle[i] = true);
            cycles ~= v;
        }
        bool[] used = new bool[n];
        void dfs(int p, int b, int r) {
            if (used[p]) return;
            used[p] = true;
            root[p] = r;
            foreach (e; g[p]) {
                int d = e.to;
                if (d == b) continue;
                if (isCycle[d]) continue;
                dfs(d, p, r);
            }
        }
        foreach (i; 0..n) {
            if (!isCycle[i]) continue;
            dfs(i, -1, i);
        }
    }
    return nmr;
}

Namori directedNamori(int[] g) {
    import std.algorithm : find, each;
    import std.range;
    import std.conv : to;
    int n = g.length.to!int;
    auto nmr = Namori(n);
    with (nmr) {
        int[] used = new int[n]; used[] = -1;
        foreach (i; 0..n) {
            if (used[i] != -1) continue;
            int j = i;
            while (used[j] == -1) {
                used[j] = i;
                j = g[j];
            }
            if (used[j] != i) continue;
            int k = j;
            int[] cy = [];
            while (true) {
                cy ~= k;
                isCycle[k] = true;
                if (g[k] == j) break;
                k = g[k];
            }
            cycles ~= cy;
        }
        int[] dp = new int[n]; dp[] = -1;
        int dfs(int p) {
            if (isCycle[p]) return p;
            if (dp[p] != -1) return dp[p];
            return dp[p] = dfs(g[p]);
        }
        foreach (i; 0..n) {
            root[i] = dfs(i);
        }
    }
    return nmr;
}
