module dcomp.tree;

import std.traits;

struct SimpleTree(T, alias _op, T _e) {
    import std.functional : binaryFun;
    alias op = binaryFun!_op;
    static immutable T e = _e;
    
    alias NP = Node*;
    /// Weighted balanced tree
    static struct Node {
        NP[2] ch;
        uint length;
        T v;
        this(in T v) {
            length = 1;
            this.v = v;
        }
        this(NP l, NP r) {
            ch = [l, r];
            update();
        }
        void update() {
            length = ch[0].length + ch[1].length;
            v = op(ch[0].v, ch[1].v);
        }
        NP rot(uint type) {
            // ty = 0: ((a, b), c) -> (a, (b, c))
            auto m = ch[type];
            ch[type] = m.ch[1-type];
            m.ch[1-type] = &this;
            update(); m.update();
            return m;
        }
        NP bal() {
            foreach (f; 0..2) {
                if (ch[f].length*2 > ch[1-f].length*5) {
                    if (ch[f].ch[1-f].length*2 > ch[1-f].length*5 ||
                        ch[f].ch[f].length*5 < (ch[f].ch[1-f].length+ch[1-f].length)*2) {
                        ch[f] = ch[f].rot(1-f);
                        update();
                    }
                    return rot(f);
                }
            }
            return &this;
        }
        NP insert(uint k, in T v) {
            assert(0 <= k && k <= length);
            if (length == 1) {
                if (k == 0) {
                    return new Node(new Node(v), &this);
                } else {
                    return new Node(&this, new Node(v));
                }
            }
            if (k < ch[0].length) {
                ch[0] = ch[0].insert(k, v);
            } else {
                ch[1] = ch[1].insert(k-ch[0].length, v);
            }
            update();
            return bal();
        }
        NP removeAt(uint k) {
            assert(0 <= k && k < length);
            if (length == 1) {
                return null;
            }
            if (k < ch[0].length) {
                ch[0] = ch[0].removeAt(k);
                if (ch[0] is null) return ch[1];
            } else {
                ch[1] = ch[1].removeAt(k-ch[0].length);
                if (ch[1] is null) return ch[0];
            }
            update();
            return bal();
        }
        const(T) at(uint k) const {
            assert(0 <= k && k < length);
            if (length == 1) return v;
            if (k < ch[0].length) return ch[0].at(k);
            return ch[1].at(k-ch[0].length);
        }
        void atAssign(uint k, in T x) {
            assert(0 <= k && k < length);
            if (length == 1) {
                v = x;
                return;
            }
            if (k < ch[0].length) ch[0].atAssign(k, x);
            else ch[1].atAssign(k-ch[0].length, x);
            update();
        }        
        const(T) sum(int a, int b) const {
            if (b <= 0 || length.to!int <= a) return e;
            if (a <= 0 && length.to!int <= b) return v;
            return op(ch[0].sum(a, b), ch[1].sum(a - ch[0].length, b - ch[0].length));
        }
        void check() {
            if (length == 1) return;
            assert(length == ch[0].length + ch[1].length);
            ch[0].check();
            ch[1].check();
            assert(ch[0].length*5 >= ch[1].length*2);
            assert(ch[1].length*5 >= ch[0].length*2);
        }
        void pr() {
            import std.stdio;
            if (length == 1) {
                writef("(%d)", v);
                return;
            }
            write("(");
            ch[0].pr();
            write(v);
            ch[1].pr();
            write(")");
        }
    }
    static NP merge(NP l, NP r, NP buf = null) {
        if (!l) return r;
        if (!r) return l;
        if (l.length*2 > r.length*5) {
            l.ch[1] = merge(l.ch[1], r, buf);
            l.update();
            return l.bal();
        } else if (l.length*5 < r.length*2) {
            r.ch[0] = merge(l, r.ch[0], buf);
            r.update();
            return r.bal();
        }
        if (buf == null) buf = new Node();
        buf.ch = [l, r];
        buf.update();
        return buf;
    }
    static NP[2] split(NP n, uint k) {
        if (!n) return [null, null];
        if (n.length == 1) {
            if (k == 0) return [null, n];
            else return [n, null];
        }
        NP[2] p;
        if (k < n.ch[0].length) {
            p = split(n.ch[0], k);
            p[1] = merge(p[1], n.ch[1], n);
        } else {
            p = split(n.ch[1], k - n.ch[0].length);
            p[0] = merge(n.ch[0], p[0], n);
        }
        return p;
    }
    import std.conv : to;
    Node* tr;
    this(T v) { tr = new Node(v); }
    this(Node* tr) { this.tr = tr; }
    this(in T[] v) {
        if (v.length == 0) return;
        if (v.length == 1) {
            tr = new Node(v[0]);
            return;
        }
        auto ltr = SimpleTree(v[0..$/2]);
        auto rtr = SimpleTree(v[$/2..$]);
        this = ltr.merge(rtr);
    }
    @property size_t length() const { return (!tr ? 0 : tr.length); }
    alias opDollar = length;
    
