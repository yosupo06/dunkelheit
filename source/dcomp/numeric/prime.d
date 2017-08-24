module dcomp.numeric.prime;

/// xの約数一覧を返す
T[] divisorList(T)(T x) {
    import std.algorithm : sort;
    T[] res;
    for (T i = 1; i*i <= x; i++) {
        if (x%i == 0) {
            res ~= i;
            if (i*i != x) res ~= x/i;
        }
    }
    sort(res);
    return res;
}

///
unittest {
    import std.range, std.algorithm;
    assert(equal(divisorList(1), [1]));
    assert(equal(divisorList(2), [1, 2]));
    assert(equal(divisorList(4), [1, 2, 4]));
    assert(equal(divisorList(24), [1, 2, 3, 4, 6, 8, 12, 24]));
}

/// xの素因数一覧を返す
T[] factorList(T)(T x) {
    T[] res;
    for (T i = 2; i*i <= x; i++) {
        while (x % i == 0) {
            res ~= i;
            x /= i;
        }
    }
    if (x > 1) res ~= x;
    // res is sorted!
    return res;
}

///
unittest {
    import std.range, std.algorithm;
    assert(equal(factorList(1), new int[0]));
    assert(equal(factorList(2), [2]));
    assert(equal(factorList(4), [2, 2]));
    assert(equal(factorList(24), [2, 2, 2, 3]));
}
