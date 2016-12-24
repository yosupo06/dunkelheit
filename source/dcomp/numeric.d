module dcomp.numeric;

T lcm(T)(const T a, const T b) {
    import std.numeric : gcd, abs;
    return a / gcd(a,b) * b;
}

//a*T[0]+b*T[1]=T[2], T[2]=gcd
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
    auto opBinary(string op:"*")(ModInt r) {return make(cast(ulong)v*r.v%MD);}
    auto opBinary(string op:"/")(ModInt r) {return this*inv(r);}
    auto opOpAssign(string op)(ModInt r) {return mixin ("this=this"~op~"r");}
    static ModInt inv(ModInt x) {return ModInt(extGcd(x.v, MD)[0]);}
    string toString() {return v.to!string;}
}
