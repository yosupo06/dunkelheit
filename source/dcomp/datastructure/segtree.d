module dcomp.datastructure.segtree;

import std.traits;

struct SegTree(alias E, Args...) {
    import std.conv : to;
    import std.traits : ReturnType;
    alias Engine = E!Args;
    alias T = Engine.DataType;
    alias L = Engine.LazyType;
    Engine eng;
    this(uint n) {
        eng = Engine(n);
    }
    this(T[] first) {
        eng = Engine(first);
    }
    @property size_t length() const { return eng.length(); }
    @property size_t opDollar() const { return eng.length(); }
    struct Range {
        Engine* eng;
        size_t start, end;
        @property T sum() {
            return eng.sum(start.to!uint, end.to!uint);
        }
    }
    const(T) opIndex(size_t k) {
        assert(0 <= k && k < eng.length());
        return eng.single(k.to!uint);
    }
    void opIndexAssign(T x, size_t k) {
        assert(0 <= k && k < eng.length());
        eng.singleSet(k.to!uint, x);
    }
    size_t[2] opSlice(size_t dim)(size_t start, size_t end) {
        assert(0 <= start && start <= end && end <= eng.length());
        return [start, end];
    }
    Range opIndex(size_t[2] rng) {
        return Range(&eng, rng[0].to!uint, rng[1].to!uint);
    }
    static if (!is(L == void)) {
        void opIndexOpAssign(string op : "+")(L x, size_t[2] rng) {
            eng.add(rng[0].to!uint, rng[1].to!uint, x);
        }
    }
}

/**
遅延伝搬SegTree

T型の配列aに対して、a[l..r] += x(xはL型)、opTT(a[l..r])が高速に計算できる

Params:
    opTT = (T, T)の演算(結果をまとめる)
    opTL = (T, L)の演算(クエリを適用する)
    opLL = (L, L)の演算(クエリをまとめる)
    eT = Tの単位元
    eL = Lの単位元
*/
template LazySeg(T, L, alias opTT, alias opTL, alias opLL, T eT, L eL, alias Engine = LazySegEngine) {
    import std.functional : binaryFun;
    alias LazySeg = SegTree!(Engine, T, L,
        binaryFun!opTT, binaryFun!opTL, binaryFun!opLL, eT, eL);
}

///
unittest {
    import std.algorithm : max;
    ///区間max, 区間加算
    auto seg = LazySeg!(int, int,
        (a, b) => max(a, b), (a, b) => a+b, (a, b) => a+b, 0, 0)([2, 1, 4]);
    
    //[2, 1, 4]
    seg[0] = 2; seg[1] = 1; seg[2] = 4;
    assert(seg[0..3].sum == 4);

    //[2, 1, 5]
    seg[2] = 5;
    assert(seg[0..2].sum == 2);
    assert(seg[0..3].sum == 5);

    //[12, 11, 5]
    seg[0..2] += 10;
    assert(seg[0..3].sum == 12);
}

/**
SegTree

T型の配列aについて、opTT(a[l..r])が高速に計算できる。
opTTは結合率を満たす2引数関数, eTは単位元。
 */
template SimpleSeg(T, alias opTT, T eT, alias Engine = SimpleSegEngine) {
    import std.functional : binaryFun;
    alias SimpleSeg = SegTree!(Engine, T, binaryFun!opTT, eT);
}

///
unittest {
    import std.algorithm : max;
    ///int型でmax(...)が計算できる、つまりRMQ
    auto seg = SimpleSeg!(int, (a, b) => max(a, b), 0)(3);

    //[2, 1, 4]
    seg[0] = 2; seg[1] = 1; seg[2] = 4;
    assert(seg[0..3].sum == 4); //max(2, 1, 4) == 4

    //[2, 1, 5]
    seg[2] = 5;
    assert(seg[0..2].sum == 2); //max(2, 1) == 2
    assert(seg[0..3].sum == 5); //max(2, 1, 5) == 5

    //[2, 11, 5]
    seg[1] = seg[1] + 10;
    assert(seg[0..3].sum == 11);
}


