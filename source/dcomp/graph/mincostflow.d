module dcomp.graph.mincostflow;

import dcomp.container.deque;

import std.stdio;

struct MinCostFlowInfo(C, D, T) {
    T g; int s, t;
    C nc, capFlow;
    D nd, flow;
    D[] dual; //potential
    int[] pv, pe; //path
    this(T g, int s, int t) {
        this.g = g;
        this.s = s;
        this.t = t;
        dual = new D[g.length];
        pv = new int[g.length];
        pe = new int[g.length];
    }
}

/// 最小費用流
MinCostFlowInfo!(C, D, T) minCostFlow(C, D, T)(T g, int s, int t, bool neg) {
    assert(s != t);
    import std.algorithm : map;
    import std.range : array;
    import std.conv : to;
    auto mcfInfo = MinCostFlowInfo!(C, D, T)(g, s, t);
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
    addEdge(g, 0, 2, 15, 3);
    addEdge(g, 1, 3, 3, 2);
    addEdge(g, 2, 3, 20, 4);
    
    auto mcfInfo = minCostFlow!(int, int)(g, 0, 3, false);
    mcfInfo.manyFlow(10^^9);
    assert(mcfInfo.capFlow == 18);
    assert(mcfInfo.flow == 3*(3+2) + 15*(3+4));
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


    writeln("MinCostFlow Random5000");

    void f() {
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

        foreach (i; 1..m) {
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

        auto res = minCostFlow!(int, int)(g, s, t, false);
        res.manyFlow(10^^9);
        int sm = (res.dual[t]-res.dual[s]) * res.capFlow;
        foreach (i, v; elist) {
            foreach (e; v) {
                sm -= max(0, (res.dual[e.to] - res.dual[i]) - e.dist) * e.cap;
            }
        }
        assert(res.flow == sm);
    }
    auto ti = benchmark!(f)(5000);
    writeln(ti[0].msecs, "ms");
}

C singleFlow(C, D, T)(ref MinCostFlowInfo!(C, D, T) mcfInfo, C c) {
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

void manyFlow(C, D, T)(ref MinCostFlowInfo!(C, D, T) mcfInfo, C c) {
    with (mcfInfo) {
        while (c) {
            C f = singleFlow(mcfInfo, c);
            if (!f) break;
            c -= f;
        }
    }
}

import dcomp.container.deque;

void dualRef(bool neg, C, D, T)(ref MinCostFlowInfo!(C, D, T) mcfInfo) {
    import std.conv : to;
    import std.typecons;
    import std.container;
    import std.algorithm;
    alias P = Tuple!(int, "to", D, "dist");
    immutable string INIT = !neg
        ? `heapify!"a.dist>b.dist"(Array!P())`
        : "Deque!P()";
    

    with(mcfInfo) {
        int n = g.length.to!int;
        D[] dist = new D[n]; dist[] = D.max;
        pv[] = -1; pe[] = -1;
        Deque!int refV;
        auto que = mixin(INIT);

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
                que.popFront();
            } else {
                p = que.back();
                que.removeBack();
            }
            return p;
        }
        insert(P(s, 0));
        dist[s] = 0;
        while (!que.empty) {
            P p = pop();
            int v = p.to;
            if (dist[v] < p.dist) continue;
            if (!neg) {
                if (v == t) break;
                refV.insertBack(v);
            }
            foreach (int i, e; g[v]) {
                D ed = e.dist + dual[v] - dual[e.to];
                if (e.cap && dist[e.to] > dist[v] + ed) {
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
            while (!refV.empty()) {
                int v = refV.back(); refV.removeBack();
                if (dist[v] >= dist[t]) continue;
                dual[v] += dist[v]-dist[t];
            }
        } else {
            for (int v = 0; v < n; v++) {
                dual[v] += dist[v];
            }
        }
        
        nd = dual[t]-dual[s];
        nc = C.max;
        for (int v = t; v != s; v = pv[v]) {
            nc = min(nc, g[pv[v]][pe[v]].cap);
        }
    }
}

void dualRef(C, D, T)(ref MinCostFlowInfo!(C, D, T) mcfInfo, bool neg) {
    if (neg == false) {
        dualRef!false(mcfInfo);
    } else {
        dualRef!true(mcfInfo);
    }
}
