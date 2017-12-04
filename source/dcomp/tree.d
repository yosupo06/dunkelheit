module dcomp.tree;

import std.traits;

struct Tree(T, alias _op, T _e) {
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
                ch[0].check();
            } else {
                ch[1] = ch[1].removeAt(k-ch[0].length);
                if (ch[1] is null) return ch[0];
                ch[1].check();
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
        const(T) sum(int a, int b) const {
            if (b <= 0 || length <= a) return e;
            if (a <= 0 && length <= b) return v;
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
                write("(1)");
                return;
            }
            write("(");
            ch[0].pr();
            write(length);
            ch[1].pr();
            write(")");
        }
    }
    static NP merge(NP l, NP r, NP buf = null) {
        if (!l) return r;
        if (!r) return l;
        auto lsz = l.length, rsz = r.length;
        if (lsz*2 > rsz*5) {
            auto nl = l.ch[0];
            auto nr = merge(l.ch[1], r, buf);
/*            if (nl.length*5 >= nr.length*2) {
                l.ch[1] = nr;
                l.update();
                return l;
            }
            if (nr.ch[0].length*2 <= nr.ch[1].length*3) {
                l.ch[1] = nr.ch[0];
                l.update();
                nr.ch[0] = l;
                nr.update();
                return nr;
            }
            auto mid = nr.ch[0];
            nr.ch[0] = mid.ch[1];
            nr.update();
            l.ch[1] = mid.ch[0];
            l.update();
            mid.ch[0] = l; mid.ch[1] = nr;
            mid.update();
            return mid;*/
            l.ch[1] = nr;
            l.update();
            return l.bal();
        } else if (lsz*5 < rsz*2) {
            auto nl = merge(l, r.ch[0], buf);
            auto nr = r.ch[1];
            if (nl.length*2 <= nr.length*5) {
                r.ch[0] = nl;
                r.update();
                return r;
            }
            if (nl.ch[0].length*3 >= nl.ch[1].length*2) {
                r.ch[0] = nl.ch[1];
                r.update();
                nl.ch[1] = r;
                nl.update();
                return nl;
            }
            auto mid = nl.ch[1];
            nl.ch[1] = mid.ch[0];
            nl.update();
            r.ch[0] = mid.ch[1];
            r.update();
            mid.ch[0] = nl; mid.ch[1] = r;
            mid.update();
            return mid;
        }
        if (buf == null) buf = new Node();
        buf.ch[0] = l; buf.ch[1] = r;
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
    import std.math : abs;    
    Node* tr;

    this(T v) {
        tr = new Node(v);
    }
    this(Node* tr) {
        this.tr = tr;
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
    Tree trim(size_t a, size_t b) {
        auto v = split(tr, b.to!uint);
        auto u = split(v[0], a.to!uint);
        tr = merge(u[0], v[1]);
        return Tree(u[1]);
    }
    ref Tree merge(Tree r) {
        tr = merge(tr, r.tr);
        return this;
    }
    const(T) opIndex(size_t k) {
        assert(0 <= k && k < length);
        return tr.at(k.to!int);
    }
    struct Range {
        Tree* eng;
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
        import std.string : join;
        string s;
        s ~= "Tree(";
        s ~= iota(length).map!(i => this[i]).to!string;
        s ~= ")";
        return s;
    }
    void check() {
        if (tr) tr.check();
    }
}

import std.traits;
int binSearch(bool rev, alias pred, T, N)(N* r, int a, int b) {
    alias args = TemplateArgsOf!T;
    alias opTT = args[1];
    auto x = args[2];
    with (r) {
        static if (!rev) {
            //left
            if (pred(x)) return a-1;
            int pos = a;
            void f(N* n, int a, int b, int offset) {
                if (b <= offset || offset + n.length <= a) return;
                if (a <= offset && offset + n.length <= b && !pred(opTT(x, n.v))) {
                    x = opTT(x, n.v);
                    pos = offset + n.length;
                    return;
                }
                if (n.length == 1) return;
                f(n.ch[0], a, b, offset);
                if (pos >= offset + n.ch[0].length) {
                    f(n.ch[1], a, b, offset + n.ch[0].length);
                }
            }

            f(r, a, b, 0);
            return pos;
        } else {
            //right

            if (pred(x)) return b;
            int pos = b-1;
            void f(N* n, int a, int b, int offset) {
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

            f(r, a, b, 0);
            return pos;
        }
    }
}


import std.traits : isInstanceOf;
import std.conv : to;

ptrdiff_t binSearchLeft(alias pred, T)(T t, ptrdiff_t a, ptrdiff_t b)
if(isInstanceOf!(Tree, T)) {
    if (t.tr is null) {
        if (pred(T.e)) return -1;
        return 0;
    }
    return t.tr.binSearch!(false, pred, T)(a.to!int, b.to!int);
}

ptrdiff_t binSearchRight(alias pred, T)(T t, ptrdiff_t a, ptrdiff_t b)
if(isInstanceOf!(Tree, T)) {
    if (t.tr is null) {
        if (pred(T.e)) return 0;
        return -1;
    }
    return t.tr.binSearch!(true, pred, T)(a.to!int, b.to!int);
}

unittest {
    import std.traits : AliasSeq;
    import std.random;
    import dcomp.modint;
    alias Mint = ModInt!(10^^9 + 7);
    auto rndM = (){ return Mint(uniform(0, 10^^9 + 7)); };
    void check() {
        alias T = Tree!(Mint, "a+b", Mint(0));
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
    auto tr = Tree!(int, max, int.min)();
    foreach (ph; 0..10000) {
        int ty = uniform(0, 2);
        if (ty == 0) {
            int x = uniform(0, 100);
            nv.insert(x);
            tr.insert(tr.binSearchLeft!(y => x <= y)(0, tr.length), x);
        } else {
            if (!nv.length) continue;
            int i = uniform(0, nv.length.to!int);
            auto u = nv[];
            foreach (_; 0..i) u.popFront();
            assert(u.front == tr[i]);
            int x = tr[i];
            nv.removeKey(x);
            tr.removeAt(i);
        }
        tr.check();
        assert(nv.length == tr.length);
    }
    writeln("Set TEST: ", sw.peek.toMsecs);
}