struct LazySegEngine(T, L, alias opTT, alias opTL, alias opLL, T eT, L eL) {
    import std.typecons : Tuple;
    alias DataType = T;
    alias LazyType = L;
    alias S = Tuple!(T, "d", L, "lz");
    uint n, sz, lg;
    S[] s;
    this(uint n) {
        import std.conv : to;
        import std.algorithm : each;
        this.n = n;
        uint lg = 0;
        while ((2^^lg) < n) lg++;
        this.lg = lg;
        sz = 2^^lg;
        s = new S[](2*sz);
        s.each!((ref x) => x = S(eT, eL));
    }
    this(T[] first) {
        import std.conv : to;
        import std.algorithm : each;
        n = first.length.to!uint;
        uint lg = 0;
        while ((2^^lg) < n) lg++;
        this.lg = lg;
        sz = 2^^lg;

        s = new S[](2*sz);
        s.each!((ref x) => x = S(eT, eL));
        foreach (i; 0..n) {
            s[sz+i].d = first[i];
        }
        foreach_reverse (i; 1..sz) {
            update(i);
        }
    }
    @property size_t length() const { return n; }
    pragma(inline):
    private void lzAdd(uint k, in L x) {
        s[k].lz = opLL(s[k].lz, x);
        s[k].d = opTL(s[k].d, x);
    }
    private void push(uint k) {
        if (s[k].lz == eL) return;
        lzAdd(2*k, s[k].lz);
        lzAdd(2*k+1, s[k].lz);
        s[k].lz = eL;
    }
    private void update(uint k) {
        s[k].d = opTT(s[2*k].d, s[2*k+1].d);
    }
    T single(uint k) {
        k += sz;
        foreach_reverse (uint i; 1..lg+1) {
            push(k>>i);
        }
        return s[k].d;
    }
    void singleSet(uint k, T x) {
        k += sz;
        foreach_reverse (uint i; 1..lg+1) {
            push(k>>i);
        }
        s[k].d = x;
        foreach (uint i; 1..lg+1) {
            update(k>>i);
        }
    }
    T sum(uint a, uint b) {
        assert(0 <= a && a <= b && b <= n);
        if (a == b) return eT;
        a += sz; b--; b += sz;
        uint tlg = lg;
        while (true) {
            uint k = a >> tlg;
            if (a >> tlg != b >> tlg) {
                tlg++;
                break;
            }
            if (((a-1) >> tlg) + 2 == (b+1) >> tlg) return s[k].d;
            push(k);
            tlg--;
        }
        T sm = eT;
        foreach_reverse (l; 0..tlg) {
            uint k = a >> l;
            if ((a-1)>>l != a>>l) {
                sm = opTT(s[k].d, sm);
                break;
            }
            push(k);
            if (!((a >> (l-1)) & 1)) sm = opTT(s[2*k+1].d, sm);
        }
        foreach_reverse (l; 0..tlg) {
            uint k = b >> l;
            if (b>>l != (b+1)>>l) {
                sm = opTT(sm, s[k].d);
                break;
            }
            push(k);
            if ((b >> (l-1)) & 1) sm = opTT(sm, s[2*k].d);
        }
        return sm;
    }
    void add(uint a, uint b, L x) {
        assert(0 <= a && a <= b && b <= n);
        if (a == b) return;
        a += sz; b--; b += sz;
        uint tlg = lg;
        while (true) {
            uint k = a >> tlg;
            if (a >> tlg != b >> tlg) {
                tlg++;
                break;
            }
            if (((a-1) >> tlg) + 2 == (b+1) >> tlg) {
                lzAdd(k, x);
                foreach (l; tlg+1..lg+1) {
                    update(a >> l);
                }
                return;
            }
            push(k);
            tlg--;
        }
        foreach_reverse (l; 0..tlg) {
            uint k = a >> l;
            if ((a-1)>>l != a>>l) {
                lzAdd(k, x);
                foreach (h; l+1..tlg) {
                    update(a >> h);
                }
                break;
            }
            push(k);
            if (!((a >> (l-1)) & 1)) lzAdd(2*k+1, x);
        }
        foreach_reverse (l; 0..tlg) {
            uint k = b >> l;
            if (b>>l != (b+1)>>l) {
                lzAdd(k, x);
                foreach (h; l+1..tlg) {
                    update(b >> h);
                }
                break;
            }
            push(k);
            if ((b >> (l-1)) & 1) lzAdd(2*k, x);
        }
        foreach (l; tlg..lg+1) {
            update(a >> l);
        }
    }
}


