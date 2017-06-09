module dcomp.bigint;

import core.checkedint;
import dcomp.int128, dcomp.foundation;

void addMultiWord(in ulong[] l, in ulong[] r, ulong[] res) {
    auto N = res.length;
    bool of = false;
    foreach (i; 0..N) {
        bool nof;
        res[i] = addu(
            (i < l.length) ? l[i] : 0UL,
            (i < r.length) ? r[i] : 0UL, nof);
        if (of) {
            res[i]++;
            nof |= (res[i] == 0);
        }
        of = nof;
    }
}

unittest {
    import std.algorithm;
    auto l = [ulong.max, ulong.max, 0UL];
    auto r = [1UL];
    ulong[] res = new ulong[4];
    addMultiWord(l, r, res[]);
    assert(equal(res, [0UL, 0UL, 1UL, 0UL]));
}

// res = l-r
void subMultiWord(in ulong[] l, in ulong[] r, ulong[] res) {
    auto N = res.length;
    bool of = false;
    foreach (i; 0..N) {
        bool nof;
        res[i] = subu(
            (i < l.length) ? l[i] : 0UL,
            (i < r.length) ? r[i] : 0UL, nof);
        if (of) {
            res[i]--;
            nof |= (res[i] == ulong.max);
        }
        of = nof;
    }
}

unittest {
    import std.algorithm;
    auto l = [0UL, 0UL, 1UL];
    auto r = [1UL];
    ulong[] res = new ulong[4];
    subMultiWord(l, r, res[]);
    assert(equal(res, [ulong.max, ulong.max, 0UL, 0UL]));
}

void mulMultiWord(in ulong[] l, in ulong r, ulong[] res) {
    auto N = res.length;
    ulong ca;
    foreach (i; 0..N) {
        auto u = mul128((i < l.length) ? l[i] : 0UL, r);
        bool of;
        res[i] = addu(u[0], ca, of);
        if (of) u[1]++;
        ca = u[1];
    }
}

void shiftLeftMultiWord(in ulong[] l, int n, ulong[] res) {
    size_t N = res.length;
    int ws = n / 64;
    int bs = n % 64;
    import std.stdio;
    foreach_reverse (ptrdiff_t i; 0..N) {
        ulong b = (0 <= i-ws && i-ws < l.length) ? l[i-ws] : 0UL;
        if (bs == 0) res[i] = b;
        else {
            ulong a = (0 <= i-ws-1 && i-ws-1 < l.length) ? l[i-ws-1] : 0UL;
            res[i] = (b << bs) | (a >> (64-bs));
        }
    }
}

// std.algorithm.cmp, reverse ver
int cmpMultiWord(in ulong[] l, in ulong[] r) {    
    import std.algorithm : max;
    auto N = max(l.length, r.length);
    foreach_reverse (i; 0..N) {
        auto ld = (i < l.length) ? l[i] : 0UL;
        auto rd = (i < r.length) ? r[i] : 0UL;
        if (ld < rd) return -1;
        if (ld > rd) return 1;
    }
    return 0;
}


struct uintN(int N) if (N >= 1) {
    import core.checkedint;
    ulong[N] d;
    this(ulong x) { d[0] = x; }
    this(string s) {
        foreach (c; s) {
            this *= 10;
            this += uintN(c-'0');
        }
    }
    string toString() {
        import std.algorithm : reverse;
        char[] s;
        if (!this) return "0";
        while (this) {
            s ~= cast(char)('0' + (this % uintN(10))[0]);
            this /= uintN(10);
        }
        reverse(s);
        return s.idup;
    }
    ref inout(ulong) opIndex(int idx) inout { return d[idx]; }
    T opCast(T: bool)() {
        import std.algorithm, std.range;
        return d[].find!"a!=0".empty == false;
    }
    //bit op
    uintN opUnary(string op)() const if (op == "~") {
        uintN res;
        foreach (i; 0..N) {
            res[i] = ~d[i];
        }
        return res;
    }
    uintN opBinary(string op)(in uintN r) const
    if (op == "&" || op == "|" || op == "^") {
        uintN res;
        foreach (i; 0..N) {
            res[i] = mixin("d[i]" ~ op ~ "r.d[i]");
        }
        return res;
    }
    uintN opBinary(string op : "<<")(int n) const {
        if (N * 64 <= n) return uintN(0);
        uintN res;
        int ws = n / 64;
        int bs = n % 64;
        if (bs == 0) {
            res.d[ws..N][] = d[0..N-ws][];
            return res;
        }
        foreach_reverse (i; 1..N-ws) {
            res[i+ws] = (d[i] << bs) | (d[i-1] >> (64-bs));
        }
        res[ws] = (d[0] << bs);
        return res;
    }
    uintN opBinary(string op : ">>")(int n) const {
        if (N * 64 <= n) return uintN(0);
        uintN res;
        int ws = n / 64;
        int bs = n % 64;
        if (bs == 0) {
            res.d[0..N-ws][] = d[ws..N][];
            return res;
        }
        foreach_reverse (i; 0..N-ws-1) {
            res[i] = (d[i+ws+1] >> (64-bs)) | (d[i+ws] << bs);
        }
        res[N-ws-1] = (d[N-1] << bs);
        return res;
    }
    //cmp
    int opCmp(in uintN r) const {
        return cmpMultiWord(d, r.d);
    }

