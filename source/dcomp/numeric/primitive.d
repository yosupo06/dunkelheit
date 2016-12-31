module dcomp.numeric.primitive;

import std.traits;

T pow(T, U)(T x, U n, T e) {
    while (n) {
        if (n & 1) e *= x;
        x *= x;
        n /= 2;
    }
    return e;
}

T pow(T, U)(T x, U n) {
    return pow(x, n, T(1));
}

T lcm(T)(in T a, in T b) {
    import std.numeric : gcd, abs;
    return a / gcd(a,b) * b;
}

//a*T[0]+b*T[1]=T[2], T[2]=gcd
//todo: to binary extgcd
T[3] extGcd(T)(T a, T b) 
if (!isIntegral!T || isSigned!T)
{
    if (b==0) {
        return [1, 0, a];
    } else {
        auto e = extGcd(b, a%b);
        return [e[1], e[0]-a/b*e[1], e[2]];
    }
}
