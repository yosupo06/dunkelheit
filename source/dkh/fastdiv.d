module dkh.fastdiv;

import dkh.foundation, dkh.int128;

/**
Barrett reductionを使用し、高速除算を行う。
ulongをこれで置き換えれば大体うまく動く。
 */
struct FastDivULong {
    const ulong value, m;
    const int lg;
    this(ulong value) {
        import core.bitop : bsr;
        this.value = value;
        assert(value);
        if (value <= 1) return;
        int _lg = value.bsr;
        if (1UL<<_lg != value) _lg++;
        lg = _lg;
        m = div128([0UL, (2UL<<(lg-1))-value], value)+1;
    }
    ulong opBinaryRight(string op:"/")(ulong x) const {
        if (value == 1) return x;
        ulong r;
        r = mul128(m, x)[1];
        r = (r + ((x-r)>>1)) >> (lg-1);
        return r;
    }
    ulong opBinaryRight(string op:"%")(ulong x) const {
        return x - (x/this)*value;
    }
}

///
unittest {
    assert(11 / FastDivULong(3) == 3);
    assert(11 % FastDivULong(3) == 2);
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
