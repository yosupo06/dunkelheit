module dcomp.memory;

MemoryPool _nowPool;

@property void nowPool(MemoryPool newPool) {
    _nowPool = newPool;
}
@property MemoryPool nowPool() {
    return _nowPool;
}

class MemoryPool {
    import core.memory : GC;
    import std.algorithm : max;

    static immutable Allign = 16;
    GC.BlkInfo[] blks;
    size_t e, idx, pos;
    this(size_t e) {
        this.e = e;
        idx = pos = 0;
    }
    void assign(size_t sz) {
        blks ~= GC.qalloc(sz);
    }
    void* malloc(size_t sz) {   
        sz = (sz + Allign-1) / Allign * Allign;
        while (idx < blks.length && blks[idx].size < pos + sz) {
            idx++; pos = 0;
        }

        if (idx == blks.length) {
            assign(max(e, sz)); pos = 0;
        }
        pos += sz;
        assert(pos <= blks[idx].size);
        return cast(void *)(cast(byte *)(blks[idx].base) + pos - sz);
    }
    void allFree() {
        idx = pos = 0;
    }
}
