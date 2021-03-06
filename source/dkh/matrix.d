module dkh.matrix;

import dkh.bitop;

/// 行列ライブラリ
struct SMatrix(T, size_t H, size_t W) {
    alias DataType = T;
    T[W][H] data;
    this(Args...)(Args args) {
        static assert(args.length == H*W);
        foreach (i, v; args) {
            data[i/W][i%W] = v;
        }
    }
    SMatrix dup() const { return this; }

    @property static size_t height() {return H;}
    @property static size_t width() {return W;}

    ref inout(T) opIndex(size_t i1, size_t i2) inout {
        return data[i1][i2];
    }
    auto opBinary(string op:"+", R)(in R r) const
    if(height == R.height && width == R.width) {
        SMatrix res = this;
        foreach (y; 0..height) foreach (x; 0..W) res[y, x] += r[y, x];
        return res;
    }
    auto opBinary(string op:"*", R)(in R r) const
    if(width == R.height) {
        auto rBuf = SMatrix!(T, R.width, R.height)();
        foreach (y; 0..R.height) {
            foreach (x; 0..R.width) {
                rBuf[x, y] = r[y, x];
            }
        }
        auto res = SMatrix!(T, height, R.width)();
        foreach (y; 0..height) {
            foreach (x; 0..R.width) {
                T sm;
                auto lv = this.data[y][];
                auto rv = rBuf.data[x][];
                foreach (k; 0..width) {
                    sm += lv[k] * rv[k];
                }
                res[y, x] = sm;
            }
        }
        return res;
    }
    auto opOpAssign(string op, T)(in T r) {return mixin ("this=this"~op~"r");}

    void swapLine(size_t x, size_t y) {
        import std.algorithm : swap;
        foreach (i; 0..W) swap(data[x][i], data[y][i]);
    }
}

import dkh.foundation, dkh.modint;
/// 行列ライブラリ(Mod2)
struct SMatrixMod2(size_t H, size_t W) {
    alias DataType = ModInt!2;
    static immutable B = 64;
    static immutable L = (W + B-1) / B;
    ulong[L][H] data;
    this(Args...)(Args args) {
        static assert(args.length == H*W);
        foreach (i, v; args) {
            this[i/W, i%W] = v;
        }
    }
    SMatrixMod2 dup() const { return this; }

    @property static size_t height() {return H;}
    @property static size_t width() {return W;}

    const(DataType) opIndex(size_t i1, size_t i2) const {
        assert(i1 < H && i2 < W);
        return DataType(((data[i1][i2/B] >> (i2%B)) & 1UL) ? 1 : 0);
    }
    void opIndexAssign(DataType d, size_t i1, size_t i2) {
        assert(i1 < H && i2 < W);
        size_t r = i2 % 64;
        if (d.v) data[i1][i2/B] |= (1UL<<r);
        else data[i1][i2/B] &= ~(1UL<<r);
    }
    void opIndexAssign(bool d, size_t i1, size_t i2) {
        assert(i1 < H && i2 < W);
        size_t r = i2 % 64;
        if (d) data[i1][i2/B] |= (1UL<<r);
        else data[i1][i2/B] &= ~(1UL<<r);
    }
    auto opIndexOpAssign(string op)(DataType d, size_t i1, size_t i2) {
        return mixin("this[i1,i2]=this[i1,i2]"~op~"d");
    }
    auto opBinary(string op:"+", R)(in R r) const
    if(height == R.height && width == R.width) {
        auto res = this.dup;
        foreach (y; 0..height) foreach (x; 0..L) {
            res.data[y][x] ^= r.data[y][x];
        }
        return res;
    }
    auto opBinary(string op:"*", R)(in R r) const
    if(width == R.height) {
        auto r2 = SMatrixMod2!(R.width, R.height)();
        foreach (y; 0..R.height) foreach (x; 0..R.width) {
            r2[x, y] = r[y, x];
        }
        auto res = SMatrixMod2!(height, R.width)();
        foreach (y; 0..height) {
            foreach (x; 0..R.width) {
                ulong sm = 0;
                foreach (k; 0..L) {
                    sm ^= data[y][k]&r2.data[x][k];
                }
                res[y, x] = poppar(sm);
            }
        }
        return res;
    }
    auto opOpAssign(string op, T)(T r) {return mixin ("this=this"~op~"r");}

