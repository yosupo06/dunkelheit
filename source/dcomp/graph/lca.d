module dcomp.graph.lca;

struct LCAInfo {
    int[] dps;
    int[][] anc;
    this(int n) {
        import core.bitop : bsr;
        int lg = n.bsr;
        if (lg == 0 || (2^^lg) < n) lg++;
        dps = new int[n];
        anc = new int[][](lg, n);
    }
}

LCAInfo lca(T)(T g, int r) {
    import std.conv : to;
    const int n = g.length.to!int;
    auto info = LCAInfo(n);
    with(info) {
        int lg = anc.length.to!int;
        void dfs(int p, int b, int nowDps) {
            anc[0][p] = b;
            dps[p] = nowDps;
            foreach (e; g[p]) {
                int d = e.to;
                if (d == b) continue;
                dfs(d, p, nowDps+1);
            }
        }
        dfs(r, -1, 0);
        foreach (i; 1..lg) {
            foreach (j; 0..n) {
                anc[i][j] = (anc[i-1][j] == -1) ? -1 : anc[i-1][anc[i-1][j]];
            }
        }
    }
    return info;
}

int getLCA(in LCAInfo lca, int l, int r) {
    import std.algorithm : swap;
    import std.conv : to;
    int lg = lca.anc.length.to!int;
    with (lca) {
        if (dps[l] < dps[r]) swap(l, r);
        int di = dps[l]-dps[r];
        foreach_reverse (i; 0..lg) {
            if (di < 2^^i) continue;
            di -= 2^^i;
            l = anc[i][l];
        }
        if (l == r) return l;
        foreach_reverse (i; 0..lg) {
            if (anc[i][l] == anc[i][r]) continue;
            l = anc[i][l];
            r = anc[i][r];
        }
    }
    return lca.anc[0][l];
}


unittest {
    import std.algorithm, std.conv, std.stdio, std.range;
    import std.random;
    import std.typecons;
    import std.datetime;

    alias E = Tuple!(int, "to");

    writeln("LCA Random500");

    void f(alias pred)() {
        int n = uniform(1, 50);
        int[] idx = iota(n).array;
        randomShuffle(idx);
        auto g = new E[][n];
        foreach (i; 1..n) {
            int p = uniform(0, i);
            int a = idx[p], b = idx[i];
            g[a] ~= E(b);
            g[b] ~= E(a);
        }
        auto par = new int[n];
        void dfs(int p, int b) {
            par[p] = b;
            foreach (e; g[p]) {
                if (e.to == b) continue;
                dfs(e.to, p);
            }
        }
        int[] makePath(int p) {
            int[] ans;
            while (p != -1) {
                ans ~= p;
                p = par[p];
            }
            return ans;
        }
        int r = uniform(0, n);
        dfs(r, -1);
        auto lcaA = lca(g, r);
        foreach (i; 0..n) {
            foreach (j; 0..n) {
                int u1 = lcaA.getLCA(i, j);
                auto p1 = makePath(i);
                auto p2 = makePath(j);
                reverse(p1);
                reverse(p2);
                int sz = min(p1.length.to!int, p2.length.to!int);
                int u2 = -1;
                assert(p1[0] == p2[0]);
                foreach (x; 0..sz+1) {
                    if (x == sz || p1[x] != p2[x]) {
                        u2 = p1[x-1];
                        break;
                    }
                }
                assert(u1 == u2);
            }
        }
    }
    auto ti = benchmark!(f!lca)(500);
    writeln(ti[0].msecs, "ms");
}
