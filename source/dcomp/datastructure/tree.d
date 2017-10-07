module dcomp.datastructure.tree;

import std.traits : isInstanceOf;

struct AVLNode(T, alias op) {
    alias Node = typeof(this);
    import std.math : abs;
    Node*[2] ch;
    int length, lv;
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
    Node* rot(int type) {
        assert(type == 0 || type == 1);
        auto buf = ch[type];
        ch[type] = buf.ch[1-type];
        buf.ch[1-type] = &this;
        update();
        buf.update();
        return buf;
    }
    Node* insert(in T v, int k) {
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
            ch[0] = ch[0].insert(v, k);
            type = 0;
        } else {
            ch[1] = ch[1].insert(v, k-ch[0].length);
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
    Node* removeAt(int k) {
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
    T at(int k) {
        assert(0 <= k && k < length);
        if (length == 1) return v;
        if (k < ch[0].length) return ch[0].at(k);
        return ch[1].at(k-ch[0].length);
    }
}
int binSearch(alias pred, N : AVLNode!(E, op), E, alias op)(N* n, E sm) {
    with (n) {
        if (length == 1) {
            if (pred(op(sm, v))) return 0;
            return 1;
        }
        if (pred(op(sm, ch[0].v))) return ch[0].binSearch!pred(sm);
        return ch[0].length + ch[1].binSearch!pred(op(sm, ch[0].v));
    }
}

struct Tree(alias Engine, T, alias op) {
    import std.math : abs;
    alias Node = Engine!(T, op);
    Node* tr;
    @property int length() {
        return (!tr ? 0 : tr.length);
    }
    this(T v) {
        tr = new Node(v);
    }
    void insert(T v, int k) {
        if (tr is null) {
            tr = new Node(v);
            return;
        }
        tr = tr.insert(v, k);
    }
    T opIndex(int k) {
        return tr.at(k);
    }
    void removeAt(int k) {
        tr = tr.removeAt(k);
    }
}

int binSearch(alias pred, T : Tree!(Engine, E, op), E, alias Engine, alias op)(T t, E e) {
    if (t.tr is null) return 0;
    return t.tr.binSearch!pred(e);
}
