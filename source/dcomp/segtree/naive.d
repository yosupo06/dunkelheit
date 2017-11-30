module dcomp.segtree.naive;

static struct NaiveSimple(T, alias opTT, T eT) {
    import std.conv : to;
    alias DataType = T;
    alias LazyType = void;
    alias BinSearch = binSearchNaive;
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

static struct Naive(T, L, alias opTT, alias opTL, alias opLL, T eT, L eL) {
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


int binSearchNaive(bool rev, alias pred, TR)(TR t, int a, int b) {
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
