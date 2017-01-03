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


E minimum(alias pred = "a < b", Range, E = ElementType!Range)(Range range, E seed)
if (isInputRange!Range && !isInfinite!Range && !is(CommonType!(ElementType!Range, E) == void)) {
    import std.functional;
    while (!range.empty) {
        if (binaryFun!pred(range.front, seed)) {
            seed = range.front;
        }
        range.popFront;
    }
    return seed;
}

ElementType!Range minimum(alias pred = "a < b", Range)(Range range)
if (isInputRange!Range && !isInfinite!Range) {
    assert(!range.empty, "range must not empty");
    auto e = range.front; range.popFront;
    return minimum!pred(range, e);
}

unittest {
    assert(minimum([2, 1, 3]) == 1);
    assert(minimum!"a > b"([2, 1, 3]) == 3);
    assert(minimum([2, 1, 3], -1) == -1);
    assert(minimum!"a > b"([2, 1, 3], 100) == 100);
}

bool[ElementType!Range] toMap(Range)(Range r) {
    import std.algorithm : each;
    bool[ElementType!Range] res;
    r.each!(a => res[a] = true);
    return res;
}
