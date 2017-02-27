module dcomp.numeric.primitive;

import std.traits;

T pow(T, U)(T x, U n) if (!isFloatingPoint!T && isIntegral!U) {
    return pow(x, n, T(1));
}

T pow(T, U)(T x, U n, T e) if (isIntegral!U) {
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
