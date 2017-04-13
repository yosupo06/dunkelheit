module dcomp.fastdiv;

import dcomp.int128;

struct FastDivULong {
    ulong value, m;
    int lg;
    this(ulong value) {
        import core.bitop : bsr;
        this.value = value;
        if (value <= 1) return;
        lg = value.bsr;
        if (1UL<<lg != value) lg++;
        m = div128([0UL, (2UL<<(lg-1))-value], value)+1;
    }
    ulong opBinaryRight(string op:"/")(ulong x) const {
        assert(value != 0);
        if (value == 1) return x;
        ulong r;
        r = mul128(m, x)[1];
        r = (r + ((x-r)>>1)) >> (lg-1);
        return r;
    }
    ulong opBinaryRight(string op:"%")(ulong x) const {
        return x - x/this*value;
    }
}

unittest {
    ulong[] up;
    ulong[] down;
    up ~= 0;
    foreach (ulong i; 1..1000) {
        up ~= i;
        up ~= -i;
    }
    foreach (ulong i; 1..1000) {
        down ~= i;
        down ~= -i;
    }
    foreach (ulong i; down) {
        auto b = FastDivULong(i);
        foreach (ulong j; up) {
            assert(j/b == j/i);
            assert(j%b == j%i);
        }
    }
}
