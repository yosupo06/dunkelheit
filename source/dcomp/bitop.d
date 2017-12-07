module dcomp.bitop;

public import core.bitop;

bool poppar(ulong v) {
    v^=v>>1; v^=v>>2;
    v&=0x1111111111111111UL;
    v*=0x1111111111111111UL;
    return ((v>>60) & 1) != 0;
}

static if (!__traits(compiles, popcnt(ulong.max))) {
    public import core.bitop : popcnt;
    int popcnt(ulong v) {
        return popcnt(cast(uint)(v)) + popcnt(cast(uint)(v>>32));
    }
}
