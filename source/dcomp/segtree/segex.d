module dcomp.segtree.segex;

import dcomp.segtree.primitive;
import dcomp.segtree.simpleseg;
import dcomp.segtree.lazyseg;

struct SimpleSegNaiveEngine(T, alias opTT, T eT) {
    alias DataType = T;
    alias LazyType = void;
    uint n, sz, lg;
    T[] d;
    @property uint length() const {return n;}
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
    //d[a]+d[a+1]+...+d[b-1]
    T sum(uint a, uint b, uint l, uint r, uint k) {
        if (b <= l || r <= a) return eT;
        if (a <= l && r <= b) return d[k];
        push(k);
        uint md = (l+r)/2;
        return opTT(sum(a, b, l, md, 2*k),
            sum(a, b, md, r, 2*k+1));
    }    
    T sum(uint a, uint b) {
        assert(0 <= a && a <= b && b <= n);
        return sum(a, b, 0, sz, 1);
    }
}

struct LazySegBlockEngine(T, L, alias opTT, alias opTL, alias opLL, T eT, L eL) {
    static immutable uint B = 16;
    import std.algorithm : min;
    import std.typecons : Tuple;
    alias DataType = T;
    alias LazyType = L;
    static struct Block {
        T[B] d;
        this(T[] first) {
            uint r = min(first.length, B);
            foreach (i; 0..r) {
                d[i] = first[i];
            }
            foreach (i; r..B) {
                d[i] = eT;
            }
        }
        T sum(uint a, uint b) {
            T sm = eT;
            foreach (i; a..b) {
                sm = opTT(sm, d[i]);
            }
            return sm;
        }
        void add(uint a, uint b, L x) {
            foreach (i; a..b) {
                d[i] = opTL(d[i], x);
            }
        }
    }
    uint N, n, sz, lg;
    Block[] blks;
    alias S = Tuple!(T, "d", L, "lz");
    S[] s;
    this(uint N) {
        import std.conv : to;
        import std.algorithm : each;
        this.N = N;
        n = N / B + 1;
        blks = new Block[n+1];
        foreach (i; 0..n+1) {
            blks[i].d.each!((ref x) => x = eT);
        }
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
        this.N = first.length.to!uint;
        n = first.length.to!uint / B + 1;
        blks = new Block[n+1];
        foreach (i; 0..n) {
            blks[i] = Block(first[i*B..min($, (i+1)*B)]);
        }
        blks[n] = Block([]);
        uint lg = 0;
        while ((2^^lg) < n) lg++;
        this.lg = lg;
        sz = 2^^lg;
        s = new S[](2*sz);
        s.each!((ref x) => x = S(eT, eL));
        foreach (i; 0..n) {
            s[sz+i].d = blks[i].sum(0, B);
        }
        foreach_reverse (i; 1..sz) {
            update(i);
        }
    }
    @property size_t length() const { return N; }
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
    private void pushPath(uint k) {
        k += sz;
        foreach_reverse (i; 1..lg+1) {
            push(k>>i);
        }
    }
    private void pushPath2(uint a, uint b) {
        a += sz; b += sz;
        foreach_reverse (i; 1..lg+1) {
            push(a>>i);
            if ((a>>i) != (b>>i)) push(b>>i);
        }
    }
    private void update(uint k) {
        s[k].d = opTT(s[2*k].d, s[2*k+1].d);
    }

