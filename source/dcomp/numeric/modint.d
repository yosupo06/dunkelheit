module dcomp.numeric.modint;

import dcomp.numeric.primitive;

struct ModInt(uint MD) if (MD < int.max) {
    import std.conv : to;
    uint v;
    this(int v) {this.v = (long(v)%MD+MD)%MD;}
    this(long v) {this.v = (v%MD+MD)%MD;}
    auto normS(uint x) {return (x<MD)?x:x-MD;}
    auto make(uint x) {ModInt m; m.v = x; return m;}
    auto opBinary(string op:"+")(ModInt r) {return make(normS(v+r.v));}
    auto opBinary(string op:"-")(ModInt r) {return make(normS(v+MD-r.v));}
    auto opBinary(string op:"*")(ModInt r) {return make( (long(v)*r.v%MD).to!uint );}
    auto opBinary(string op:"/")(ModInt r) {return this*inv(r);}
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

struct DModInt {
    import std.conv : to;
    uint MD, v;
    this(int v, uint md) {
        MD = md;
        this.v = ((long(v)%MD+MD)%MD).to!uint;
    }
    this(long v, uint md) {
        MD = md;
        this.v = ((v%MD+MD)%MD).to!uint;
    }
    auto normS(uint x) {return (x<MD)?x:x-MD;}
    auto make(uint x) {DModInt m; m.MD = MD; m.v = x; return m;}
    auto opBinary(string op:"+")(DModInt r) {
        assert(MD == r.MD);
        return make(normS(v+r.v));
    }
    auto opBinary(string op:"-")(DModInt r) {
        assert(MD == r.MD);
        return make(normS(v+MD-r.v));
    }
    auto opBinary(string op:"*")(DModInt r) {
        assert(MD == r.MD);
        return make((long(v)*r.v%MD).to!uint);
    }
    auto opBinary(string op:"/")(DModInt r) {
        assert(MD == r.MD);
        return this*inv(r);
    }
    auto opOpAssign(string op)(DModInt r) {return mixin ("this=this"~op~"r");}
    static DModInt inv(DModInt x) {
        return DModInt(extGcd!int(x.v, x.MD)[0], x.MD);
    }
    string toString() {return v.to!string;}
}

unittest {
    immutable MD = 10^^9 + 7;
    alias Mint = DModInt;
    //negative check
    assert(Mint(-1, MD).v == 10^^9 + 6);
    assert(Mint(-1L, MD).v == 10^^9 + 6);
    Mint a = Mint(48, MD);
    Mint b = Mint.inv(a);
    assert(b.v == 520833337);
    Mint c = Mint(15, MD);
    Mint d = Mint(3, MD);
    assert((c/d).v == 5);
}
