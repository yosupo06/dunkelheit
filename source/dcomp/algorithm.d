module dcomp.algorithm;

//[0,0,0,...,1,1,1]で、初めて1となる場所を探す。pred(l) == 0, pred(r) == 1と仮定
T binSearch(alias pred, T)(T l, T r) {
    while (r-l > 1) {
        T md = (l+r)/2;
        if (!pred(md)) l = md;
        else r = md;
    }
    return r;
}

import std.range.primitives;

Rotator!Range rotator(Range)(Range r)
if (isForwardRange!Range && hasLength!Range) {
    return typeof(return)(r);
}

struct Rotator(Range)
if (isForwardRange!Range && hasLength!Range) {
    size_t cnt;
    Range start, now;
    this(Range r) {
        cnt = 0;
        start = r.save;
        now = r.save;
    }
    this(this) {
        start = start.save;
        now = now.save;
    }
    @property bool empty() {
        return now.empty;
    }
    @property auto front() {
        assert(!now.empty);
        import std.range : take, chain;
        return chain(now, start.take(cnt));
    }
    @property Rotator!Range save() {
        return this;
    }
    void popFront() {
        cnt++;
        now.popFront;
    }
}
