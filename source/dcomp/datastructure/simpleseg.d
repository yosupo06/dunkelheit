module dcomp.datastructure.simpleseg;

// simpleなsegtree
// a op b op .. op x が求められる、遅延評価なし
// (T, op)はモノイドの必要がある、eはモノイド
struct SimpleSeg(T, alias op, T e) {
    const size_t n, sz;
    T[] d;
    @disable this();
    this(size_t n) {
        import std.algorithm : fill;
        import core.bitop : bsr;
        int lg = n.bsr;
        if ((2^^lg) < n) lg++;
        this.n = n;
        this.sz = 2^^lg;
        d = new T[](2*this.sz);
        d.fill(e);
    }
    T opIndex(int idx) {return d[idx+sz];}
    void opIndexAssign(T v, int idx) {
        import std.stdio : writeln;
        idx += sz;
        d[idx] = v;
        while (idx/2 >= 1) {
            idx /= 2;
            d[idx] = op(d[2*idx], d[2*idx+1]);
        }
    }
    //todo more beautiful?
    T sum(size_t a, size_t b, size_t l, size_t r, size_t k) {
        if (b <= l || r <= a) return e;
        if (a <= l && r <= b) return d[k];
        size_t md = (l+r)/2;
        return op(sum(a, b, l, md, 2*k),
            sum(a, b, md, r, 2*k+1));
    }
    //[a, b)
    T sum(size_t a, size_t b) {
        return sum(a, b, 0, sz, 1);
    }
    //todo formatspec?
    string toString() {
        import std.conv : to;
        return d[sz..sz+n].to!string;
    }
}
