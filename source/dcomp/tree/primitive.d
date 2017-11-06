module dcomp.tree.primitive;

struct Tree(alias E, T, alias opTT, T _e) {
    immutable static T e = _e;
    import std.functional : binaryFun;
    import std.conv : to;
    import std.math : abs;    
    alias Engine = E!(T, binaryFun!opTT, e);
    Engine* tr;

    this(T v) {
        tr = new Engine(v);
    }

    @property size_t length() const { return (!tr ? 0 : tr.length); }
    alias opDollar = length;
    
    void insert(size_t k, in T v) {
        assert(0 <= k && k <= length);
        if (tr is null) {
            tr = new Engine(v);
            return;
        }
        tr = tr.insert(k.to!int, v);
    }
    const(T) opIndex(size_t k) {
        assert(0 <= k && k < length);
        return tr.at(k.to!int);
    }
    void removeAt(size_t k) {
        assert(0 <= k && k < length);
        tr = tr.removeAt(k.to!int);
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
}

import std.traits : isInstanceOf;
import std.conv : to;

ptrdiff_t binSearchLeft(alias pred, T)(T t, ptrdiff_t a, ptrdiff_t b)
if(isInstanceOf!(Tree, T)) {
    if (t.tr is null) {
        if (pred(T.e)) return -1;
        return 0;
    }
    import dcomp.tree.avl;
    pragma(msg, typeof(t.tr), isInstanceOf!(AVLNode, typeof(t.tr)));
    return t.tr.binSearch!(false, pred)(a.to!int, b.to!int);
}

ptrdiff_t binSearchRight(alias pred, T)(T t, ptrdiff_t a, ptrdiff_t b)
if(isInstanceOf!(Tree, T)) {
    if (t.tr is null) {
        if (pred(T.e)) return 0;
        return -1;
    }
    import dcomp.tree.avl;
    return t.tr.binSearch!(true, pred)(a.to!int, b.to!int);
}
