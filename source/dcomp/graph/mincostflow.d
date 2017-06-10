module dcomp.graph.mincostflow;

import dcomp.container.deque;

import std.stdio;

struct minCostFlowInfo(C, D, T) {
    T g; int s, t;
    D INF, EPS;
    C capFlow;
    D flow;
    D[] dual; //potential
    C nc; D nd;
    int[] pv, pe; //path
    this(T g, int s, int t, D EPS, D INF) {
        this.g = g;
        this.s = s;
        this.t = t;
        this.INF = INF;
        this.EPS = EPS;
        dual = new D[g.length];
        pv = new int[g.length];
        pe = new int[g.length];
    }
}

/// 最小費用流
minCostFlowInfo!(C, D, T) minCostFlow(C, D, T)(T g, int s, int t, D EPS, D INF, bool neg) {
    assert(s != t);
    import std.algorithm : map;
    import std.range : array;
    import std.conv : to;
    int n = g.length.to!int;
    auto mcfInfo =
        minCostFlowInfo!(C, D, T)(g, s, t, EPS, INF);
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

    auto mcfInfo = minCostFlow!(int, int)(g, 0, 3, 0, 10^^9, false);
    mcfInfo.manyFlow(10^^9);
    assert(mcfInfo.capFlow == 18);
    assert(mcfInfo.flow == 3*(3+2) + 15*(3+4));
}

C singleFlow(C, D, T)(ref minCostFlowInfo!(C, D, T) mcfInfo, C c) {
    import std.algorithm;
    with (mcfInfo) {
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

void manyFlow(C, D, T)(ref minCostFlowInfo!(C, D, T) mcfInfo, C c) {
    with (mcfInfo) {
        D res = 0;
        while (c) {
            D d = nd;
            C f = singleFlow(mcfInfo, c);
            if (!f) break;
            res += D(f) * d;
            c -= f;
        }
    }
}

import dcomp.container.deque;

void dualRef(bool neg, C, D, T)(ref minCostFlowInfo!(C, D, T) mcfInfo) {
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
        D[] dist = new D[n]; dist[] = INF;
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

        if (dist[t] == INF) {
            nd = INF;
            nc = 0;
            return;
        }
        nd = dual[t]-dual[s];
        nc = INF;
        for (int v = t; v != s; v = pv[v]) {
            nc = min(nc, g[pv[v]][pe[v]].cap);
        }
    }
}

void dualRef(C, D, T)(ref minCostFlowInfo!(C, D, T) mcfInfo, bool neg) {
    if (neg == false) {
        dualRef!false(mcfInfo);
    } else {
        dualRef!true(mcfInfo);
    }
}

