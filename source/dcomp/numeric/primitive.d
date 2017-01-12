module dcomp.numeric.primitive;

import std.traits;

T pow(T, U)(T x, U n) { return pow(x, n, T(1)); }
T pow(T, U)(T x, U n, T e) {
    while (n) {
        if (n & 1) e *= x;
        x *= x;
        n /= 2;
    }
    return e;
}

unittest {
    assert(pow(3, 5) == 243);
    assert(pow(3, 5, 2) == 486);
}

T lcm(T)(in T a, in T b) {
    import std.numeric : gcd;
    return a / gcd(a,b) * b;
}

unittest {
    assert(lcm(2, 4) == 4);
    assert(lcm(3, 5) == 15);
    assert(lcm(1, 1) == 1);
    assert(lcm(0, 100) == 0);
}

//a*T[0]+b*T[1]=T[2], T[2]=gcd
//todo: to binary extgcd
T[3] extGcd(T)(in T a, in T b) 
if (!isIntegral!T || isSigned!T) //unsignedはNG
{
    if (b==0) {
        return [1, 0, a];
    } else {
        auto e = extGcd(b, a%b);
        return [e[1], e[0]-a/b*e[1], e[2]];
    }
}

unittest {
    import std.numeric : gcd;
    foreach (i; 0..100) {
        foreach (j; 0..100) {
            auto e = extGcd(i, j);
            assert(e[2] == gcd(i, j));
            assert(e[0] * i + e[1] * j == e[2]);
        }
    }
}

T[] factTable(T)(size_t length) {
    import std.range : take, recurrence;
    import std.array : array;
    return T(1).recurrence!((a, n) => a[n-1]*T(n)).take(length).array;
}

// optimize
T[] invFactTable(T)(size_t length) {
    import std.algorithm : map, reduce;
    import std.range : take, recurrence, iota;
    import std.array : array;
    auto res = new T[length];
    res[$-1] = T(1) / iota(1, length).map!T.reduce!"a*b";
    foreach_reverse (i, v; res[0..$-1]) {
        res[i] = res[i+1] * T(i+1);
    }
    return res;
}

T[] invTable(T)(size_t length) {
    auto f = factTable!T(length);
    auto invf = invFactTable!T(length);
    auto res = new T[length];
    foreach (i; 1..length) {
        res[i] = invf[i] * f[i-1];
    }
    return res;
}
unittest {
    import std.stdio;
    import dcomp.numeric.modint;
    alias Mint = ModInt!(10^^9 + 7);
    auto r = factTable!Mint(20);
    Mint a = 1;
    assert(r[0] == Mint(1));
    foreach (i; 1..20) {
        a *= Mint(i);
        assert(r[i] == a);
    }
    auto p = invFactTable!Mint(20);
    foreach (i; 1..20) {
        assert((r[i]*p[i]).v == 1);
    }
}