    T single(uint k) {
        pushPath(k/B);
        return opTL(blks[k/B].d[k%B], s[k/B+sz].lz);
    }
    void singleSet(uint k, T x) {
        pushPath(k/B);
        if (s[k/B+sz].lz != eL) blks[k/B].add(0, B, s[k/B+sz].lz);
        s[k/B+sz].lz = eL;
        blks[k/B].d[k%B] = x;
        upPath(k/B);
    }
    T sumBody(uint a, uint b) {
        assert(0 <= a && a <= b && b <= n);
        T sml = eT, smr = eT;
        a += sz; b += sz;
        while (a < b) {
            if (a & 1) sml = opTT(sml, s[a++].d);
            if (b & 1) smr = opTT(s[--b].d, smr);
            a >>= 1; b >>= 1;
        }
        return opTT(sml, smr);
    }
    T sum(uint a, uint b) {
        if (a == b) return eT;
        uint aB = a / B, aC = a % B;
        uint bB = b / B, bC = b % B;
        if (aB == bB) {
            pushPath(aB);
            return opTL(blks[aB].sum(aC, bC), s[aB+sz].lz);
        }
        pushPath2(aB, bB);
        auto left = opTL(blks[aB].sum(aC, B), s[aB+sz].lz);
        auto right = opTL(blks[bB].sum(0, bC), s[bB+sz].lz);
        return opTT(opTT(left, sumBody(aB+1, bB)), right);
    }
    void upPath(uint k) {
        k += sz;
        s[k].d = blks[k-sz].sum(0, B);
        foreach (i; 1..lg+1) {
            k >>= 1;
            update(k);
        }
    }
    void upPath2(uint a, uint b) {
        a += sz; b += sz;
        s[a].d = blks[a-sz].sum(0, B);
        s[b].d = blks[b-sz].sum(0, B);
        foreach (i; 1..lg+1) {
            a >>= 1; b >>= 1;
            update(a);
            if (a != b) update(b);
        }
    }
    void addBody(uint a, uint b, L x) {
        assert(0 <= a && a <= b && b <= n);
        a += sz; b += sz;
        while (a < b) {
            if (a & 1) lzAdd(a++, x);
            if (b & 1) lzAdd(--b, x);
            a >>= 1; b >>= 1;
        }        
    }
    void add(uint a, uint b, L x) {
        if (a == b) return;
        uint aB = a / B, aC = a % B;
        uint bB = b / B, bC = b % B;
        if (aB == bB) {
            pushPath(aB);
            if (s[aB+sz].lz != eL) blks[aB].add(0, B, s[aB+sz].lz);
            s[aB+sz].lz = eL;
            blks[aB].add(aC, bC, x);
            upPath(aB);
            return;
        }
        pushPath2(aB, bB);
        if (s[aB+sz].lz != eL) blks[aB].add(0, B, s[aB+sz].lz);
        if (s[bB+sz].lz != eL) blks[bB].add(0, B, s[bB+sz].lz);
        s[aB+sz].lz = s[bB+sz].lz = eL;
        blks[aB].add(aC, B, x);
        blks[bB].add(0, bC, x);
        addBody(aB+1, bB, x);
        upPath2(aB, bB);
    }
}

struct LazySegNaiveEngine(T, L, alias opTT, alias opTL, alias opLL, T eT, L eL) {
    alias DataType = T;
    alias LazyType = L;
    alias BinSearch = binSearchLazyNaive;
    import std.functional : binaryFun;
    uint n, sz, lg;
    T[] d; L[] lz;
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
        lz = new L[](2*sz);
        lz.each!((ref x) => x = eL);
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
        lz = new L[](2*sz);
        lz.each!((ref x) => x = eL);
    }
    private void lzAdd(uint k, L x) {
        d[k] = opTL(d[k], x);
        lz[k] = opLL(lz[k], x);
    }
    public void push(uint k) {
        if (lz[k] == eL) return;
        lzAdd(2*k, lz[k]);
        lzAdd(2*k+1, lz[k]);
        lz[k] = eL;
    }
    void update(uint k) {
        d[k] = opTT(d[2*k], d[2*k+1]);
    }
    T single(uint k) {
        k += sz;
        foreach_reverse (uint i; 1..lg+1) {
            push(k>>i);
        }
        return d[k];
    }
    void singleSet(uint k, T x) {
        k += sz;
        foreach_reverse (uint i; 1..lg+1) {
            push(k>>i);
        }
        d[k] = x;
        foreach (uint i; 1..lg+1) {
            d[k>>i] = opTT(d[2*(k>>i)], d[2*(k>>i)+1]);
        }
    }
    //d[a]+d[a+1]+...+d[b-1]
    T sum(uint a, uint b, uint l, uint r, uint k) {
        if (b <= l || r <= a) return eT;
        if (a <= l && r <= b) return d[k];
        push(k);
        uint md = (l+r)/2;
        return opTT(sum(a, b, l, md, 2*k),
            sum(a, b, md, r, 2*k+1));
    }    
    T sum(uint a, uint b) {
        assert(0 <= a && a <= b && b <= n);
        return sum(a, b, 0, sz, 1);
    }
    void add(uint a, uint b, L x, uint l, uint r, uint k) {
        if (b <= l || r <= a) return;
        if (a <= l && r <= b) {
            lzAdd(k, x);
            return;
        }
        push(k);
        uint md = (l+r)/2;
        add(a, b, x, l, md, 2*k);
        add(a, b, x, md, r, 2*k+1);
        d[k] = opTT(d[2*k], d[2*k+1]);
    }
    void add(uint a, uint b, L x) {
        assert(0 <= a && a <= b && b <= n);
        add(a, b, x, 0, sz, 1);
    }
}

