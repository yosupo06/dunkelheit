module dcomp.segtree.simpleseg;

import dcomp.segtree.primitive;

import std.functional : binaryFun;

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