    void swapLine(size_t x, size_t y) {
        import std.algorithm : swap;
        foreach (i; 0..L) swap(data[x][i], data[y][i]);
    }
}

/// ditto
struct DMatrix(T) {
    alias DataType = T;
    size_t h, w;
    T[] data;
    this(size_t h, size_t w) {
        this.h = h; this.w = w;
        data = new T[h*w];
    }
    this(size_t h, size_t w, in T[] d) {
        this(h, w);
        assert(d.length == h*w);
        data[] = d[];
    }
    DMatrix dup() const { return DMatrix(h, w, data); }

    @property size_t height() const {return h;}
    @property size_t width() const {return w;}

    ref inout(T) opIndex(size_t i1, size_t i2) inout {
        return data[i1*width+i2];
    }
    auto opBinary(string op:"+", R)(in R r) const {
        assert(height == r.height && width == r.width);
        auto res = this.dup;
        foreach (y; 0..height) foreach (x; 0..width) res[y, x] += r[y, x];
        return res;
    }
    auto opBinary(string op:"*", R)(in R r) const {
        assert(width == r.height);
        auto rBuf = DMatrix!(T)(R.width, R.height);
        foreach (y; 0..R.height) {
            foreach (x; 0..R.width) {
                rBuf[x, y] = r[y, x];
            }
        }
        auto res = DMatrix!(T)(height, r.width);
        foreach (y; 0..height) {
            foreach (x; 0..r.width) {
                foreach (k; 0..width) {
                    res[y, x] += this[y, k]*rBuf[x, k];
                }
            }
        }
        return res;
    }
    auto opOpAssign(string op, T)(in T r) {return mixin ("this=this"~op~"r");}
    void swapLine(size_t x, size_t y) {
        import std.algorithm : swap;
        foreach (i; 0..w) swap(this[x, i], this[y, i]);
    }    
}

///
unittest {
    import dkh.numeric.primitive;
    auto mat = DMatrix!int(2, 2, [0, 1, 1, 1]);
    assert(pow(mat, 10, DMatrix!int(2, 2, [1, 0, 0, 1]))[0, 0] == 34); //Fib_10
}

unittest {
    auto mat1 = DMatrix!int(2, 2, [1, 1, 1, 1]);
    auto mat2 = DMatrix!int(2, 2, [2, 2, 2, 2]);
    auto mat3 = mat1 + mat2;
    assert(mat1[0, 0] == 1);
    assert(mat2[0, 0] == 2);
}

auto matrix(size_t H, size_t W, alias pred)() {
    import std.traits : ReturnType;
    SMatrix!(typeof(pred(0, 0)), H, W) res;
    foreach (y; 0..H) {
        foreach (x; 0..W) {
            res[y, x] = pred(y, x);
        }
    }
    return res;
}

auto matrix(alias pred)(size_t H, size_t W) {
    import std.traits : ReturnType;
    auto res = DMatrix!(typeof(pred(0, 0)))(H, W);
    foreach (y; 0..H) {
        foreach (x; 0..W) {
            res[y, x] = pred(y, x);
        }
    }
    return res;
}

auto matrixMod2(size_t H, size_t W, alias pred)() {
    import std.traits : ReturnType;
    SMatrixMod2!(H, W) res;
    foreach (y; 0..H) {
        foreach (x; 0..W) {
            res[y, x] = pred(y, x);
        }
    }
    return res;
}

