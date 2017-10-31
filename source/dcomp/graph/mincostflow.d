module dcomp.graph.mincostflow;

import dcomp.container.deque;

/// 最小費用流の乗法
struct MinCostFlowInfo(C, D, D EPS, T) {
    T g;
    int s, t;
    C nc, capFlow; ///今の最短路の容量, 今流した量
    D nd, flow; ///今の最短路の長さ, 今流したコスト
    D[] dual; /// 双対問題の答え(=ポテンシャル)
    int[] pv, pe;
    this(T g, int s, int t) {
        this.g = g;
        this.s = s;
        this.t = t;
        flow = D(0);
        dual = new D[g.length]; dual[] = D(0);
        pv = new int[g.length];
        pe = new int[g.length];
    }
}

/// 最小費用流
MinCostFlowInfo!(C, D, EPS, T) minCostFlow(C, D, D EPS, T)(T g, int s, int t, bool neg) {
    assert(s != t);
    import std.algorithm : map;
    import std.range : array;
    import std.conv : to;
    auto mcfInfo = MinCostFlowInfo!(C, D, EPS, T)(g, s, t);
    mcfInfo.dualRef(neg);
    return mcfInfo;
}

///
unittest {
    import std.conv : to;
    struct Edge {
        int to, cap, dist, rev;
    }

    void addEdge(Edge[][] g, int from, int to, int cap, int dist) {
        g[from] ~= Edge(to, cap, dist, g[to].length.to!int);
        g[to] ~= Edge(from, 0, -dist, g[from].length.to!int-1);
    }

    auto g = new Edge[][](4);

    addEdge(g, 0, 1, 10, 3);
    addEdge(g, 0, 2, 12, 3);
    addEdge(g, 1, 3, 3, 2);
    addEdge(g, 2, 3, 20, 4);
    
    auto mcfInfo = minCostFlow!(int, int, 0)(g, 0, 3, false);
    //最初は 0->1->3で容量3, 距離5を流せる
    assert(mcfInfo.nc == 3 && mcfInfo.nd == 5);

    //最短経路が変わらない間(=容量3)流す
    mcfInfo.singleFlow(10^^9);

    assert(mcfInfo.capFlow == 3 && mcfInfo.flow == 15);

    //次は 0->2->3で容量12, 距離7を流せる
    assert(mcfInfo.nc == 12 && mcfInfo.nd == 7);
    
    //最短経路が変わらない間(=容量12)流す
    mcfInfo.singleFlow(10^^9);

    assert(mcfInfo.capFlow == 3 + 12);
    assert(mcfInfo.flow == 15 + 12*7);
}

///min(nc, c)流す
C singleFlow(C, D, alias EPS, T)(ref MinCostFlowInfo!(C, D, EPS, T) mcfInfo, C c) {
    import std.algorithm;
    with (mcfInfo) {
        if (nd == D.max) return nc;
        c = min(c, nc);
        for (int v = t; v != s; v = pv[v]) {
            g[pv[v]][pe[v]].cap -= c;
            g[v][g[pv[v]][pe[v]].rev].cap += c;
        }        
        capFlow += c;
        flow += c * nd;
        nc -= c;
        if (!nc) dualRef(mcfInfo, false);
    }
    return c;
}

///流量がcになるまで流せるだけ流し続ける
void manyFlow(C, D, alias EPS, T)(ref MinCostFlowInfo!(C, D, EPS, T) mcfInfo, C c) {
    with (mcfInfo) {
        while (c) {
            C f = singleFlow(mcfInfo, c);
            if (!f) break;
            c -= f;
        }
    }
}

import dcomp.array;
import dcomp.container.radixheap;

void dualRef(bool neg, C, D, alias EPS, T)(ref MinCostFlowInfo!(C, D, EPS, T) mcfInfo) {
    import std.conv : to;
    import std.traits : isIntegral;
    import std.typecons;
    import std.container;
    import std.algorithm;
    alias P = Tuple!(int, "to", D, "dist");

    with(mcfInfo) {
        int n = g.length.to!int;
        D[] dist = new D[n]; dist[] = D.max;
        pv[] = -1; pe[] = -1;
        FastAppender!(int[]) refV;
        auto que = (){
            static if (!neg) {
                static if (isIntegral!D) {
                    return RadixHeap!(P, "a.dist")();
                } else {
                    return heapify!"a.dist>b.dist"(make!(Array!P));
                }
            } else {
                return Deque!P();
            }
        }();
        void insert(P p) {
            static if (!neg) {
                que.insert(p);
            } else {
                que.insertBack(p);
            }
        }
        P pop() {
            P p;
            static if (!neg) {
                p = que.front();
                que.removeFront();
            } else {
                p = que.back();
                que.removeBack();
            }
            return p;
        }
        insert(P(s, D(0)));
        dist[s] = D(0);
        while (!que.empty) {
            P p = pop();
            int v = p.to;
            if (dist[v] < p.dist) continue;
            if (!neg) {
                if (v == t) break;
                refV ~= v;
            }
            foreach (int i, e; g[v]) {
                D ed = e.dist + dual[v] - dual[e.to];
                if (e.cap && dist[e.to] > dist[v] + ed + EPS) {
                    dist[e.to] = dist[v] + ed;
                    pv[e.to] = v; pe[e.to] = i;
                    insert(P(e.to, dist[e.to]));
                }
            }
        }
        if (dist[t] == D.max) {
            nd = D.max;
            nc = 0;
            return;
        }
        static if (!neg) {
            foreach (v; refV.data) {
                if (dist[v] >= dist[t]) continue;
                dual[v] += dist[v]-dist[t];
            }
        } else {
            for (int v = 0; v < n; v++) {
                if (dist[v] == D.max) dual[v] = D.max;
                else dual[v] += dist[v];
            }
        }
        
        nd = dual[t]-dual[s];
        nc = C.max;
        for (int v = t; v != s; v = pv[v]) {
            nc = min(nc, g[pv[v]][pe[v]].cap);
        }
    }
}