struct SimpleSegEngine(T, alias opTT, T eT) {
    alias DataType = T;
    alias LazyType = void;
    import std.functional : binaryFun;
    uint n, sz, lg;
    T[] d;
    @property size_t length() const {return n;}
    this(uint n) {
        import std.algorithm : each;
        uint lg = 0;
        while ((2^^lg) < n) lg++;
        this.n = n;
        this.lg = lg;
        sz = 2^^lg;
        d = new T[](2*sz);
        d.each!((ref x) => x = eT);
    }
    this(T[] first) {
        import std.conv : to;
        import std.algorithm : each;
        n = first.length.to!uint;
        if (n == 0) return;
        uint lg = 0;
        while ((2^^lg) < n) lg++;
        this.lg = lg;
        sz = 2^^lg;
        d = new T[](2*sz);
        d.each!((ref x) => x = eT);
        foreach (i; 0..n) {
            d[sz+i] = first[i];
        }
        foreach_reverse (i; 1..sz) {
            update(i);
        }
    }
    pragma(inline):
    private void push(uint k) {}
    void update(uint k) {
        d[k] = opTT(d[2*k], d[2*k+1]);
    }
    T single(uint k) {
        return d[k+sz];
    }
    void singleSet(uint k, T x) {
        k += sz;
        d[k] = x;
        foreach (uint i; 1..lg+1) {
            update(k>>i);
        }
    }
    T sum(uint a, uint b) {
        assert(0 <= a && a <= b && b <= n);
        T sml = eT, smr = eT;
        a += sz; b += sz;
        while (a < b) {
            if (a & 1) sml = opTT(sml, d[a++]);
            if (b & 1) smr = opTT(d[--b], smr);
            a >>= 1; b >>= 1;
        }
        return opTT(sml, smr);
    }
}

unittest {
    //issue 17466
    import std.stdio;
    auto seg = LazySeg!(long[2], long[2],
        (a, b) => a, (a, b) => a, (a, b) => a, [0L, 0L], [0L, 0L])(10);
}


unittest {
    //some func test
    import std.typecons, std.random, std.algorithm;
    import dcomp.datastructure.segex;

    void check(alias Seg)() {
        import std.algorithm : max;
        ///区間max, 区間加算
        alias S = SegTree!(Seg, int, int,
            (a, b) => max(a, b), (a, b) => a+b, (a, b) => a+b, 0, 0); 
        S seg;
        seg = S([2, 1, 4]);
        
        //[2, 1, 4]
        seg[0] = 2; seg[1] = 1; seg[2] = 4;
        assert(seg[0..3].sum == 4);

        //[2, 1, 5]
        seg[2] = 5;
        assert(seg[0..2].sum == 2);
        assert(seg[0..3].sum == 5);

        //[12, 11, 5]
        seg[0..2] += 10;
        assert(seg[0..3].sum == 12);

        //n=10
        auto seg2 = SegTree!(Seg, int, int,
            (a, b) => max(a, b), (a, b) => a+b, (a, b) => a+b, 0, 0)(10);
        assert(seg2.length == 10);
    }
    void checkSimple(alias Seg)() {
        import std.algorithm : max;
        ///区間max, 区間加算
        
        alias S = SegTree!(Seg, int, (a, b) => a+b, 0);
        S seg;
        seg = S(10);
        assert(seg.length == 10);
    }
    check!LazySegEngine();
    check!LazySegBlockEngine();
    check!LazySegNaiveEngine();
    checkSimple!SimpleSegEngine();
    checkSimple!SimpleSegNaiveEngine();
}