    void insert(size_t k, in T v) {
        assert(0 <= k && k <= length);
        if (tr is null) {
            tr = new Node(v);
            return;
        }
        tr = tr.insert(k.to!int, v);
    }
    void removeAt(size_t k) {
        assert(0 <= k && k < length);
        tr = tr.removeAt(k.to!int);
    }
    SimpleTree trim(size_t a, size_t b) {
        auto v = split(tr, b.to!uint);
        auto u = split(v[0], a.to!uint);
        tr = merge(u[0], v[1]);
        return SimpleTree(u[1]);
    }
    SimpleTree split(size_t k) {
        auto u = split(tr, k.to!uint);
        tr = u[0];
        return SimpleTree(u[1]);
    }
    ref SimpleTree merge(SimpleTree r) {
        tr = merge(tr, r.tr);
        return this;
    }
    const(T) opIndex(size_t k) {
        assert(0 <= k && k < length);
        return tr.at(k.to!int);
    }
    void opIndexAssign(in T x, size_t k) {
        return tr.atAssign(k.to!int, x);
    }
    struct Range {
        SimpleTree* eng;
        size_t start, end;
        @property T sum() {
            return eng.tr.sum(start.to!uint, end.to!uint);
        }
    }
    size_t[2] opSlice(size_t dim)(size_t start, size_t end) {
        assert(0 <= start && start <= end && end <= length());
        return [start, end];
    }
    Range opIndex(size_t[2] rng) {
        return Range(&this, rng[0].to!uint, rng[1].to!uint);
    }
    string toString() {
        //todo: more optimize
        import std.range : iota;
        import std.algorithm : map;
        import std.conv : to;
        string s;
        s ~= "Tree(";
        s ~= iota(length).map!(i => this[i]).to!string;
        s ~= ")";
        return s;
    }
    void check() {
        if (tr) tr.check();
    }
    void pr() {
        if (tr) tr.pr();
    }
}

import std.traits : isInstanceOf;

ptrdiff_t binSearchLeft(alias pred, T)(T t, ptrdiff_t _a, ptrdiff_t _b)
if(isInstanceOf!(SimpleTree, T)) {
    import std.conv : to;
    import std.traits : Unqual;
    int a = _a.to!int, b = _b.to!int;
    Unqual!(typeof(T.e)) x = T.e;
    if (pred(x)) return a-1;
    if (t.tr is null) return 0;
    
    alias op = T.op;
    int pos = a;
    void f(T.Node* n, int a, int b, int offset) {
        if (b <= offset || offset + n.length <= a) return;
        if (a <= offset && offset + n.length <= b && !pred(op(x, n.v))) {
            x = op(x, n.v);
            pos = offset + n.length;
            return;
        }
        if (n.length == 1) return;
        f(n.ch[0], a, b, offset);
        if (pos >= offset + n.ch[0].length) {
            f(n.ch[1], a, b, offset + n.ch[0].length);
        }
    }
    f(t.tr, a, b, 0);
    return pos;
}

ptrdiff_t binSearchRight(alias pred, T)(T t, ptrdiff_t a, ptrdiff_t b)
if(isInstanceOf!(SimpleTree, T)) {
    import std.conv : to;
    import std.traits : Unqual;
    int a = _a.to!int, b = _b.to!int;
    Unqual!(typeof(T.e)) x = T.e;
    if (pred(x)) return b;
    if (t.tr is null) return 0;

    alias op = T.op;
    int pos = b-1;
    void f(T.Node* n, int a, int b, int offset) {
        if (b <= offset || offset + n.length <= a) return;
        if (a <= offset && offset + n.length <= b && !pred(opTT(n.v, x))) {
            x = opTT(n.v, x);
            pos = offset - 1;
            return;
        }
        if (n.length == 1) return;
        f(n.ch[1], a, b, offset + n.ch[0].length);
        if (pos < offset + n.ch[0].length) {
            f(n.ch[0], a, b, offset);
        }
    }
    f(t.tr, a, b, 0);
    return pos;
}

unittest {
    import std.traits : AliasSeq;
    import std.random;
    import dcomp.modint;
    alias Mint = ModInt!(10^^9 + 7);
    auto rndM = (){ return Mint(uniform(0, 10^^9 + 7)); };
    void check() {
        alias T = SimpleTree!(Mint, "a+b", Mint(0));
        T t;
        Mint sm = 0;
        foreach (i; 0..100) {
            auto x = rndM();
            sm += x;
            t.insert(0, x);
        }
        assert(sm == t[0..$].sum);
    }
    check();
}

unittest {
    import std.random;
    import std.algorithm;
    import std.conv;
    import std.container.rbtree;
    import std.stdio;

    import dcomp.stopwatch;
    StopWatch sw; sw.start;
    auto nv = redBlackTree!(true, int)([]);
    alias T = SimpleTree!(int, max, int.min);
    auto tr = T();
    foreach (ph; 0..10000) {
        int ty = uniform(0, 2);
        if (ty == 0) {
            int x = uniform(0, 100);
            nv.insert(x);
            auto idx = tr.binSearchLeft!(y => x <= y)(0, tr.length);
            if (uniform(0, 2)) {
                auto tr2 = tr.trim(idx, tr.length); 
                tr.merge(T(x)).merge(tr2);
            } else {
                tr.insert(idx, x);
            }
        } else {
            if (!nv.length) continue;
            int i = uniform(0, nv.length.to!int);
            auto u = nv[];
            foreach (_; 0..i) u.popFront();
            assert(u.front == tr[i]);
            int x = tr[i];
            nv.removeKey(x);
            if (uniform(0, 2)) {
                tr.removeAt(i);
            } else {
                tr.trim(i, i+1);
            }
        }
        tr.check();
        assert(nv.length == tr.length);
    }
    writeln("Set TEST: ", sw.peek.toMsecs);
}
