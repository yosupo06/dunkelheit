module dcomp.bitop;

public import core.bitop;

static if (!__traits(compiles, popcnt(ulong.max))) {
    public import core.bitop : popcnt;
    int popcnt(ulong v) {
        return popcnt(cast(uint)(v)) + popcnt(cast(uint)(v>>32));
    }
}

/// poppar(v) == popcnt(v) % 2
bool poppar(uint v) {
    v^=v>>1; v^=v>>2;
    v&=0x11111111U;
    v*=0x11111111U;
    return ((v>>28) & 1) != 0;
}

/// ditto
bool poppar(ulong v) {
    v^=v>>1; v^=v>>2;
    v&=0x1111111111111111UL;
    v*=0x1111111111111111UL;
    return ((v>>60) & 1) != 0;
}

///
unittest {
    import std.random;
    foreach (i; 0..100) {
        uint v = uniform!"[]"(0U, uint.max);
        assert(poppar(v) == popcnt(v) % 2);
    }
    foreach (i; 0..100) {
        ulong v = uniform!"[]"(0UL, ulong.max);
        assert(poppar(v) == popcnt(v) % 2);
    }
}
