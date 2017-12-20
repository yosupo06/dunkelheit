module dkh.graph.scc;

import dkh.graph.primitive;
import dkh.container.stackpayload, dkh.container.deque;

/// 強連結成分の情報
struct SCCInfo {
    int[] id; /// 頂点id -> 強連結成分id
    int[][] groups; /// 強連結成分id -> その連結成分の頂点idたち
    /// iと同じgroupの頂点を返す
    const(int[]) group(size_t i) const {
        return groups[id[i]];
    }    
    this(size_t n) {
        id = new int[n];
    }
}

/// 強連結成分分解
SCCInfo scc(T)(T g) {
    import std.range;
    import std.algorithm : each, map, min, reverse;
    import std.conv : to;
    auto n = g.length;
    auto sccInfo = SCCInfo(n);
    with (sccInfo) {
        bool[] inS = new bool[n];
        int[] low = new int[n], ord = new int[n]; ord[] = -1;
        int time = 0;
        Deque!int st;
        int bufC = 0;
        StackPayload!int buf; buf.reserve(n);
        StackPayload!(int[]) gBuf;
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
            if (ord[i] == -1) dfs(i.to!int);
        }
        groups = gBuf.data;
        reverse(groups);
        groups.each!((i, v) => v.each!(x => id[x] = i.to!int));
    }
    return sccInfo;
}

///
unittest {
    import std.algorithm, std.typecons;
    alias E = Tuple!(int, "to");
    E[][] g = new E[][5];
    g[0] ~= E(1);
    g[1] ~= E(2);
    g[2] ~= E(0); g[2] ~= E(3);
    g[3] ~= E(4);
    g[4] ~= E(3);

    auto info = scc(g);

    assert(info.id[0] == info.id[1] && info.id[1] == info.id[2]);
    assert(info.id[3] == info.id[4]);
    assert(info.id[0] < info.id[3]); //idはトポロジカル順
    assert(equal(info.group(0).dup.sort!"a<b", [0, 1, 2]));
    assert(equal(info.group(3).dup.sort!"a<b", [3, 4]));
}

unittest {
    import std.algorithm, std.conv, std.stdio, std.range;
    import std.random;
    import std.typecons;

    struct E {int to;}

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
    import dkh.stopwatch;
    auto ti = benchmark!(f)(1000);
    writeln("SCC Random1000: ", ti[0].toMsecs);
}
