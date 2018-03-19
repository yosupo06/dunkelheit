module dkh.datastructure.segtree;

import std.conv : to;
import std.functional : binaryFun;
import std.traits : isInstanceOf;

struct SegTree(alias E, Args...) {
    import std.traits : ReturnType;
    alias Engine = E!Args;
    alias T = Engine.DataType;
    alias L = Engine.LazyType;

    Engine eng;

    this(size_t n) { eng = Engine(n.to!uint); }
    this(T[] first) { eng = Engine(first); }

    @property size_t length() const { return eng.length(); }
    @property size_t opDollar() const { return eng.length(); }
    
    struct Range {
        Engine* eng;
        size_t start, end;
        @property const(T) sum() {
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
    size_t[2] opSlice(size_t dim : 0)(size_t start, size_t end) {
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

ptrdiff_t binSearchLeft(alias pred, TR)(TR t, ptrdiff_t a, ptrdiff_t b) 
if (isInstanceOf!(SegTree, TR)) {
    return TR.Engine.BinSearch!(false, pred)(t.eng, a.to!int, b.to!int);
}

ptrdiff_t binSearchRight(alias pred, TR)(TR t, ptrdiff_t a, ptrdiff_t b) 
if (isInstanceOf!(SegTree, TR)) {
    return TR.Engine.BinSearch!(true, pred)(t.eng, a.to!int, b.to!int);
}

/**
SegTree

T型の配列aについて、opTT(a[l..r])が高速に計算できる。
opTTは結合率を満たす2引数関数, eTは単位元。
 */
alias SimpleSeg(T, alias opTT, T eT, alias Engine = SimpleSegEngine) =
    SegTree!(Engine, T, binaryFun!opTT, eT);

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

struct SimpleSegEngine(T, alias opTT, T eT) {
    alias DataType = T;
    alias LazyType = void;
    alias BinSearch = binSearchSimple;
    uint n, sz, lg;
    T[] d;
    @property uint length() const {return n;}
    this(uint n) {
        import std.algorithm : each;
        this.n = n;
        if (n == 0) return;
        while ((2^^lg) < n) lg++;
        sz = 2^^lg;
        d = new T[](2*sz);
        d.each!((ref x) => x = eT);
    }
    this(T[] first) {
        import std.conv : to;
        import std.algorithm : each;
        n = first.length.to!uint;
        if (n == 0) return;
        while ((2^^lg) < n) lg++;
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

int binSearchSimple(bool rev, alias pred, TR)(TR t, int a, int b) {
    import std.traits : TemplateArgsOf;
    alias args = TemplateArgsOf!TR;
    alias opTT = args[1];
    auto x = args[2];
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
                int md = (l+r)/2;
                f(a, b, md, r, 2*k+1);
                if (pos < md) f(a, b, l, md, 2*k);
            }
            f(a, b, 0, sz, 1);
            return pos;            
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
    alias BinSearch = binSearchLazy;
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

int binSearchLazy(bool rev, alias pred, TR)(TR t, int a, int b) {
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
                if (a <= l && r <= b && !pred(opTT(x, s[k].d))) {
                    x = opTT(x, s[k].d);
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
                if (a <= l && r <= b && !pred(opTT(x, s[k].d))) {
                    x = opTT(s[k].d, x);
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
