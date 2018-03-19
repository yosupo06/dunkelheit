module dkh.numeric.prime;

import std.traits;
import dkh.int128;

///
ulong ulongPowMod(U)(ulong x, U n, ulong md)
if (isIntegral!U || is(U == BigInt)) {
    x %= md;
    ulong r = 1;
    while (n) {
        if (n & 1) {
            r = mul128(r, x).mod128(md);
        }
        x = mul128(x, x).mod128(md);
        n >>= 1;
    }
    return r % md;
}

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

import dkh.numeric.primitive;

/// Millar-Rabin Test
bool isPrime(ulong n) {
    import dkh.int128;
    if (n <= 1) return false;
    if (n == 2) return true;
    if (n % 2 == 0) return false;
    ulong d = n-1;
    while (d % 2 == 0) d /= 2;
    ulong[] alist = [2,3,5,7,11,13,17,19,23,29,31,37];
    foreach (a; alist) {
        if (n <= a) break;
        ulong y = ulongPowMod(a, d, n);
        ulong t = d;
        while (t != n-1 && y != 1 && y != n-1) {
            y = mul128(y, y).mod128(n);
            t <<= 1;
        }
        if (y != n-1 && t % 2 == 0) {
            return false;
        }
    }
    return true;
}

///
unittest {
    assert(!isPrime(0));
    assert(!isPrime(1));
    assert(isPrime(2));
    assert(isPrime(10^^9 + 7));
}
