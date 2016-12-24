module dcomp.prime;

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

T[] factorList(T)(T x) {
    T[] res;
    for (T i = 1; i*i <= x; i++) {
        while (x % i == 0) {
            res ~= i;
            x /= i;
        }
    }
    if (x > 1) res ~= x;
    // res is sorted!
    return res;
}