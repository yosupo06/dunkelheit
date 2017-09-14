module dcomp.datastructure.segtree;

/// 遅延伝搬Segment Tree
struct LazySeg(T, L, alias opTT, alias opTL, alias opLL, T eT, L eL, bool isSimple = false) {
    const uint n, sz, lg;
    T[] d;
    static if (!isSimple) L[] lz;
    @disable this();
    this(uint n) {
        import std.algorithm : fill, each;
        import core.bitop : bsr;
        if (n == 0) return;
        uint lg = 0;
        while ((2^^lg) < n) lg++;
        this.n = n;
        this.lg = lg;
        sz = 2^^lg;
        d = new T[](2*sz);
        d.each!((ref x) => x = eT);
        static if (!isSimple) {
            lz = new L[](2*sz);
            lz.each!((ref x) => x = eL);
        }
    }
    static if (isSimple) {
        private void lzAdd(uint k, L x) {}
        private void push(uint k) {}
    } else {
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
    }
    T single(uint k) {
        k += sz;
        foreach_reverse (uint i; 1..lg+1) {
            push(k>>i);
        }
        return d[k];
    }
    void singleSet(T x, uint k) {
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
    @property uint opDollar() const {return sz;}
    struct Range {
        LazySeg* seg;
        uint start, end;
        @property T sum() {
            return seg.sum(start, end);
        }
    }
    T opIndex(uint k) {
        assert(0 <= k && k < n);
        return single(k);
    }
    void opIndexAssign(T x, uint k) {
        assert(0 <= k && k < n);
        singleSet(x, k);
    }
    uint[2] opSlice(size_t dim)(uint start, uint end) {
        assert(0 <= start && start <= end && end <= sz);
        return [start, end];
    }
    Range opIndex(uint[2] rng) {
        return Range(&this, rng[0], rng[1]);
    }
    static if (!isSimple) {
        void opIndexOpAssign(string op : "+")(L x, uint[2] rng) {
            add(rng[0], rng[1], x);
        }
    }
}

///
unittest {
    import std.algorithm : max;
    ///区間max, 区間加算
    auto seg = LazySeg!(int, int,
        (a, b) => max(a, b), (a, b) => a+b, (a, b) => a+b, 0, 0)(3);
    
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

unittest {
    //issue 17466
    import std.stdio;
    auto seg = LazySeg!(long[2], long[2],
        (a, b) => a, (a, b) => a, (a, b) => a, [0L, 0L], [0L, 0L])(10);
}

alias SimpleSeg(T, alias op, T e) = LazySeg!(T, bool, op, (a, b) => a, (a, b) => a, e, false, false);

///
unittest {
    import std.algorithm : max;
    ///区間加算
    import std.typecons;
    auto seg = SimpleSeg!(int, (a, b) => max(a, b), 0)(3);

    //[2, 1, 4]
    seg[0] = 2; seg[1] = 1; seg[2] = 4;
    assert(seg[0..3].sum == 4);

    //[2, 1, 5]
    seg[2] = 5;
    assert(seg[0..2].sum == 2);
    assert(seg[0..3].sum == 5);
}



import std.traits;

int binSearchLeft(alias pred, TR)(TR t, int a, int b) 
if (isInstanceOf!(LazySeg, TR)) {
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

unittest {
    import std.random;
    auto seg = LazySeg!(uint, uint,
        (a, b) => (a | b),
        (a, b) => (a | b),
        (a, b) => (a | b),
        0U, 0U)(100);
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
if (isInstanceOf!(LazySeg, TR)) {
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

unittest {
    import std.random;
    auto seg = LazySeg!(uint, uint,
        (a, b) => (a | b),
        (a, b) => (a | b),
        (a, b) => (a | b),
        0U, 0U)(100);
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