unittest {
    //stress test
    import std.typecons, std.random, std.algorithm;
    import dcomp.modint, dcomp.matrix, dcomp.numeric.primitive;
    static immutable uint MD = 10^^9 + 7;
    alias Mint = ModInt!MD;
    alias Mat = SMatrix!(Mint, 2, 2);

    static immutable Mat e = (){
        Mat m;
        m[0, 0] = Mint(1);
        m[1, 1] = Mint(1);
        return m;
    }();

    Xorshift128 gen;

    Mint rndI() {
        return Mint(uniform(0, MD, gen));
    }
    Mat rndM() {
        Mat m;
        while (true) {
            foreach (i; 0..2) {
                foreach (j; 0..2) {
                    m[i, j] = rndI();
                }
            }
            if (m[0, 0] * m[1, 1] == m[0, 1] * m[1, 0]) continue;
            break;
        }
        return m;
    }
    
    Mat check(alias Seg)(int N, int M, uint seed) {
        alias T = Tuple!(Mat, int);
        gen = Xorshift128(seed);
        T[] a = new T[N];
        a.each!((ref x) => x = T(rndM(), 1));
        alias Q = Tuple!(int, int, int, Mat);
        Q[] que = new Q[M];
        foreach (ref q; que) {
            q[0] = uniform(0, 2, gen);
            q[1] = uniform(0, N+1, gen);
            q[2] = uniform(0, N+1, gen);
            if (q[1] > q[2]) swap(q[1], q[2]);
            q[3] = rndM();
        }
        static auto opTT(T a, T b) {
            return T(a[0]*b[0], a[1]+b[1]);
        }
        static auto opTL(T a, Mat b) {
            if (b == Mat()) return a;
            return T(pow(b, a[1], e), a[1]);
        }
        static auto opLL(Mat a, Mat b) {
            return b;
        }

        auto s = SegTree!(Seg, T, Mat, opTT, opTL, opLL, T(e, 0), Mat())(a);
        Mat res;
        foreach (q; que) {
            if (q[0] == 0) {
                //sum
                res += s[q[1]..q[2]].sum()[0];
            } else {
                //set
                s[q[1]..q[2]] += q[3];
            }
        }
        return res;
    }
    Mat checkSimple(alias Seg)(int N, int M, uint seed) {
        alias T = Tuple!(Mat, int);
        gen = Xorshift128(seed);
        Mat[] a = new Mat[N];
        a.each!((ref x) => x = rndM());
        alias Q = Tuple!(int, int, int, Mat);
        Q[] que = new Q[M];
        foreach (ref q; que) {
            q[0] = uniform(0, 2, gen);
            if (N == 0) q[0] = 0;
            if (q[0] == 0) {
                q[1] = uniform(0, N+1, gen);
                q[2] = uniform(0, N+1, gen);
                if (q[1] > q[2]) swap(q[1], q[2]);
            } else {
                q[1] = uniform(0, N, gen);
            }
            q[3] = rndM();
        }
        static auto opTT(Mat a, Mat b) {
            return a*b;
        }

        auto s = SegTree!(Seg, Mat, opTT, e)(a);
        Mat res;
        foreach (q; que) {
            if (q[0] == 0) {
                //sum
                res += s[q[1]..q[2]].sum();
            } else if (q[0] == 1) {
                //set
                s[q[1]] = q[3];
            }
        }
        return res;
    }    
    static struct Naive(T, L, alias opTT, alias opTL, alias opLL, T eT, L eL) {
        import std.conv : to;
        alias DataType = T;
        alias LazyType = L;
        T[] d;
        @property size_t length() const { return d.length; }
        this(uint n) {
            d = new T[n];
        }
        this(T[] first) {
            d = first.dup;
        }
        T sum(uint l, uint r) {
            T sm = eT;
            foreach (i; l..r) {
                sm = opTT(sm, d[i]);
            }
            return sm;
        }
        void add(uint l, uint r, L m) {
            foreach (i; l..r) {
                d[i] = opTL(d[i], m);
            }
        }
        T single(int k) { return d[k]; }
        void singleSet(int k, T x) { d[k] = x; }
    }
    static struct NaiveSimple(T, alias opTT, T eT) {
        import std.conv : to;
        alias DataType = T;
        alias LazyType = void;
        T[] d;
        @property size_t length() const { return d.length; }
        this(uint n) {
            d = new T[n];
        }
        this(T[] first) {
            d = first.dup;
        }
        T sum(uint l, uint r) {
            T sm = eT;
            foreach (i; l..r) {
                sm = opTT(sm, d[i]);
            }
            return sm;
        }
        T single(int k) { return d[k]; }
        void singleSet(int k, T x) { d[k] = x; }
    }    
    int n = 64;
    Mat[] ansLazy = new Mat[n];
    foreach (i; 0..n) {
        ansLazy[i] = check!Naive(i, 1000, 114514);
    }
    Mat[] ansSimple = new Mat[n];
    foreach (i; 0..n) {
        ansSimple[i] = checkSimple!NaiveSimple(i, 1000, 114514);
    }
    
    foreach (i; 0..n) {
        import std.exception;
        assert(check!LazySegEngine(i, 1000, 114514) == ansLazy[i]);
    }

    import dcomp.datastructure.segex;
    foreach (i; 0..n) {
        import std.exception;
        assert(check!LazySegBlockEngine(i, 1000, 114514) == ansLazy[i]);
    }

    foreach (i; 0..n) {
        import std.exception;
        assert(check!LazySegNaiveEngine(i, 1000, 114514) == ansLazy[i]);
    }

    foreach (i; 0..n) {
        import std.exception;
        assert(checkSimple!SimpleSegEngine(i, 1000, 114514) == ansSimple[i]);
    }

    foreach (i; 0..n) {
        import std.exception;
        assert(checkSimple!SimpleSegNaiveEngine(i, 1000, 114514) == ansSimple[i]);
    }
}
