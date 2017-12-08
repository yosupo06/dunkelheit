/**
2-SAT を解くライブラリ
 */
module dcomp.twosat;

import dcomp.graph.scc;
import dcomp.container.stackpayload;

/// 2-SAT を解く構造体
struct TwoSat {
    bool[] vars; /// assigned variable

    static struct Edge {uint to;}
    private StackPayload!Edge[] g;

    /// Clause $(D (vars[a] == aExpect) || (vars[b] == bExpect))
    void addClause(size_t a, bool expectedA, size_t b, bool expectedB) {
        import std.conv : to;
        g[2*a+(expectedA?0:1)] ~= Edge((2*b+(expectedB?1:0)).to!uint);
        g[2*b+(expectedB?0:1)] ~= Edge((2*a+(expectedA?1:0)).to!uint);
    }

    /**
    Solve 2-sat

    Returns:
        satisfiable or not
     */
    bool solve() {
        import std.array : array;
        import std.algorithm : map;
        auto sccInfo = scc(g.map!(v => v.data).array);
        foreach (i; 0..vars.length) {
            if (sccInfo.id[2*i] == sccInfo.id[2*i+1]) return false;
            vars[i] = sccInfo.id[2*i] < sccInfo.id[2*i+1];
        }
        return true;
    }

    /**
    Params:
        n = # of variables
     */
    this(size_t n) {
        vars = new bool[n];
        g = new StackPayload!Edge[](2*n);
    }
}

///
unittest {
    // Solve (x0 v x1) ^ (~x0 v x2) ^ (~x1 v ~x2)
    auto sat = TwoSat(3);
    sat.addClause(0, true,  1, true);  // (vars[0] == true  || vars[1] == true)
    sat.addClause(0, false, 2, true);  // (vars[0] == false || vars[2] == true)
    sat.addClause(1, false, 2, false); // (vars[1] == false || vars[2] == false)
    assert(sat.solve() == true);
    auto vars = sat.vars;
    assert(vars[0] == true  || vars[1] == true);
    assert(vars[0] == false || vars[2] == true);
    assert(vars[1] == false || vars[2] == false);
}

unittest {
    import std.algorithm, std.conv, std.stdio, std.range;
    import std.random;
    import std.typecons;

    struct E {int to;}

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
                sat.addClause(x, f, y, g);
                conds ~= [N(x, f), N(y, g)];
                break;
            }
        }
        assert(sat.solve());
        auto vars = sat.vars;
        foreach (cond; conds) {
            int x = cond[0].i;
            bool f = cond[0].expect;
            int y = cond[1].i;
            bool g = cond[1].expect;
            assert(vars[x] == f || vars[y] == g);
        }
    }

    import dcomp.stopwatch;
    auto ti = benchmark!(f)(1000);
    writeln("TwoSat Random1000: ", ti[0].toMsecs);
}