void dualRef(C, D, alias EPS, T)(ref MinCostFlowInfo!(C, D, EPS, T) mcfInfo, bool neg) {
    if (neg == false) {
        dualRef!false(mcfInfo);
    } else {
        dualRef!true(mcfInfo);
    }
}

unittest {
    import std.algorithm, std.conv, std.stdio, std.range;
    import std.random;
    import std.typecons;
    import std.datetime;

    struct E {
        int to, cap, dist, rev;
    }
    void addEdge(E[][] g, int from, int to, int cap, int dist) {
        g[from] ~= E(to, cap, dist, g[to].length.to!int);
        g[to] ~= E(from, 0, -dist, g[from].length.to!int-1);
    }



    void f(bool neg)() {
        int n = uniform(2, 20);
        int m = uniform(0, 200);
        int s, t;
        while (true) {
            s = uniform(0, n);
            t = uniform(0, n);
            if (s != t) break;
        }
        auto g = new E[][n];
        E[][] elist = new E[][n];

        foreach (i; 0..m) {
            int x, y;
            while (true) {
                x = uniform(0, n);
                y = uniform(0, n);
                if (x == y) continue;
                break;
            }
            int c = uniform(0, 100);
            int d = uniform(0, 100);
            addEdge(g, x, y, c, d);
            elist[x] ~= E(y, c, d, -1);
        }

        auto res = minCostFlow!(int, int, 0)(g, s, t, neg);
        res.manyFlow(10^^9);
        int sm = (res.dual[t]-res.dual[s]) * res.capFlow;
        foreach (i, v; elist) {
            foreach (e; v) {
                sm -= (max(0L, (long(res.dual[e.to]) - res.dual[i]) - e.dist) * e.cap).to!long;
            }
        }
        assert(res.flow == sm);
    }
    writeln("MinCostFlow Random5000, Neg5000");
    auto ti = benchmark!(f!false, f!true)(5000);
    writeln(ti[0].msecs, "ms");
    writeln(ti[1].msecs, "ms");
}

unittest {
    import std.algorithm, std.conv, std.stdio, std.range;
    import std.random;
    import std.typecons;
    import std.datetime;

    struct E {
        int to, cap;
        double dist;
        int rev;
    }
    void addEdge(E[][] g, int from, int to, int cap, double dist) {
        g[from] ~= E(to, cap, dist, g[to].length.to!int);
        g[to] ~= E(from, 0, -dist, g[from].length.to!int-1);
    }



    void f(bool neg)() {
        int n = uniform(2, 20);
        int m = uniform(0, 200);
        int s, t;
        while (true) {
            s = uniform(0, n);
            t = uniform(0, n);
            if (s != t) break;
        }
        auto g = new E[][n];
        E[][] elist = new E[][n];

        foreach (i; 0..m) {
            int x, y;
            while (true) {
                x = uniform(0, n);
                y = uniform(0, n);
                if (x == y) continue;
                break;
            }
            int c = uniform(0, 100);
            double d = uniform(0.0, 100.0);
            addEdge(g, x, y, c, d);
            elist[x] ~= E(y, c, d, -1);
        }

        auto res = minCostFlow!(int, double, 1e-9)(g, s, t, neg);
        res.manyFlow(10^^9);
        double sm = (res.dual[t]-res.dual[s]) * res.capFlow;
        foreach (i, v; elist) {
            foreach (e; v) {
                sm -= max(0.0, (res.dual[e.to] - res.dual[i]) - e.dist) * e.cap;
            }
        }
        import std.math;
        assert(abs(res.flow - sm) <= 1e-3);
    }
    writeln("MinCostFlow double Random5000, Neg5000");
    auto ti = benchmark!(f!false, f!true)(5000);
    writeln(ti[0].msecs, "ms");
    writeln(ti[1].msecs, "ms");
}
