module dkh.numeric.primitive;

import std.traits, std.bigint;

/// lcm
T lcm(T)(in T a, in T b) {
    import std.numeric : gcd;
    return a / gcd(a,b) * b;
}

///
unittest {
    assert(lcm(2, 4) == 4);
    assert(lcm(3, 5) == 15);
    assert(lcm(1, 1) == 1);
    assert(lcm(0, 100) == 0);
}

/// 高速累乗
Unqual!T pow(T, U)(T x, U n)
if (!isFloatingPoint!T && (isIntegral!U || is(U == BigInt))) {
    return pow(x, n, T(1));
}

/// ditto
Unqual!T pow(T, U, V)(T x, U n, V e)
if ((isIntegral!U || is(U == BigInt)) && is(Unqual!T == Unqual!V)) {
    Unqual!T b = x, v = e;
    Unqual!U m = n;
    while (m) {
        if (m & 1) v *= b;
        b *= b;
        m /= 2;
    }
    return v;
}

unittest {
    assert(pow(3, 5) == 243);
    assert(pow(3, 5, 2) == 486);
}

///
T powMod(T, U, V)(T x, U n, V md)
if (isIntegral!U || is(U == BigInt)) {
    T r = T(1);
    Unqual!U m = n;
    while (m) {
        if (m & 1) r = (r*x)%md;
        x = (x*x)%md;
        m >>= 1;
    }
    return r % md;
}

unittest {
    immutable int B = 3;
    assert(powMod(5, B, 100) == 25); //125 % 100
}

//todo: consider binary extgcd
/// a*T[0]+b*T[1]=T[2], T[2]=gcd
T[3] extGcd(T)(in T a, in T b) 
if (!isIntegral!T || isSigned!T) //unsignedはNG
{
    if (b==0) {
        return [T(1), T(0), a];
    } else {
        auto e = extGcd(b, a%b);
        return [e[1], e[0]-a/b*e[1], e[2]];
    }
}

///
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

/// calc inverse, (x * invMod(x)) % md == 1
T invMod(T)(T x, T md) {
    auto r = extGcd!T(x, md);
    assert(r[2] == 1);
    auto z = r[0];
    return (z % md + md) % md;
}

unittest {
    import std.numeric : gcd;
    foreach (i; 1..100) {
        foreach (j; 1..i) {
            if (gcd(i, j) != 1) continue;
            auto k = invMod(j, i);
            assert(j * k % i == 1);
        }
    }
}
