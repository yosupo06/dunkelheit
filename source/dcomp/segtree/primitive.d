module dcomp.segtree.primitive;

import std.conv : to;

struct SegTree(alias E, Args...) {
    import std.traits : ReturnType;
    alias Engine = E!Args;
    alias T = Engine.DataType;
    alias L = Engine.LazyType;

    Engine eng;

    this(size_t n) { eng = Engine(n.to!uint); }
    this(T[] first) { eng = Engine(first); }

    @property size_t length() const { return eng.length(); }
    @property size_t opDollar() const { return eng.length(); }
    
    struct Range {
        Engine* eng;
        size_t start, end;
        @property const(T) sum() {
            return eng.sum(start.to!uint, end.to!uint);
        }
    }
    const(T) opIndex(size_t k) {
        assert(0 <= k && k < eng.length());
        return eng.single(k.to!uint);
    }
    void opIndexAssign(T x, size_t k) {
        assert(0 <= k && k < eng.length());
        eng.singleSet(k.to!uint, x);
    }
    size_t[2] opSlice(size_t dim)(size_t start, size_t end) {
        assert(0 <= start && start <= end && end <= eng.length());
        return [start, end];
    }
    Range opIndex(size_t[2] rng) {
        return Range(&eng, rng[0].to!uint, rng[1].to!uint);
    }
    static if (!is(L == void)) {
        void opIndexOpAssign(string op : "+")(L x, size_t[2] rng) {
            eng.add(rng[0].to!uint, rng[1].to!uint, x);
        }
    }
}

import std.traits : isInstanceOf;

ptrdiff_t binSearchLeft(alias pred, TR)(TR t, ptrdiff_t a, ptrdiff_t b) 
if (isInstanceOf!(SegTree, TR)) {
    return TR.Engine.BinSearch!(false, pred)(t.eng, a.to!int, b.to!int);
}

ptrdiff_t binSearchRight(alias pred, TR)(TR t, ptrdiff_t a, ptrdiff_t b) 
if (isInstanceOf!(SegTree, TR)) {
    return TR.Engine.BinSearch!(true, pred)(t.eng, a.to!int, b.to!int);
}
