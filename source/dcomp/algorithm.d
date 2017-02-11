module dcomp.algorithm;

import std.range.primitives;
import std.traits : isFloatingPoint, isIntegral;

//[0,0,0,...,1,1,1]で、初めて1となる場所を探す。pred(l) == 0, pred(r) == 1と仮定
T binSearch(alias pred, T)(T l, T r) if (isIntegral!T) {
    while (r-l > 1) {
        T md = (l+r)/2;
        if (!pred(md)) l = md;
        else r = md;
    }
    return r;
}

T binSearch(alias pred, T)(T l, T r, int cnt = 60) if (isFloatingPoint!T) {
    foreach (i; 0..cnt) {
        T md = (l+r)/2;
        if (!pred(md)) l = md;
        else r = md;
    }
    return r;
}

Rotator!Range rotator(Range)(Range r) {
    return Rotator!Range(r);
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
if (isInputRange!Range && !isInfinite!Range) {
    import std.algorithm, std.functional;
    return reduce!((a, b) => binaryFun!pred(a, b) ? a : b)(seed, range);
}

ElementType!Range minimum(alias pred = "a < b", Range)(Range range) {
    assert(!range.empty, "range must not empty");
    auto e = range.front; range.popFront;
    return minimum!pred(range, e);
}

E maximum(alias pred = "a < b", Range, E = ElementType!Range)(Range range, E seed)
if (isInputRange!Range && !isInfinite!Range) {
    import std.algorithm, std.functional;
    return reduce!((a, b) => binaryFun!pred(a, b) ? b : a)(seed, range);
}

ElementType!Range maximum(alias pred = "a < b", Range)(Range range) {
    assert(!range.empty, "range must not empty");
    auto e = range.front; range.popFront;
    return maximum!pred(range, e);
}

unittest {
    assert(minimum([2, 1, 3]) == 1);
    assert(minimum!"a > b"([2, 1, 3]) == 3);
    assert(minimum([2, 1, 3], -1) == -1);
    assert(minimum!"a > b"([2, 1, 3], 100) == 100);

    assert(maximum([2, 1, 3]) == 3);
    assert(maximum!"a > b"([2, 1, 3]) == 1);
    assert(maximum([2, 1, 3], 100) == 100);
    assert(maximum!"a > b"([2, 1, 3], -1) == -1);
}

bool[ElementType!Range] toMap(Range)(Range r) {
    import std.algorithm : each;
    bool[ElementType!Range] res;
    r.each!(a => res[a] = true);
    return res;
}
