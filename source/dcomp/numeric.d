module dcomp.numeric;


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
T[3] extGcd(T)(T a, T b) {
    if (b==0) {
        return [1, 0, a];
    } else {
        auto e = extGcd(b, a%b);
        return [e[1], e[0]-a/b*e[1], e[2]];
    }
}

struct ModInt(uint MD) {
    import std.conv : to;
    uint v;
    this(int v) {this.v = (v%MD+MD)%MD;}
    this(long v) {this.v = (v%MD+MD)%MD;}
    auto normS(uint x) {return (x<MD)?x:x-MD;}
    auto make(uint x) {ModInt m; m.v = x; return m;}
    auto opBinary(string op:"+")(ModInt r) {return make(normS(v+r.v));}
    auto opBinary(string op:"-")(ModInt r) {return make(normS(v+MD-r.v));}
    auto opBinary(string op:"*")(ModInt r) {return make((v.to!long*r.v%MD).to!uint);}
    auto opBinary(string op:"/")(ModInt r) {return this*inv(r);}
    auto opOpAssign(string op)(ModInt r) {return mixin ("this=this"~op~"r");}
    static ModInt inv(ModInt x) {return ModInt(extGcd(x.v, MD)[0]);}
    string toString() {return v.to!string;}
}

// f([10]) = [1*] 
// &演算での畳み込みを内積に変換する
T[] zeta(T)(T[] v, bool rev) {
    import core.bitop : bsr;
    int n = bsr(v.length);
    assert(1<<n == v.length);
    foreach (fe; 0..n) {
        foreach (i, _; v) {
            if (i & (1<<fe)) continue;
            if (!rev) {
                v[i] += v[i|(1<<fe)];
            } else {
                v[i] -= v[i|(1<<fe)];
            }
        }
    }
    return v;
}

// xor演算での畳み込みを内積に変換する、サイズ2のFFT
T[] hadamard(T)(T[] v, bool rev) {
    import core.bitop : bsr;
    int n = bsr(v.length);
    assert(1<<n == v.length);
    foreach (fe; 0..n) {
        foreach (i, _; v) {
            if (i & (1<<fe)) continue;
            auto l = v[i], r = v[i|(1<<fe)];
            if (!rev) {
                v[i] = l+r;
                v[i|(1<<fe)] = l-r;
            } else {
                v[i] = (l+r)/2;
                v[i|(1<<fe)] = (l-r)/2;
            }
        }
    }
    return v;
}
