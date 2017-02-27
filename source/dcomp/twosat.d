module dcomp.twosat;

import dcomp.graph.scc;

struct TwoSat {
    bool[] res;

    struct Edge {int to;}
    Edge[][] g;

    // add ((a == aExp) || (b == bExp))
    void addCond(int a, bool aExp, int b, bool bExp) {
        void addEdge(int l, int r) {
            g[l] ~= Edge(r);
        }
        addEdge(2*a+(aExp?0:1), 2*b+(bExp?1:0));
        addEdge(2*b+(bExp?0:1), 2*a+(aExp?1:0));
    }
    bool exec() {
        import std.conv : to;
        int n = res.length.to!int;
        auto sccInfo = scc(g);
        for (int i = 0; i < n; i++) {
            if (sccInfo.id[2*i] == sccInfo.id[2*i+1]) return false;
            res[i] = sccInfo.id[2*i] < sccInfo.id[2*i+1];
        }
        return true;
    }
    this(int n) {
        res = new bool[n];
        g = new Edge[][](2*n);
    }
}

unittest {
    import std.algorithm, std.conv, std.stdio, std.range;
    import std.random;
    import std.typecons;
    import std.datetime;

    struct E {int to;}

    writeln("TwoSat Random10000");
    void f() {
        int n = uniform(1, 50);
        int m = uniform(1, 100);
        auto ans = new bool[n];
        auto sat = TwoSat(n);
        ans.each!((ref x) => x = uniform(0, 2) == 1);
        struct N {int i; bool expect;}
        N[2][] conds;
        foreach (i; 0..m) {
            int x = uniform(0, n);
            int y = uniform(0, n);
            while (true) {
                bool f = uniform(0, 2) == 1;
                bool g = uniform(0, 2) == 1;
                if (ans[x] != f && ans[y] != g) continue;
                sat.addCond(x, f, y, g);
                conds ~= [N(x, f), N(y, g)];
                break;
            }
        }
        assert(sat.exec());
        auto res = sat.res;
        foreach (cond; conds) {
            int x = cond[0].i;
            bool f = cond[0].expect;
            int y = cond[1].i;
            bool g = cond[1].expect;
            assert(res[x] == f || res[y] == g);
        }
    }
    auto ti = benchmark!(f)(10000);
    writeln(ti[0].msecs, "ms");
}
