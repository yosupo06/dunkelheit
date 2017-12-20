module dkh.modpoly;

import dkh.numeric.primitive;
import dkh.numeric.convolution;
import dkh.modint;
import dkh.container.stack;


struct ModPoly(uint MD) if (MD < int.max) {
    alias Mint = ModInt!MD;
    import std.algorithm : min, max, reverse;
    
    Stack!Mint d;
    void shrink() { while (!d.empty && d.back == Mint(0)) d.removeBack; }
    @property size_t length() const { return d.length; }
    @property inout(Mint)[] data() inout { return d.data; }
    
    this(in Mint[] v) {
        d = v.dup;
        shrink();
    }

    const(Mint) opIndex(size_t i) const {
        if (i < d.length) return d[i];
        return Mint(0);
    }
    void opIndexAssign(Mint x, size_t i) {
        if (i < d.length) {
            d[i] = x;
            shrink();
            return;
        }
        if (x == Mint(0)) return;
        while (d.length < i) d.insertBack(Mint(0));
        d.insertBack(x);
        return;
    }

    ModPoly opBinary(string op : "+")(in ModPoly r) const {
        size_t N = length, M = r.length;
        Mint[] res = new Mint[max(N, M)];
        foreach (i; 0..max(N, M)) res[i] = this[i] + r[i];
        return ModPoly(res);
    }
    ModPoly opBinary(string op : "-")(in ModPoly r) const {
        size_t N = length, M = r.length;
        Mint[] res = new Mint[max(N, M)];
        foreach (i; 0..max(N, M)) res[i] = this[i] - r[i];
        return ModPoly(res);
    }
    ModPoly opBinary(string op : "*")(in ModPoly r) const {
        size_t N = length, M = r.length;
        if (min(N, M) == 0) return ModPoly();
        return ModPoly(multiply(data, r.data));
    }
    ModPoly opBinary(string op : "*")(in Mint r) const {
        Mint[] res = new Mint[length];
        foreach (i; 0..length) res[i] = this[i]*r;
        return ModPoly(res);
    }
    ModPoly opBinary(string op : "/")(in ModPoly r) const {
        size_t B = max(1, length, r.length);
        return divWithInv(r.inv(B), B);
    }
    ModPoly opBinary(string op : "%")(in ModPoly r) const {
        return *this - y * div(y);
    }
    ModPoly opBinary(string op : "<<")(size_t n) const {
        Mint[] res = new Mint[n+length];
        foreach (i; 0..length) res[i+n] = this[i];
        return ModPoly(res);
    }
    ModPoly opBinary(string op : ">>")(size_t n) const {
        if (length <= n) return ModPoly();
        Mint[] res = new Mint[length-n];
        foreach (i; n..length) res[i-n] = this[i];
        return ModPoly(res);
    }
    ModPoly opOpAssign(string op)(in ModPoly r) {
        return mixin("this=this"~op~"r");
    }

    ModPoly strip(size_t n) const {
        auto res = d.data.dup;
        res = res[0..min(n, length)];
        return ModPoly(res);
    }
    ModPoly divWithInv(in ModPoly ir, size_t B) const {
        return (this * ir) >> (B-1);
    }
    ModPoly remWithInv(in ModPoly r, in ModPoly ir, size_t B) const {
        return this - r * divWithInv(ir, B);
    }
    ModPoly rev(ptrdiff_t n = -1) const {
        auto res = d.data.dup;
        if (n != -1) res = res[0..n];
        reverse(res);
        return ModPoly(res);
    }
    ModPoly inv(size_t n) const {
        assert(length >= 1);
        assert(n >= length-1);
        ModPoly c = rev();
        ModPoly d = ModPoly([Mint(1)/c[0]]);
        for (ptrdiff_t i = 1; i+length-2 < n; i *= 2) {
            d = (d * (ModPoly([Mint(2)]) - c*d)).strip(2*i);
        }
        return d.rev(n+1-length);
    }

    string toString() {
        import std.conv : to;
        import std.range : join;
        string[] l = new string[length];
        foreach (i; 0..length) {
            l[i] = (this[i]).toString ~ "x^" ~ i.to!string;
        }
        return l.join(" + ");
    }
}

ModPoly!MD nthMod(uint MD)(in ModPoly!MD mod, ulong n) {
    import core.bitop : bsr;
    alias Mint = ModInt!MD;
    assert(mod.length);
    size_t B = mod.length * 2 - 1;
    auto modInv = mod.inv(B);
    auto p = ModPoly!MD([Mint(1)]);
    if (n == 0) return p;
    auto m = bsr(n);
    foreach_reverse(i; 0..m+1) {
        if (n & (1L<<i)) {
            p = (p<<1).remWithInv(mod, modInv, B);
        }
        if (i) {
            p = (p*p).remWithInv(mod, modInv, B);
        }
    }
    return p;
}

ModPoly!MD berlekampMassey(uint MD)(in ModInt!MD[] s) {
    alias Mint = ModInt!MD;
    Mint[] b = [Mint(-1)], c = [Mint(-1)];
    Mint y = 1;
    foreach (ed; 1..s.length+1) {
        auto L = c.length, M = b.length;
        Mint x = 0;
        foreach (i; 0..L) {
            x += c[i] * s[ed-L+i];
        }
        b ~= Mint(0); M++;
        if (x == Mint(0)) {
            continue;
        }
        auto freq = x/y;
        if (L < M) {
            auto tmp = c;
            import std.range : repeat, take, array;
            c = Mint(0).repeat.take(M-L).array ~ c;
            foreach (i; 0..M) {
                c[M-1-i] -= freq*b[M-1-i];
            }
            b = tmp;
            y = x;
        } else {
            foreach (i; 0..M) {
                c[L-1-i] -= freq*b[M-1-i];
            }
        }
    }
    return ModPoly!MD(c);
}

unittest {
    import std.stdio;
    static immutable int MD = 7;
    alias Mint = ModInt!MD;
    alias MPol = ModPoly!MD;
    auto p = MPol(), q = MPol();
    p[0] = Mint(3); p[1] = Mint(2);
    q[0] = Mint(3); q[1] = Mint(2);
    writeln(p+q);
    writeln(p-q);
    writeln(p*q);
}

unittest {
    import std.stdio;
    static immutable int MD = 7;
    alias Mint = ModInt!MD;
    alias MPol = ModPoly!MD;
    auto p = MPol();
    p[10] = Mint(1);
    assert(p.length == 11);    
}
