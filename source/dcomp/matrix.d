module dcomp.matrix;

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
