module dcomp.datastructure.lazyseg;

struct LazySeg(T, L, alias opTT, alias opTL, alias opLL, T eT, L eL) {
    const int n, sz;
    T[] d;
    L[] lz;
    @disable this();
    this(int n) {
        import std.algorithm : fill;
        import core.bitop : bsr;
        if (n == 0) return;
        int lg = n.bsr;
        if ((2^^lg) < n) lg++;
        this.n = n;
        this.sz = 2^^lg;
        d = new T[](2*this.sz); d[] = eT;
        lz = new L[](2*this.sz); lz[] = eL;
    }
    private void lzAdd(int k, L x) {
        d[k] = opTL(d[k], x);
        lz[k] = opLL(lz[k], x);
    }
    private void push(int k) {
        if (lz[k] == eL) return;
        lzAdd(2*k, lz[k]);
        lzAdd(2*k+1, lz[k]);
        lz[k] = eL;
    }
    T sum(int a, int b, int l, int r, int k) {
        if (b <= l || r <= a) return eT;
        if (a <= l && r <= b) return d[k];
        push(k);
        int md = (l+r)/2;
        return opTT(sum(a, b, l, md, 2*k),
            sum(a, b, md, r, 2*k+1));
    }
    T sum(int a, int b) {
        assert(0 <= a && a <= b && b <= n);
        return sum(a, b, 0, sz, 1);
    }
    void add(int a, int b, L x, int l, int r, int k) {
        if (b <= l || r <= a) return;
        if (a <= l && r <= b) {
            lzAdd(k, x);
            return;
        }
        push(k);
        int md = (l+r)/2;
        add(a, b, x, l, md, 2*k);
        add(a, b, x, md, r, 2*k+1);
        d[k] = opTT(d[2*k], d[2*k+1]);
    }
    void add(int a, int b, L x) {
        assert(0 <= a && a <= b && b <= n);
        add(a, b, x, 0, sz, 1);
    }
    @property int opDollar() const {return sz;}
    struct Range {
        LazySeg* seg;
        int start, end;
        @property T sum() {
            return seg.sum(start, end);
        }
    }
    int[2] opSlice(size_t dim)(int start, int end) {
        assert(0 <= start && start <= end && end <= sz);
        return [start, end];
    }
    Range opIndex(int[2] rng) {
        return Range(&this, rng[0], rng[1]);
    }
    void opIndexOpAssign(string op)(L x, int[2] rng) {
        add(rng[0], rng[1], x);
    }
}
