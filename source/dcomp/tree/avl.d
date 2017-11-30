module dcomp.tree.avl;

import dcomp.tree.primitive;

struct AVLNode(T, alias op, T e) {
    alias Node = typeof(this);
    import std.algorithm : max;
    import std.math : abs;
    Node*[2] ch;
    uint length; int lv;
    T v;
    this(in T v) {
        length = 1;
        this.v = v;
    }
    this(Node* l, Node* r) {
        ch = [l, r];
        update();
    }
    void update() {
        length = ch[0].length + ch[1].length;
        lv = max(ch[0].lv, ch[1].lv) + 1;
        v = op(ch[0].v, ch[1].v);
    }
    //type0 : ((a, b), c) -> (a, (b, c))
    //type1 : (a, (b, c)) -> ((a, b), c)
    Node* rot(uint type) {
        assert(type == 0 || type == 1);
        auto buf = ch[type];
        ch[type] = buf.ch[1-type];
        buf.ch[1-type] = &this;
        update();
        buf.update();
        return buf;
    }
    Node* insert(uint k, in T v) {
        assert(0 <= k && k <= length);
        if (length == 1) {
            if (k == 0) {
                return new Node(new Node(v), &this);
            } else {
                return new Node(&this, new Node(v));
            }
        }

        int type;
        if (k < ch[0].length) {
            ch[0] = ch[0].insert(k, v);
            type = 0;
        } else {
            ch[1] = ch[1].insert(k-ch[0].length, v);
            type = 1;
        }
        update();
        if (abs(ch[0].lv - ch[1].lv) <= 1) return &this;
        if (lv - ch[type].ch[1-type].lv == 2 && lv - ch[type].ch[type].lv == 3) {
            ch[type] = ch[type].rot(1-type);
            update();
        }
        return rot(type);
    }
    Node* removeAt(uint k) {
        assert(0 <= k && k < length);
        if (length == 1) {
            return null;
        }
        int type;
        if (k < ch[0].length) {
            type = 0;
            ch[0] = ch[0].removeAt(k);
            if (ch[0] is null) return ch[1];
        } else {
            type = 1;
            ch[1] = ch[1].removeAt(k-ch[0].length);
            if (ch[1] is null) return ch[0];
        }
        update();
        if (abs(ch[0].lv - ch[1].lv) <= 1) return &this;
        if (lv - ch[1-type].ch[type].lv == 2 && lv - ch[1-type].ch[1-type].lv == 3) {
            ch[1-type] = ch[1-type].rot(type);
            update();
        }
        return rot(1-type);
    }
    //pred([a1, a2, ..., ai]) = 1 -> return i, search min i, assume pred([]) = 0 & assume pred(all+ex) = 1
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
}

import std.traits;

int binSearch(bool rev, alias pred, N)(N* r, int a, int b)
if (isInstanceOf!(AVLNode, N)) {
    alias args = TemplateArgsOf!N;
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

unittest {
    import dcomp.segtree.naive;
    import dcomp.tree.primitive;
    import dcomp.segtree.primitive;
    import dcomp.segtree.simpleseg;
    import std.traits : AliasSeq;
    alias TreeEngines = AliasSeq!(AVLNode);

    import std.random;

    void f(alias T)() {
        auto nav = SimpleSeg!(uint,
            (a, b) => (a | b),
            0U, NaiveSimple)(100);
        auto seg = Tree!(T, uint,
            (a, b) => (a | b),
            0U)();
        foreach (i; 0..100) {
            auto u = uniform!"[]"(0, 31);
            seg.insert(seg.length, u);
            nav[i] = u;
        }
        foreach (i; 0..100) {
            foreach (j; i..101) {
                foreach (x; 0..32) {
                    auto z = nav.binSearchLeft!((a) => a & x)(i, j);
                    auto w = seg.binSearchLeft!((a) => a & x)(i, j);
                    if (z != w) {
                        import std.stdio;
                        writeln(i, " ", j, " ", z, " ", w, " : ", nav[i], " ", seg[i], " ", x);
                    }
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
    foreach (E; TreeEngines) {
        f!AVLNode();
    }
}