    //arit
    uintN opUnary(string op)() if (op == "++") {
        uintN res;
        bool of = true;
        foreach (i; 0..N) {
            if (of) {
                d[i]++;
                if (d[i]) of = false;
            }
        }
        return res;
    }
    uintN opUnary(string op)() if (op == "--") {
        return this -= uintN(1); //todo optimize
    }
    uintN opUnary(string op)() const if (op=="+" || op=="-") {
        if (op == "+") return this;
        if (op == "-") {
            return ++(~this);
        }
    }
    
    uintN opBinary(string op : "+")(in uintN r) const {
        uintN res;
        addMultiWord(d, r.d, res.d);
        return res;
    }
    uintN opBinary(string op : "-")(in uintN r) const {
        uintN res;
        subMultiWord(d, r.d, res.d);
        return res;
    }

    uintN opBinary(string op : "*")(in uintN r) const {
        uintN res;
        foreach (s; 0..N) {
            foreach (i; 0..s+1) {
                int j = s-i;
                auto u = mul128(d[i], r[j]);
                bool of;
                res[s] = addu(res[s], u[0], of);
                if (s+1 < N) {
                    if (of) {
                        res[s+1]++;
                        of = (res[s+1] == 0);
                    }
                    res[s+1] = addu(res[s+1], u[1], of);
                    if (s+2 < N && of) res[s+2]++;
                }
            }
        }
        return res;
    }
    uintN opBinary(string op : "*")(in ulong r) const {
        uintN res;
        mulMultiWord(d, r, res.d);
        return res;
    }

    uintN opBinary(string op : "/")(in uintN rr) const {
        import core.bitop;
        int up = -1, shift;
        foreach_reverse (i; 0..N) {
            if (rr[i]) {
                up = i;
                shift = 63 - bsr(rr[i]);
                break;
            }
        }
        assert(up != -1);

        ulong[N+1] l;
        l[0..N] = d[0..N];
        shiftLeftMultiWord(l, shift, l);
        auto r = (rr << shift);
        uintN res;
        foreach_reverse (i; 0..N-up) {
            //compare l[i, i+up+1] -> res[i]
            ulong pred = (r[up] == ulong.max) ? l[i+up+1] : div128([l[i+up], l[i+up+1]], r[up]+1);
            res[i] = pred;
            ulong[N+1] buf;
            mulMultiWord(r.d[], pred, buf); // r * pred
            subMultiWord(l[i..i+up+2], buf[], l[i..i+up+2]);
            while (cmpMultiWord(l[i..i+up+2], r.d[]) != -1) {
                res[i]++;
                subMultiWord(l[i..i+up+2], r.d[], l[i..i+up+2]);
            }
        }
        return res;
    }
    uintN opBinary(string op : "/")(in ulong r) const {
        return this / uintN(r);
    }
    uintN opBinary(string op : "%", T)(in T r) const {
        return this - this/r*r;
    }

    auto opOpAssign(string op, T)(in T r) {
        return mixin("this=this" ~ op ~ "r");
    }
}

unittest {
    alias Uint = uintN!20;
    import std.stdio, std.conv;
    auto x = Uint("31415926535897969393238462");
    auto y = Uint("1145141919810893");
    assert((x*y).to!string == "35975694425956177975650270094479894166566");
    assert((x/y).to!string == "27434090039");
}