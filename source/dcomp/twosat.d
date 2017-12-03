/**
2-SAT を解くライブラリ
 */
module dcomp.twosat;

import dcomp.graph.scc;
import dcomp.container.stackpayload;

/// 2-SAT を解く構造体
struct TwoSat {
    /// execをした後, 解けたならば答えが入る
    bool[] res;

    struct Edge {int to;}
    StackPayload!Edge[] g;

    /// $(D (a == aExp) || (b == bExp)) という条件を追加
    void addCond(int a, bool aExp, int b, bool bExp) {
        g[2*a+(aExp?0:1)] ~= Edge(2*b+(bExp?1:0));
        g[2*b+(bExp?0:1)] ~= Edge(2*a+(aExp?1:0));
    }

    /// 解けたかをreturnする, 実際の答えはresに入る
    bool exec() {
        import std.array : array;
        import std.algorithm : map;
        import std.conv : to;
        int n = res.length.to!int;
        auto sccInfo = scc(g.map!(v => v.data).array);
        for (int i = 0; i < n; i++) {
            if (sccInfo.id[2*i] == sccInfo.id[2*i+1]) return false;
            res[i] = sccInfo.id[2*i] < sccInfo.id[2*i+1];
        }
        return true;
    }
    /// n:変数の数
    this(int n) {
        res = new bool[n];
        g = new StackPayload!Edge[](2*n);
    }
}

///
unittest {
    /+
    (x0 v x1) ^ (~x0 v x2) ^ (~x1 v ~x2) を解く
    +/
    auto sat = TwoSat(3);
    sat.addCond(0, true,  1, true);  //(x0 == true  || x1 == true)
    sat.addCond(0, false, 2, true);  //(x0 == false || x2 == true)
    sat.addCond(1, false, 2, false); //(x1 == false || x2 == false)
    assert(sat.exec() == true);
    auto res = sat.res;
    assert(res[0] == true  || res[1] == true);
    assert(res[0] == false || res[2] == true);
    assert(res[1] == false || res[2] == false);
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

    import dcomp.stopwatch;
    auto ti = benchmark!(f)(1000);
    writeln("TwoSat Random1000: ", ti[0].toMsecs);
}
