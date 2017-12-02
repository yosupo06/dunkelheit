module dcomp.graph.maxflow;

import dcomp.container.deque;

///maxflowの情報
struct MaxFlowInfo(C) {
    C flow; ///流量
    bool[] dual; ///最小カット(S側:false, T側:true)
}

///最大流ライブラリ, Dinic
MaxFlowInfo!(C) maxFlow(C, C EPS, T)(T g, int s, int t, C gap = C.max) {
    assert(s != t);
    import std.algorithm : map;
    import std.range : array;
    import std.conv : to;
    int n = g.length.to!int;
    int[] level = new int[n];
    int[] iter = new int[n];

    void bfs() {
        level[] = -1; level[s] = 0;
        auto que = Deque!int();
        que.insertBack(s);
        while (!que.empty) {
            int v = que.front; que.removeFront;
            foreach (e; g[v]) {
                if (e.cap <= EPS) continue;
                if (level[e.to] < 0) {
                    level[e.to] = level[v] + 1;
                    que.insertBack(e.to);
                }
            }
        }
    }

    C dfs(int v, C f) {
        import std.algorithm : min;
        if (v == t) return f;
        C res = 0;
        auto edgeList = g[v][iter[v]..$];
        foreach (ref e; edgeList) {
            if (e.cap <= EPS) continue;
            if (level[v] >= level[e.to]) continue;            
            C d = dfs(e.to, min(f, e.cap));
            e.cap -= d;
            g[e.to][e.rev].cap += d;
            res += d;
            f -= d;
            if (f == 0) break;
            iter[v]++;
        }
        return res;
    }

    C flow = 0;
    while (gap - flow > EPS) {
        bfs();
        if (level[t] < 0) break;
        iter[] = 0;
        while (true) {
            C f = dfs(s, gap - flow);
            if (!f) break;
            flow += f;
        }
    }

    auto mfInfo = MaxFlowInfo!C();
    mfInfo.flow = flow;
    mfInfo.dual = level.map!"a == -1".array;
    return mfInfo;
}



///最大流ライブラリ, Dinic
MaxFlowInfo!(C) maxFlowSlow(C, T)(T g, int s, int t, C gap = C.max) {
    assert(s != t);
    import std.algorithm : map;
    import std.range : array;
    import std.conv : to;
    int n = g.length.to!int;

    bool[] used = new bool[n];
    bool dfs(int v) {
        if (v == t) return true;
        import std.stdio;
        used[v] = true;
        foreach (ref e; g[v]) {
            if (used[e.to]) continue;
            if (!e.cap) continue;
            if (dfs(e.to)) {
                e.cap -= 1;
                g[e.to][e.rev].cap += 1;
                return true;
            }
        }
        return false;
    }
    
    C flow = 0;
    while (flow < gap) {
        used[] = false;
        if (!dfs(s)) break;
        flow++;
    }
    auto mfInfo = MaxFlowInfo!C();
    mfInfo.flow = flow;
    mfInfo.dual = used.map!"!a".array;
    return mfInfo;
}


///
unittest {
    import std.algorithm : equal;
    import std.conv : to;
    struct Edge {
        int to, cap, rev;
    }
    void addEdge(Edge[][] g, int from, int to, int cap) {
        g[from] ~= Edge(to, cap, g[to].length.to!int);
        g[to] ~= Edge(from, 0, g[from].length.to!int-1);
    }

    auto g = new Edge[][](4);

    addEdge(g, 0, 1, 3);
    addEdge(g, 0, 2, 3);
    addEdge(g, 1, 3, 2);
    addEdge(g, 2, 3, 4);
    auto res = maxFlow!(int, 0)(g, 0, 3);
    assert(res.flow == 5);
    //MinCut : S={0, 1}, T={2, 3}
    assert(equal(res.dual, [false, false, true, true]));
}


unittest {
    import std.algorithm, std.conv, std.stdio, std.range;
    import std.random;
    import std.typecons;
    import std.datetime;

    struct E {
        int to, cap, rev;
    }
    void addEdge(E[][] g, int from, int to, int cap) {
        g[from] ~= E(to, cap, g[to].length.to!int);
        g[to] ~= E(from, 0, g[from].length.to!int-1);
    }


    writeln("MaxFlow Random5000");

    void f(alias MF)() {
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
            addEdge(g, x, y, c);
            elist[x] ~= E(y, c, -1);
        }

        auto res = MF(g, s, t);
        assert(res.dual[s] == false);
        assert(res.dual[t] == true);
        int sm = 0;
        foreach (i, v; elist) {
            foreach (e; v) {
                if (res.dual[i] == false && res.dual[e.to] == true) {
                    sm += e.cap;
                }
            }
        }
        assert(res.flow == sm);
    }
    auto ti = benchmark!(
        f!(maxFlow!(int, 0, E[][])),
        f!(maxFlowSlow!(int, E[][])),
        )(5000);
    writeln(ti[0].msecs, "ms");
}

unittest {
    import std.algorithm, std.conv, std.stdio, std.range, std.math;
    import std.random;
    import std.typecons;
    import std.datetime;

    struct E {
        int to;
        double cap;
        int rev;
    }
    void addEdge(E[][] g, int from, int to, double cap) {
        g[from] ~= E(to, cap, g[to].length.to!int);
        g[to] ~= E(from, 0.0, g[from].length.to!int-1);
    }
    immutable double EPS = 1e-9;

    writeln("MaxFlow Double Random5000");

    void f() {
        int n = uniform(2, 20);
        int m = uniform(0, 200);
        int s = 0, t = 1;
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
            double c = uniform(0.0, 100.0);
            addEdge(g, x, y, c);
            elist[x] ~= E(y, c, -1);
        }

        auto res = maxFlow!(double, EPS)(g, 0, 1);
        assert(res.dual[0] == false);
        assert(res.dual[1] == true);
        double sm = 0;
        foreach (i, v; elist) {
            foreach (e; v) {
                if (res.dual[i] == false && res.dual[e.to] == true) {
                    sm += e.cap;
                }
            }
        }
        assert(abs(res.flow - sm) < EPS);
    }
    auto ti = benchmark!(f)(5000);
    writeln(ti[0].msecs, "ms");
}
