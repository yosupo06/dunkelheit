module dcomp.modint;

import dcomp.numeric.primitive;

/**
自動mod取り構造体
 */
struct ModInt(uint MD) if (MD < int.max) {
    import std.conv : to;
    uint v;
    this(int v) {this(long(v));}
    this(long v) {this.v = (v%MD+MD)%MD;}
    static auto normS(uint x) {return (x<MD)?x:x-MD;}
    static auto make(uint x) {ModInt m; m.v = x; return m;}
    /// 整数型と同じように演算可能 割り算のみ遅い
    auto opBinary(string op:"+")(ModInt r) const {return make(normS(v+r.v));}
    /// ditto
    auto opBinary(string op:"-")(ModInt r) const {return make(normS(v+MD-r.v));}
    /// ditto
    auto opBinary(string op:"*")(ModInt r) const {return make((long(v)*r.v%MD).to!uint);}
    /// ditto
    auto opBinary(string op:"/")(ModInt r) const {return this*inv(r);}
    auto opOpAssign(string op)(ModInt r) {return mixin ("this=this"~op~"r");}
    /// xの逆元を求める
    static ModInt inv(ModInt x) {return ModInt(extGcd!int(x.v, MD)[0]);}
    string toString() {return v.to!string;}
}

///
unittest {
    alias Mint = ModInt!(107);
    assert((Mint(100) + Mint(10)).v == 3);
    assert(( Mint(10) * Mint(12)).v == 13);
    assert((  Mint(1) /  Mint(2)).v == 108/2);
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

/**
自動mod取り構造体(実行時mod指定)
 */
struct DModInt(string name) {
    import std.conv : to;
    static uint MD;
    uint v;
    this(int v) {this(long(v));}
    this(long v) {this.v = ((v%MD+MD)%MD).to!uint;}
    static auto normS(uint x) {return (x<MD)?x:x-MD;}
    static auto make(uint x) {DModInt m; m.MD = MD; m.v = x; return m;}
    /// 整数型と同じように演算可能 割り算のみ遅い
    auto opBinary(string op:"+")(DModInt r) const {return make(normS(v+r.v));}
    /// ditto
    auto opBinary(string op:"-")(DModInt r) const {return make(normS(v+MD-r.v));}
    /// ditto
    auto opBinary(string op:"*")(DModInt r) const {return make((long(v)*r.v%MD).to!uint);}
    /// ditto
    auto opBinary(string op:"/")(DModInt r) const {return this*inv(r);}
    auto opOpAssign(string op)(DModInt r) {return mixin ("this=this"~op~"r");}
    /// xの逆元を求める
    static DModInt inv(DModInt x) {
        return DModInt(extGcd!int(x.v, MD)[0]);
    }
    string toString() {return v.to!string;}
}

///
unittest {
    alias Mint1 = DModInt!"mod1";
    alias Mint2 = DModInt!"mod2";
    Mint1.MD = 7;
    Mint2.MD = 9;
    assert((Mint1(5)+Mint1(5)).v == 3); // (5+5) % 7
    assert((Mint2(5)+Mint2(5)).v == 1); // (5+5) % 9    
}

unittest {
    alias Mint = DModInt!"default";
    Mint.MD = 10^^9 + 7;
    //negative check
    assert(Mint(-1).v == 10^^9 + 6);
    assert(Mint(-1L).v == 10^^9 + 6);
    const Mint a = Mint(48);
    const Mint b = Mint.inv(a);
    assert((a*b).v == 1);
    assert(b.v == 520833337);
    Mint c = Mint(15);
    Mint d = Mint(3);
    assert((c/d).v == 5);
    c += d;
    assert(c.v == 18);
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