int binSearchLazyNaive(bool rev, alias pred, TR)(TR t, int a, int b) {
    import std.traits : TemplateArgsOf;
    alias args = TemplateArgsOf!TR;
    alias opTT = args[2];
    auto x = args[5];
    with (t) {
        static if (!rev) {
            //left
            if (pred(x)) return a-1;
            int pos = a;
            void f(int a, int b, int l, int r, int k) {
                if (b <= l || r <= a) return;
                if (a <= l && r <= b && !pred(opTT(x, d[k]))) {
                    x = opTT(x, d[k]);
                    pos = r;
                    return;
                }
                if (l+1 == r) return;
                push(k);
                int md = (l+r)/2;
                f(a, b, l, md, 2*k);
                if (pos >= md) f(a, b, md, r, 2*k+1);
            }
            f(a, b, 0, sz, 1);
            return pos;
        } else {
            //right
            if (pred(x)) return b;
            int pos = b-1;
            void f(int a, int b, int l, int r, int k) {
                if (b <= l || r <= a) return;
                if (a <= l && r <= b && !pred(opTT(x, d[k]))) {
                    x = opTT(d[k], x);
                    pos = l-1;
                    return;
                }
                if (l+1 == r) return;
                push(k);
                int md = (l+r)/2;
                f(a, b, md, r, 2*k+1);
                if (pos < md) f(a, b, l, md, 2*k);
            }
            f(a, b, 0, sz, 1);
            return pos;
        }
    }
}

unittest {
    import dcomp.segtree.naive;
    import std.traits : AliasSeq;
    alias SimpleEngines = AliasSeq!(SimpleSegEngine);
    alias LazyEngines = AliasSeq!(LazySegEngine, LazySegNaiveEngine);

    import std.random;
    
    void f(alias T)() {
        auto nav = LazySeg!(uint, uint,
            (a, b) => (a | b),
            (a, b) => (a | b),
            (a, b) => (a | b),
            0U, 0U, Naive)(100);
        auto seg = LazySeg!(uint, uint,
            (a, b) => (a | b),
            (a, b) => (a | b),
            (a, b) => (a | b),
            0U, 0U, T)(100);
        foreach (i; 0..100) {
            auto u = uniform!"[]"(0, 31);
            seg[i] = u;
            nav[i] = u;
        }
        foreach (i; 0..100) {
            foreach (j; i..101) {
                foreach (x; 0..32) {
                    assert(
                        nav.binSearchLeft!((a) => a & x)(i, j) ==
                        seg.binSearchLeft!((a) => a & x)(i, j));
                    assert(seg.binSearchLeft!((a) => true)(i, j) == i-1);
                    assert(
                        nav.binSearchRight!((a) => a & x)(i, j) ==
                        seg.binSearchRight!((a) => a & x)(i, j));
                    assert(seg.binSearchRight!((a) => true)(i, j) == j);
                }
            }
        }
    }
    void g(alias T)() {
        auto nav = SimpleSeg!(uint,
            (a, b) => (a | b),
            0U, NaiveSimple)(100);
        auto seg = SimpleSeg!(uint,
            (a, b) => (a | b),
            0U, T)(100);
        foreach (i; 0..100) {
            auto u = uniform!"[]"(0, 31);
            seg[i] = u;
            nav[i] = u;
        }
        foreach (i; 0..100) {
            foreach (j; i..101) {
                foreach (x; 0..32) {
                    assert(
                        nav.binSearchLeft!((a) => a & x)(i, j) ==
                        seg.binSearchLeft!((a) => a & x)(i, j));
                    assert(seg.binSearchLeft!((a) => true)(i, j) == i-1);
                    assert(
                        nav.binSearchRight!((a) => a & x)(i, j) ==
                        seg.binSearchRight!((a) => a & x)(i, j));
                    assert(seg.binSearchRight!((a) => true)(i, j) == j);
                }
            }
        }
    }
    foreach (E; LazyEngines) {
        f!E();
    }
    foreach (E; SimpleEngines) {
        g!E();
    }
}

