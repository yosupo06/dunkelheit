module dcomp.functional;

struct memoCont(alias pred) {
    import std.range, std.algorithm, std.conv;
    import std.string : join;
    import std.traits : ReturnType, ParameterTypeTuple, isIntegral;
    import std.typecons : tuple, Tuple;
    import std.meta;
    alias R = ReturnType!pred;
    alias Args = ParameterTypeTuple!pred;
    static assert (allSatisfy!(isIntegral, Args));
    static immutable N = Args.length;
    int[2][N] rng;
    int[N] len;
    R[] dp;
    bool[] used;
    void init(int[2][N] rng) {
        this.rng = rng;
        len = rng[].map!(a => a[1]-a[0]+1).array;
        int sz = len.reduce!"a*b";
        dp = new R[sz];
        used = new bool[sz];
    }
    R opCall(Args args) {
        int idx, base = 1;
        foreach (i, v; args) {
            assert(rng[i][0] <= v && v <= rng[i][1]);
            idx += base*(v - rng[i][0]);
            base *= len[i];
        }
        if (used[idx]) return dp[idx];
        used[idx] = true;
        auto r = pred(args);
        dp[idx] = r;
        return r;
    }
}

unittest {
    import dcomp.numeric.primitive;
    import dcomp.numeric.modint;
    alias Mint = ModInt!(10^^9+7);
    auto fact = factTable!Mint(100);
    auto iFac = invFactTable!Mint(100);
    Mint C0(int a, int b) {
        if (a < 0 || a < b) return Mint(0);
        return fact[a]*iFac[b]*iFac[a-b];
    }
    struct A {
        static memoCont!C1base C1;
        static Mint C1base(int a, int b) {
            if (a == 0) {
                if (b == 0) return Mint(1);
                return Mint(0);
            }
            if (b < 0) return Mint(0);
            return C1(a-1, b-1) + C1(a-1, b);
        }
    }
    A.C1.init([[0, 100], [-2, 100]]);
    foreach (i; 0..100) {
        foreach (j; 0..100) {
            assert(C0(i, j) == A.C1(i, j));
        }
    }
}