auto determinent(Mat)(in Mat _m) {
    auto m = _m.dup;
    assert(m.height == m.width);
    import std.conv, std.algorithm;
    alias M = Mat.DataType;
    size_t N = m.height;
    M base = 1;
    foreach (i; 0..N) {
        if (m[i, i] == M(0)) {
            foreach (j; i+1..N) {
                if (m[j, i] != M(0)) {
                    m.swapLine(i, j);
                    base *= M(-1);
                    break;
                }
            }
            if (m[i, i] == M(0)) return M(0);
        }
        base *= m[i, i];
        M im = M(1)/m[i, i];
        foreach (j; 0..N) {
            m[i, j] *= im;
        }
        foreach (j; i+1..N) {
            M x = m[j, i];
            foreach (k; 0..N) {
                m[j, k] -= m[i, k] * x;
            }
        }
    }
    return base;
}


size_t rank(Mat)(in Mat _m) {
    alias M = Mat.DataType;
    auto m = _m.dup;
    immutable size_t h = m.height, w = m.width;
    size_t rnk;
    foreach (c; 0..w) {
        size_t mr = h;
        foreach (r; rnk..h) {
            if (m[r, c]) {
                mr = r;
                break;
            }
        }
        if (mr == h) continue;
        m.swapLine(rnk, mr);
        foreach (r; rnk + 1..h) {
            if (!a[r, c]) continue;
            auto freq = a[r, c] / a[rnk, c];
            foreach (i; c..w) m[r, i] -= freq * m[rnk, i];
        }
        rnk++;
        if (rnk == h) break;
    }
    return rnk;
}

unittest {
    import std.random, std.stdio, std.algorithm;
    import dkh.modint;
    void f(uint Mod)() {
        alias Mint = ModInt!Mod;
        alias Mat = SMatrix!(Mint, 3, 3);
        alias Vec = SMatrix!(Mint, 3, 1);
        static Mint rndM() {
            return Mint(uniform(0, Mod));
        }
        Mat m = matrix!(3, 3, (i, j) => rndM())();
        Mint sm = 0;
        auto idx = [0, 1, 2];
        do {
            Mint buf = 1;
            foreach (i; 0..3) {
                buf *= m[i, idx[i]];
            }
            sm += buf;
        } while (idx.nextEvenPermutation);
        idx = [0, 2, 1];
        do {
            Mint buf = 1;
            foreach (i; 0..3) {
                buf *= m[i, idx[i]];
            }
            sm -= buf;
        } while (idx.nextEvenPermutation);
        auto _m = m.dup;
        auto u = m.determinent;
        assert(sm == m.determinent);
        assert(_m == m);
    }
    void fD(uint Mod)() {
        alias Mint = ModInt!Mod;
        alias Mat = DMatrix!Mint;
        alias Vec = DMatrix!Mint;
        static Mint rndM() {
            return Mint(uniform(0, Mod));
        }
        Mat m = matrix!((i, j) => rndM())(3, 3);
        Mint sm = 0;
        auto idx = [0, 1, 2];
        do {
            Mint buf = 1;
            foreach (i; 0..3) {
                buf *= m[i, idx[i]];
            }
            sm += buf;
        } while (idx.nextEvenPermutation);
        idx = [0, 2, 1];
        do {
            Mint buf = 1;
            foreach (i; 0..3) {
                buf *= m[i, idx[i]];
            }
            sm -= buf;
        } while (idx.nextEvenPermutation);
        auto _m = m.dup;
        auto u = m.determinent;
        assert(sm == m.determinent);
        assert(_m == m);
    }    
    void fMod2() {
        alias Mint = ModInt!2;
        alias Mat = SMatrixMod2!(3, 3);
        alias Vec = SMatrixMod2!(3, 1);
        static Mint rndM() {
            return Mint(uniform(0, 2));
        }
        Mat m = matrixMod2!(3, 3, (i, j) => rndM())();
        Mint sm = 0;
        auto idx = [0, 1, 2];
        do {
            Mint buf = 1;
            foreach (i; 0..3) {
                buf *= m[i, idx[i]];
            }
            sm += buf;
        } while (idx.nextEvenPermutation);
        idx = [0, 2, 1];
        do {
            Mint buf = 1;
            foreach (i; 0..3) {
                buf *= m[i, idx[i]];
            }
            sm -= buf;
        } while (idx.nextEvenPermutation);
        auto _m = m.dup;
        auto u = m.determinent;
        if (sm != m.determinent) {
            writeln(sm, " ", m.determinent);
            foreach (i; 0..3) {
                foreach (j; 0..3) {
                    write(m[i, j], " ");
                }
                writeln;
            }
            writeln(m);
        }
        assert(sm == m.determinent);
        assert(_m == m);
    }    
    import dkh.stopwatch;
    writeln("Det: ", benchmark!(f!2, f!3, f!11, fD!2, fD!3, fD!11, fMod2)(10000)[].map!(a => a.toMsecs));
}


