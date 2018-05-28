module dkh.datastructure.segtreenaive;

import dkh.datastructure.segtree;

/*
This file contain naive codes of segtree, you don't need to import this file usually.
If you want to use segtree, import dkh.dasatructure.segtree.
*/

import std.conv : to;
import std.functional : binaryFun;
import std.traits : isInstanceOf;

static struct NaiveSimple(T, alias opTT, T eT) {
    import std.conv : to;
    alias DataType = T;
    alias LazyType = void;
    alias BinSearch = binSearchNaiveSimple;
    T[] d;
    @property size_t length() const { return d.length; }
    this(uint n) {
        d = new T[n];
    }
    this(T[] first) {
        d = first.dup;
    }
    const(T) sum(uint l, uint r) {
        T sm = eT;
        foreach (i; l..r) {
            sm = opTT(sm, d[i]);
        }
        return sm;
    }
    const(T) single(int k) { return d[k]; }
    void singleSet(int k, in T x) { d[k] = x; }
}

static struct NaiveLazy(T, L, alias opTT, alias opTL, alias opLL, T eT, L eL) {
    import std.conv : to;
    alias DataType = T;
    alias LazyType = L;
    alias BinSearch = binSearchNaiveLazy;
    T[] d;
    @property size_t length() const { return d.length; }
    this(uint n) {
        d = new T[n];
    }
    this(T[] first) {
        d = first.dup;
    }
    const(T) sum(uint l, uint r) {
        T sm = eT;
        foreach (i; l..r) {
            sm = opTT(sm, d[i]);
        }
        return sm;
    }
    void add(uint l, uint r, in L m) {
        foreach (i; l..r) {
            d[i] = opTL(d[i], m);
        }
    }
    const(T) single(int k) { return d[k]; }
    void singleSet(int k, in T x) { d[k] = x; }
}


int binSearchNaiveSimple(bool rev, alias pred, TR)(TR t, int a, int b) {
    import std.traits : TemplateArgsOf;
    alias args = TemplateArgsOf!TR;
    alias opTT = args[1];
    auto x = args[2];
    with (t) {
        static if (!rev) {
            //left
            if (pred(x)) return a-1;
            foreach (i; a..b) {
                x = opTT(x, d[i]);
                if (pred(x)) return i;
            }
            return b;
        } else {
            if (pred(x)) return b;
            foreach_reverse (i; a..b) {
                x = opTT(d[i], x);
                if (pred(x)) return i;
            }
            return a-1;
        }
    }
}

int binSearchNaiveLazy(bool rev, alias pred, TR)(TR t, int a, int b) {
    import std.traits : TemplateArgsOf;
    alias args = TemplateArgsOf!TR;
    alias opTT = args[2];
    auto x = args[5];
    with (t) {
        static if (!rev) {
            //left
            if (pred(x)) return a-1;
            foreach (i; a..b) {
                x = opTT(x, d[i]);
                if (pred(x)) return i;
            }
            return b;
        } else {
            if (pred(x)) return b;
            foreach_reverse (i; a..b) {
                x = opTT(d[i], x);
                if (pred(x)) return i;
            }
            return a-1;
        }
    }
}

unittest {
    import std.meta : AliasSeq;
    alias SimpleEngines = AliasSeq!(SimpleSegEngine);
    alias LazyEngines = AliasSeq!(LazySegEngine);

    import std.random;
    
    void f(alias T)() {
        auto nav = LazySeg!(uint, uint,
            (a, b) => (a | b),
            (a, b) => (a | b),
            (a, b) => (a | b),
            0U, 0U, NaiveLazy)(100);
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
    import std.meta : AliasSeq;
    alias SimpleEngines = AliasSeq!(SimpleSegEngine);
    alias LazyEngines = AliasSeq!(LazySegEngine);
    
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
    import std.meta : AliasSeq;
    alias SimpleEngines = AliasSeq!(SimpleSegEngine);
    alias LazyEngines = AliasSeq!(LazySegEngine);

    import std.typecons, std.random, std.algorithm;
    import dkh.modint, dkh.matrix, dkh.numeric.primitive;
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

    import dkh.stopwatch;
    StopWatch sw; sw.start;

    int n = 40;
    Mat[] ansLazy = new Mat[n];
    foreach (i; 0..n) {
        ansLazy[i] = check!NaiveLazy(i, 500, 114514);
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
