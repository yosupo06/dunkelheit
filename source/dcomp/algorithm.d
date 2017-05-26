module dcomp.algorithm;

import std.range.primitives;
import std.traits : isFloatingPoint, isIntegral;

/**
binary search

$(D [pred(l) = false, false, ..., false, true, true, ..., pred(r) = true]) $(BR)
このように, $(D pred(l) = false), $(D pred(r) = true), 単調性の3つを仮定する

小数の場合, 引数cntで反復回数を指定する

Returns:
    $(D pred(x) = true)なる最小のx
 */
T binSearch(alias pred, T)(T l, T r) if (isIntegral!T) {
    while (r-l > 1) {
        T md = (l+r)/2;
        if (!pred(md)) l = md;
        else r = md;
    }
    return r;
}

/// ditto
T binSearch(alias pred, T)(T l, T r, int cnt = 60) if (isFloatingPoint!T) {
    foreach (i; 0..cnt) {
        T md = (l+r)/2;
        if (!pred(md)) l = md;
        else r = md;
    }
    return r;
}

///
unittest {
    assert(binSearch!(x => x*x >= 100)(0, 20) == 10);
    assert(binSearch!(x => x*x >= 101)(0, 20) == 11);
    assert(binSearch!(x => true)(0, 20) == 1);
    assert(binSearch!(x => false)(0, 20) == 20);
}

/// 最小値探索関数
E minimum(alias pred = "a < b", Range, E = ElementType!Range)(Range range, E seed)
if (isInputRange!Range && !isInfinite!Range) {
    import std.algorithm, std.functional;
    return reduce!((a, b) => binaryFun!pred(a, b) ? a : b)(seed, range);
}

/// ditto
ElementType!Range minimum(alias pred = "a < b", Range)(Range range) {
    assert(!range.empty, "range must not empty");
    auto e = range.front; range.popFront;
    return minimum!pred(range, e);
}

///
unittest {
    assert(minimum([2, 1, 3]) == 1);
    assert(minimum!"a > b"([2, 1, 3]) == 3);
    assert(minimum([2, 1, 3], -1) == -1);
    assert(minimum!"a > b"([2, 1, 3], 100) == 100);
}

/// 最大値探索関数
E maximum(alias pred = "a < b", Range, E = ElementType!Range)(Range range, E seed)
if (isInputRange!Range && !isInfinite!Range) {
    import std.algorithm, std.functional;
    return reduce!((a, b) => binaryFun!pred(a, b) ? b : a)(seed, range);
}

/// ditto
ElementType!Range maximum(alias pred = "a < b", Range)(Range range) {
    assert(!range.empty, "range must not empty");
    auto e = range.front; range.popFront;
    return maximum!pred(range, e);
}

///
unittest {
    assert(maximum([2, 1, 3]) == 3);
    assert(maximum!"a > b"([2, 1, 3]) == 1);
    assert(maximum([2, 1, 3], 100) == 100);
    assert(maximum!"a > b"([2, 1, 3], -1) == -1);
}

/**
要素を回転させるRange
 */
Rotator!Range rotator(Range)(Range r) {
    return Rotator!Range(r);
}

/// ditto
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

///
unittest {
    import std.algorithm : equal, cmp;
    import std.array : array;
    int[] a = [1, 2, 3];
    assert(equal!equal(a.rotator, [
        [1, 2, 3],
        [2, 3, 1],
        [3, 1, 2],
    ]));
    int[] b = [3, 1, 4, 1, 5];
    assert(equal(b.rotator.maximum!"cmp(a, b) == -1", [5, 3, 1, 4, 1]));
}
