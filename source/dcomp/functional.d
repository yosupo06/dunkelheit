module dcomp.functional;

struct memoCont(alias pred) {
    import std.range, std.algorithm, std.conv;
    import std.string : join;
    import std.traits : ReturnType, ParameterTypeTuple, isIntegral;
    import std.typecons : tuple, Tuple;
    import std.meta;
    alias R = ReturnType!pred;
    alias Args = ParameterTypeTuple!pred;
    static assert (allSatisfy!(isIntegral, Args)); // should be int only?

    static immutable N = Args.length;
    static string toTuple(string s) { //int[N] -> (N[0], N[1], N[2], ...)
        return "(" ~ iota(N).map!(i => s~"["~i.to!string~"]").join(",") ~ ")";
    }
    static string toArray(string s) { //int[N] -> [N[0]][N[1]][N[2]]...
        return iota(N).map!(i => "["~s~"["~i.to!string~"]]").join("");
    }
    template NArray(T, int N) {
        static if (!N) alias NArray = T;
        else alias NArray = NArray!(T, N-1)[];
    }
    int[2][N] rng;
    NArray!(R, N) dp;
    NArray!(bool, N) used;
    void init(int[2][N] rng) {
        this.rng = rng;
        int[N] len = rng[].map!(a => a[1]-a[0]+1).array;
        
        //dp = new typeof(dp)(len[0], len[1], ..., len[N-1])
        //used = new typeof(used)(len[0], len[1], ..., len[N-1])
        dp = mixin("new typeof(dp)"~toTuple("len"));
        used = mixin("new typeof(used)"~toTuple("len"));
    }
    R opCall(Args args) {
        int[N] idx;
        foreach (i, v; args) {
            assert(rng[i][0] <= v && v <= rng[i][1]);
            idx[i] = v - rng[i][0];
        }
        //if (used[idx[0]]..[idx[N-1]]) dp[idx[0]]..[idx[N-1]]
        //used[idx[0]]..[idx[N-1]] = true
        if (mixin("used"~toArray("idx"))) return mixin("dp"~toArray("idx"));
        mixin("used"~toArray("idx")) = true;

        auto r = pred(args);

        //dp[idx[0]]..[idx[N-1]] = r
        mixin("dp"~toArray("idx")) = r;

        return r;
    }
}
