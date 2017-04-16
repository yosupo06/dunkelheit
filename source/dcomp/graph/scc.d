module dcomp.graph.scc;

import dcomp.array;
import dcomp.graph.primitive;
import dcomp.container.deque;

struct SCCInfo {
    int[] id; // vertex id -> scc id
    int[][] groups; // scc id -> scc vertexs
    this(int n) {
        id = new int[n];
    }
}

SCCInfo scc(T)(T g) {
    import std.range;
    import std.algorithm : each, map, min, reverse;
    import std.conv : to;
    int n = g.length.to!int;
    auto sccInfo = SCCInfo(n);
    with (sccInfo) {
        bool[] inS = new bool[n];
        int[] low = new int[n], ord = new int[n]; ord[] = -1;
        int time = 0;
        Deque!int st;
        int bufC = 0;
        FastAppender!(int[]) buf; buf.reserve(n);
        FastAppender!(int[][]) gBuf;
        void dfs(int v) {
            low[v] = ord[v] = time++;
            st.insertBack(v);
            inS[v] = true;
            foreach (e; g[v]) {
                if (ord[e.to] == -1) {
                    dfs(e.to);
                    low[v] = min(low[v], low[e.to]);
                } else if (inS[e.to]) {
                    low[v] = min(low[v], ord[e.to]);
                }
            }
            if (low[v] == ord[v]) {
                int p = st.length.to!int - 1;
                while (true) {
                    int u = st.back; st.removeBack;
                    buf ~= u;
                    if (u == v) break;
                }
                auto gr = buf.data[bufC..$];
                bufC = buf.length.to!int;
                gr.each!(x => inS[x] = false);
                gBuf ~= gr;
            }
        }
        foreach (i; 0..n) {
            if (ord[i] == -1) dfs(i);
        }
        groups = gBuf.data;
        reverse(groups);
        groups.each!((i, v) => v.each!(x => id[x] = i.to!int));
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
            int iid = sccInfo.id[i];
            assert(sccInfo.groups[iid].find(i).empty == false);
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
