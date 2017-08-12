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
    this(size_t h, size_t w, T[] d) {
        this(h, w);
        assert(d.length == h*w);
        data[] = d[];
    }

    @property size_t height() {return h;}
    @property size_t width() {return w;}

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


// m * v = r
Vec solveLinear(Mat, Vec)(Mat m, Vec r) {
    import std.conv, std.algorithm;
    alias Mod2 = typeof(Vec[0, 0]);
    int N = m.height.to!int, M = m.width.to!int;
    int c = 0;
    foreach (x; 0..M) {
        int my = -1;
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
        int f = -1;
        Mod2 sm;
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
