module dcomp.matrix;

/// 行列ライブラリ
struct SMatrix(T, size_t H, size_t W) {
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

    auto ref opIndex(size_t i1, size_t i2) {
        return data[i1][i2];
    }
    auto opBinary(string op:"+", R)(R r)
    if(height == R.height && width == R.width) {
        auto res = this;
        foreach (y; 0..height) foreach (x; 0..W) res[y, x] += r[y, x];
        return res;
    }
    auto opBinary(string op:"*", R)(R r)
    if(width == R.height) {
        auto res = SMatrix!(T, height, R.width)();
        foreach (y; 0..height) {
            foreach (x; 0..R.width) {
                foreach (k; 0..width) {
                    res[y, x] += this[y, k]*r[k, x];
                }
            }
        }
        return res;
    }
    auto opOpAssign(string op, T)(T r) {return mixin ("this=this"~op~"r");}    
}

/// ditto
struct DMatrix(T) {
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

    auto ref opIndex(size_t i1, size_t i2) {
        return data[i1*width+i2];
    }
    auto opBinary(string op:"+", R)(R r) {
        assert(height == R.height && width == R.width);
        auto res = this;
        foreach (y; 0..height) foreach (x; 0..width) res[y, x] += r[y, x];
        return res;
    }
    auto opBinary(string op:"*", R)(R r) {
        assert(width == R.height);
        auto res = DMatrix!(T)(height, R.width);
        foreach (y; 0..height) {
            foreach (x; 0..R.width) {
                foreach (k; 0..width) {
                    res[y, x] += this[y, k]*r[k, x];
                }
            }
        }
        return res;
    }
    auto opOpAssign(string op, T)(T r) {return mixin ("this=this"~op~"r");}    
}

///
unittest {
    import dcomp.numeric.primitive;
    auto mat = DMatrix!int(2, 2, [0, 1, 1, 1]);
    assert(pow(mat, 10, DMatrix!int(2, 2, [1, 0, 0, 1]))[0, 0] == 34); //Fib_10
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

auto determinent(Mat)(in Mat _m) {
    auto m = _m.dup;
    assert(m.height == m.width);
    import std.conv, std.algorithm;
    alias M = typeof(m[0, 0]);
    size_t N = m.height;
    M base = 1;
    foreach (i; 0..N) {
        if (m[i, i] == M(0)) {
            foreach (j; i+1..N) {
                if (m[j, i] != M(0)) {
                    foreach (k; 0..N) swap(m[i, k], m[j, k]);
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

unittest {
    import std.random, std.stdio, std.algorithm;
    import dcomp.modint;
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
    import std.datetime;
    writeln("Det: ", benchmark!(f!2, f!3, f!11)(10000)[].map!"a.msecs");
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
        foreach (i; 0..M) {
            swap(m[c, i], m[my, i]);
        }
        swap(r[c, 0], r[my, 0]);
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
        typeof(Vec[0, 0]) sm;
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
    import dcomp.modint;
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