// m * v = r
Vec solveLinear(Mat, Vec)(Mat m, Vec r) {
    import std.conv, std.algorithm;
    size_t N = m.height, M = m.width;
    int c = 0;
    foreach (x; 0..M) {
        ptrdiff_t my = -1;
        foreach (y; c..N) {
            if (m[y, x].v) {
                my = y;
                break;
            }
        }
        if (my == -1) continue;
        m.swapLine(c, my);
        r.swapLine(c, my);
        foreach (y; 0..N) {
            if (c == y) continue;
            if (m[y, x].v == 0) continue;
            auto freq = m[y, x] / m[c, x];
            foreach (k; 0..M) {
                m[y, k] -= freq * m[c, k];
            }
            r[y, 0] -= freq * r[c, 0];
        }
        c++;
        if (c == N) break;
    }
    Vec v;
    foreach_reverse (y; 0..c) {
        ptrdiff_t f = -1;
        Mat.DataType sm;
        foreach (x; 0..M) {
            if (m[y, x].v && f == -1) {
                f = x;
            }
            sm += m[y, x] * v[x, 0];
        }
        v[f, 0] += (r[y, 0] - sm) / m[y, f];
    }
    return v;
}

unittest {
    import std.random, std.stdio;
    import dkh.modint;
    alias Mint = ModInt!(10^^9 + 7);
    alias Mat = SMatrix!(Mint, 3, 3);
    alias Vec = SMatrix!(Mint, 3, 1);
    static Mint rndM() {
        return Mint(uniform(0, 10^^9 + 7));
    }
    Mat m = matrix!(3, 3, (i, j) => rndM())();
    Vec x = matrix!(3, 1, (i, j) => rndM())();
    Vec r = m * x;
    Vec x2 = solveLinear(m, r);
    assert(m * x2 == r);
}

unittest {
    import std.random, std.stdio, std.algorithm;
    import dkh.modint;
    void f(uint Mod)() {
        alias Mint = ModInt!Mod;
        alias Mat = SMatrix!(Mint, 3, 3);
        alias Vec = SMatrix!(Mint, 3, 1);
        static Mint rndM() {
            return Mint(uniform(0, Mod));
        }
        Mat m = matrix!(3, 3, (i, j) => rndM())();
        Vec x = matrix!(3, 1, (i, j) => rndM())();
        Vec r = m * x;
        Mat _m = m.dup;
        Vec x2 = solveLinear(m, r);
        assert(m == _m);
        assert(m * x2 == r);
    }
    void fMod2() {
        alias Mint = ModInt!2;
        alias Mat = SMatrixMod2!(3, 3);
        alias Vec = SMatrixMod2!(3, 1);
        static Mint rndM() {
            return Mint(uniform(0, 2));
        }
        Mat m = matrixMod2!(3, 3, (i, j) => rndM())();
        Vec x = matrixMod2!(3, 1, (i, j) => rndM())();
        Vec r = m * x;
        Mat _m = m.dup;
        Vec x2 = solveLinear(m, r);
        assert(m == _m);
        assert(m * x2 == r);
    }
    import dkh.stopwatch;
    writeln("SolveLinear: ", benchmark!(f!2, f!3, f!11, fMod2)(10000)[].map!(a => a.toMsecs));
}
