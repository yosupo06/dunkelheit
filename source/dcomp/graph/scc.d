module dcomp.graph.scc;

struct SCC {
    int[] id; // vertex id -> scc id
    int[][] groups; // scc id -> scc vertexs
    int count; // scc count
    this(int n) {
        id = new int[n];
    }
}

import dcomp.array;

SCC scc(T)(T g) {
    import std.array : appender;
    import std.range;
    import std.algorithm : each, map;
    import std.conv : to;
    int n = g.length.to!int;
    //make reverse graph
    struct Edge {int to;}
    FastAppender!(Edge[])[] rg_buf = new FastAppender!(Edge[])[](n);
    g.each!((i, v) => v.each!(e => rg_buf[e.to] ~= Edge(i.to!int)));
    auto rg = rg_buf.map!(v => v.data).array;

    auto sccInfo = SCC(n);
    with (sccInfo) {
        auto used = new bool[n];

        //make backorder list
        auto vs = appender!(int[])();
        void dfs(int v) {
            used[v] = true;
            foreach (e; g[v]) {
                if (used[e.to]) continue;
                dfs(e.to);
            }
            vs ~= v;
        }
        foreach (i; 0..n) {
            if (used[i]) continue;
            dfs(i);
        }

        used[] = false;        
        count = 0;
        auto buf = appender!(int[])();
        void rdfs(int v) {
            used[v] = true;
            id[v] = count;
            buf ~= v;
            foreach (e; rg[v]) {
                if (used[e.to]) continue;
                rdfs(e.to);
            }
        }
        auto groups_buf = appender!(int[][])();
        foreach_reverse (i; vs.data) {
            if (used[i]) continue;
            rdfs(i);
            groups_buf ~= buf.data.dup;
            buf.clear();
            count++;
        }
        groups = groups_buf.data;
    }
    return sccInfo;
}

unittest {
    import std.algorithm, std.conv, std.stdio, std.range;
    import std.random;
    import std.typecons;
    import std.datetime;

    struct E {int to;}

    writeln("SCC Random1000");
    void f() {
        int n = uniform(1, 50);
        int p = uniform(1, 50);
        E[][] g = new E[][n];
        bool[][] naive = new bool[][](n, n);
        foreach (i; 0..n) {
            foreach (j; 0..n) {
                if (i == j) continue;
                if (uniform(0, 100) < p) {
                    g[i] ~= E(j);
                    naive[i][j] = true;
                }
            }
        }

        auto sccInfo = scc(g);

        foreach (k; 0..n) {
            foreach (i; 0..n) {
                foreach (j; 0..n) {
                    naive[i][j] |= naive[i][k] && naive[k][j];
                }
            }
        }

        foreach (i; 0..n) {
            foreach (j; i+1..n) {
                bool same = sccInfo.id[i] == sccInfo.id[j];
                if (same) {
                    assert(naive[i][j] && naive[j][i]);
                } else {
                    assert(!naive[i][j] || !naive[j][i]);                    
                    if (sccInfo.id[i] < sccInfo.id[j]) {
                        assert(!naive[j][i]);
                    } else {
                        assert(!naive[i][j]);
                    }
                }
            }
        }
    }
    auto ti = benchmark!(f)(1000);
    writeln(ti[0].msecs, "ms");
}
