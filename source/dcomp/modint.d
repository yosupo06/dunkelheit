module dcomp.modint;

import dcomp.numeric.primitive;

struct ModInt(uint MD) if (MD < int.max) {
    import std.conv : to;
    uint v;
    this(int v) {this(long(v));}
    this(long v) {this.v = (v%MD+MD)%MD;}
    static auto normS(uint x) {return (x<MD)?x:x-MD;}
    static auto make(uint x) {ModInt m; m.v = x; return m;}
    auto opBinary(string op:"+")(ModInt r) const {return make(normS(v+r.v));}
    auto opBinary(string op:"-")(ModInt r) const {return make(normS(v+MD-r.v));}
    auto opBinary(string op:"*")(ModInt r) const {return make( (long(v)*r.v%MD).to!uint );}
    auto opBinary(string op:"/")(ModInt r) const {return this*inv(r);}
    auto opOpAssign(string op)(ModInt r) {return mixin ("this=this"~op~"r");}
    static ModInt inv(ModInt x) {return ModInt(extGcd!int(x.v, MD)[0]);}
    string toString() {return v.to!string;}
}

unittest {
    static assert( is(ModInt!(uint(1000000000) * 2))); //not overflow
    static assert(!is(ModInt!(uint(1145141919) * 2))); //overflow!
    alias Mint = ModInt!(10^^9+7);
    // negative check
    assert(Mint(-1).v == 10^^9 + 6);
    assert(Mint(-1L).v == 10^^9 + 6);

    Mint a = 48;
    Mint b = Mint.inv(a);
    assert(b.v == 520833337);

    Mint c = Mint(15);
    Mint d = Mint(3);
    assert((c/d).v == 5);
}

struct DModInt(string name) {
    import std.conv : to;
    static uint MD;
    uint v;
    this(int v) {this(long(v));}
    this(long v) {this.v = ((v%MD+MD)%MD).to!uint;}
    auto normS(uint x) {return (x<MD)?x:x-MD;}
    auto make(uint x) {DModInt m; m.MD = MD; m.v = x; return m;}
    auto opBinary(string op:"+")(DModInt r) {
        return make(normS(v+r.v));
    }
    auto opBinary(string op:"-")(DModInt r) {
        return make(normS(v+MD-r.v));
    }
    auto opBinary(string op:"*")(DModInt r) {
        return make((long(v)*r.v%MD).to!uint);
    }
    auto opBinary(string op:"/")(DModInt r) {
        return this*inv(r);
    }
    auto opOpAssign(string op)(DModInt r) {return mixin ("this=this"~op~"r");}
    static DModInt inv(DModInt x) {
        return DModInt(extGcd!int(x.v, MD)[0]);
    }
    string toString() {return v.to!string;}
}

unittest {
    alias Mint = DModInt!("default");
    Mint.MD = 10^^9 + 7;
    //negative check
    assert(Mint(-1).v == 10^^9 + 6);
    assert(Mint(-1L).v == 10^^9 + 6);
    Mint a = Mint(48);
    Mint b = Mint.inv(a);
    assert(b.v == 520833337);
    Mint c = Mint(15);
    Mint d = Mint(3);
    assert((c/d).v == 5);
}

template isModInt(T) {
    const isModInt =
        is(T : ModInt!MD, uint MD) || is(S : DModInt!S, string s);
}


T[] factTable(T)(size_t length) if (isModInt!T) {
    import std.range : take, recurrence;
    import std.array : array;
    return T(1).recurrence!((a, n) => a[n-1]*T(n)).take(length).array;
}

// optimize
T[] invFactTable(T)(size_t length) if (isModInt!T) {
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

T[] invTable(T)(size_t length) if (isModInt!T) {
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
