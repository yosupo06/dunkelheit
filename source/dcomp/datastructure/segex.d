module dcomp.datastructure.segex;
import dcomp.datastructure.segtree;

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
    const uint N, n, sz, lg;
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
        return blks[k/B].d[k%B];
    }
    void singleSet(uint k, T x) {
        pushPath(k/B);
        blks[k/B].d[k%B] = x;
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
    import std.functional : binaryFun;
    const uint n, sz, lg;
    T[] d; L[] lz;
    @disable this();
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
    private void push(uint k) {
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


import std.traits;

int binSearchLeft(alias pred, TR)(TR t, int a, int b) 
if (isInstanceOf!(SegTree, TR)) {
    return binSearchLeft!pred(t.eng, a, b);
}

unittest {
    import std.random;
    import dcomp.datastructure.segtree;
    auto seg = LazySeg!(uint, uint,
        (a, b) => (a | b),
        (a, b) => (a | b),
        (a, b) => (a | b),
        0U, 0U, LazySegNaiveEngine)(100);
    uint[] d = new uint[100];
    foreach (i; 0..100) {
        auto u = uniform!"[]"(0, 31);
        seg[i] = u;
        d[i] = u;
    }
    int naive(int a, int b, int x) {
        int sm = 0;
        foreach (i; a..b) {
            sm = sm|d[i];
            if (sm&x) return i;
        }
        return b;
    }
    foreach (i; 0..100) {
        foreach (j; i..101) {
            foreach (x; 0..32) {
                assert(naive(i, j, x) ==
                    seg.binSearchLeft!((a) => a & x)(i, j));
                assert(seg.binSearchLeft!((a) => true)(i, j) == i-1);
            }
        }
    }
}

int binSearchRight(alias pred, TR)(TR t, int a, int b) 
if (isInstanceOf!(SegTree, TR)) {
    return binSearchRight!pred(t.eng, a, b);
}

unittest {
    import std.random;
    import dcomp.datastructure.segtree;
    auto seg = LazySeg!(uint, uint,
        (a, b) => (a | b),
        (a, b) => (a | b),
        (a, b) => (a | b),
        0U, 0U, LazySegNaiveEngine)(100);
    uint[] d = new uint[100];
    foreach (i; 0..100) {
        auto u = uniform!"[]"(0, 31);
        seg[i] = u;
        d[i] = u;
    }
    int naive(int a, int b, int x) {
        int sm = 0;
        foreach_reverse (i; a..b) {
            sm = sm|d[i];
            if (sm&x) return i;
        }
        return a-1;
    }
    foreach (i; 0..100) {
        foreach (j; i..101) {
            foreach (x; 0..32) {
                assert(naive(i, j, x) ==
                    seg.binSearchRight!((a) => a & x)(i, j));
                assert(seg.binSearchRight!((a) => true)(i, j) == j);
            }
        }
    }
}


int binSearchLeft(alias pred, TR)(TR t, int a, int b) 
if (isInstanceOf!(LazySegNaiveEngine, TR)) {
    alias args = TemplateArgsOf!TR;
    alias opTT = args[2];
    with (t) {
        auto x = args[5];
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
    }
}

int binSearchRight(alias pred, TR)(TR t, int a, int b) 
if (isInstanceOf!(LazySegNaiveEngine, TR)) {
    alias args = TemplateArgsOf!TR;
    alias opTT = args[2];
    with (t) {
        auto x = args[5];
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

struct SimpleSegNaiveEngine(T, alias opTT, T eT) {
    alias DataType = T;
    alias LazyType = void;
    import std.functional : binaryFun;
    const uint n, sz, lg;
    T[] d;
    @disable this();
    @property size_t length() const {return sz;}
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

