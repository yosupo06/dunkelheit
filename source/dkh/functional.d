module dkh.functional;

/**
メモ化ライブラリ

std.functional.memoizeとは違い, 引数が連続している必要がある.
ハッシュテーブルではなく配列で値を保存するため高速である.
 */
struct memoCont(alias pred) {
    import std.traits : ReturnType, ParameterTypeTuple, isIntegral;
    import std.meta : allSatisfy;
    alias R = ReturnType!pred;
    alias Args = ParameterTypeTuple!pred;
    static assert (allSatisfy!(isIntegral, Args));
    static immutable N = Args.length;
    
    private int[2][N] rng;
    int[N] len;
    R[] dp;
    bool[] used;
    void init(in int[2][N] rng) {
        import std.algorithm : reduce, map;
        import std.range : array;
        this.rng = rng;
        len = rng[].map!(a => a[1]-a[0]+1).array;
        auto sz = reduce!"a*b"(1, len);
        dp = new R[sz];
        used = new bool[sz];
    }
    R opCall(Args args) {
        import core.exception : RangeError;
        size_t idx, base = 1;
        foreach (i, v; args) {
            version(assert) {
                if (v < rng[i][0] || rng[i][1] < v) {
                    throw new RangeError;
                }
            }
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

///
unittest {
    import dkh.numeric.primitive;
    import dkh.modint;
    alias Mint = ModInt!(10^^9+7);

    struct A {
        static auto fact = factTable!Mint(100);
        static auto iFac = invFactTable!Mint(100);
        static Mint C1(int n, int k) {
            return fact[n] * iFac[k] * iFac[n-k];
        }

        // メモ化再帰でnCkの計算をする
        static memoCont!C2base C2;
        static Mint C2base(int n, int k) {
            if (k == 0) return Mint(1);
            if (n == 0) return Mint(0);
            return C2(n-1, k-1) + C2(n-1, k);
        }
    }
    
    // 0 <= n <= 99, 0 <= k <= 99, 閉区間
    A.C2.init([[0, 99], [0, 99]]);
    foreach (i; 0..100) {
        foreach (j; 0..i+1) {
            assert(A.C1(i, j) == A.C2(i, j));
        }
    }
}