unittest {
    //some func test
    import std.traits : AliasSeq;
    alias SimpleEngines = AliasSeq!(SimpleSegEngine, SimpleSegNaiveEngine);
    alias LazyEngines = AliasSeq!(LazySegEngine, LazySegBlockEngine, LazySegNaiveEngine);
    
    void checkSimple(alias Seg)() {
        import std.algorithm : max;
        
        alias S = SegTree!(Seg, int, (a, b) => a+b, 0);
        S seg;
        seg = S(10);
        assert(seg.length == 10);
    }
    void check(alias Seg)() {
        import std.algorithm : max;

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

    foreach (E; SimpleEngines) {
        checkSimple!E();
    }
    foreach (E; LazyEngines) {
        check!E();
    }
}

unittest {
    //stress test
    import dcomp.segtree.naive;
    import std.traits : AliasSeq;
    alias SimpleEngines = AliasSeq!(SimpleSegEngine, SimpleSegNaiveEngine);
    alias LazyEngines = AliasSeq!(LazySegEngine, LazySegBlockEngine, LazySegNaiveEngine);

    import std.typecons, std.random, std.algorithm;
    import dcomp.modint, dcomp.matrix, dcomp.numeric.primitive;
    static immutable uint MD = 10^^9 + 7;
    alias Mint = ModInt!MD;
    alias Mat = SMatrix!(Mint, 2, 2);

    static immutable Mat e = matrix!(2, 2, (i, j) => Mint(i == j ? 1 : 0))();

    Xorshift128 gen;

    Mat rndM() {
        Mat m;
        while (true) {
            m = matrix!(2, 2, (i, j) => Mint(uniform(0, MD, gen)))();
            if (m[0, 0] * m[1, 1] == m[0, 1] * m[1, 0]) continue;
            break;
        }
        return m;
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
    Mat check(alias Seg)(int N, int M, uint seed) {
        alias T = Tuple!(Mat, int);
        gen = Xorshift128(seed);
        T[] a = new T[N];
        a.each!((ref x) => x = T(rndM(), 1));
        alias Q = Tuple!(int, int, int, Mat);
        Q[] que = new Q[M];
        foreach (ref q; que) {
            q[0] = uniform(0, 4, gen);
            if (N == 0) q[0] %= 2;
            if (q[0] < 2) {
                q[1] = uniform(0, N+1, gen);
                q[2] = uniform(0, N+1, gen);
                if (q[1] > q[2]) swap(q[1], q[2]);
            } else {
                q[1] = uniform(0, N, gen);
            }
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
            } else if (q[0] == 1) {
                //set
                s[q[1]..q[2]] += q[3];
            } else if (q[0] == 2) {
                //single sum
                T w = s[q[1]];
                res += w[0];
            } else if (q[0] == 3) {
                //single set
                s[q[1]] = T(q[3], 1);
            }
        }
        return res;
    }

    import dcomp.stopwatch;
    StopWatch sw; sw.start;

    int n = 40;
    Mat[] ansLazy = new Mat[n];
    foreach (i; 0..n) {
        ansLazy[i] = check!Naive(i, 500, 114514);
    }
    Mat[] ansSimple = new Mat[n];
    foreach (i; 0..n) {
        ansSimple[i] = checkSimple!NaiveSimple(i, 500, 114514);
    }
    
    foreach (E; SimpleEngines) {
        foreach (i; 0..n) {
            assert(checkSimple!E(i, 500, 114514) == ansSimple[i]);
        }
    }
    foreach (E; LazyEngines) {
        foreach (i; 0..n) {
            assert(check!E(i, 500, 114514) == ansLazy[i]);
        }
    }

    import std.stdio;
    writeln("SegTree Stress: ", sw.peek.toMsecs);
}
