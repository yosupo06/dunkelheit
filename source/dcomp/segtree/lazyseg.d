module dcomp.segtree.lazyseg;

import dcomp.segtree.primitive;

import std.functional : binaryFun;

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
alias LazySeg(T, L, alias opTT, alias opTL, alias opLL, T eT, L eL, alias Engine = LazySegEngine) =
    SegTree!(Engine, T, L , binaryFun!opTT, binaryFun!opTL, binaryFun!opLL, eT, eL);

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


struct LazySegEngine(T, L, alias opTT, alias opTL, alias opLL, T eT, L eL) {
    import std.typecons : Tuple;
    alias DataType = T;
    alias LazyType = L;
    alias BinSearch = binSearch;
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
    @property uint length() const { return n; }
    pragma(inline):
    private void lzAdd(uint k, in L x) {
        s[k].lz = opLL(s[k].lz, x);
        s[k].d = opTL(s[k].d, x);
    }
    public void push(uint k) {
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



unittest {
    //issue 17466
    import std.stdio;
    auto seg = LazySeg!(long[2], long[2],
        (a, b) => a, (a, b) => a, (a, b) => a, [0L, 0L], [0L, 0L])(10);
}


int binSearch(bool rev, alias pred, TR)(TR t, int a, int b) {
    static if (!rev) {
        return binSearchLeft!pred(t, a, b);
    } else {
        return binSearchRight!pred(t, a, b);
    }
}

int binSearchLeft(alias pred, TR)(TR t, int a, int b) {
    import std.traits : TemplateArgsOf;
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

int binSearchRight(alias pred, TR)(TR t, int a, int b) {
    import std.traits : TemplateArgsOf;
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
