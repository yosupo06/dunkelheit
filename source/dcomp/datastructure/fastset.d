module dcomp.datastructure.fastset;

struct FastSet {
    import std.range : back;
    import core.bitop : bsr, bsf;
    size_t N, lg;
    ulong[][] seg;
    this(size_t N) {
        this.N = N;
        if (N == 0) {
            seg ~= new ulong[1];
            return;
        }
        while (true) {
            seg ~= new ulong[(N+63)/64];
            if (N == 1) break;
            N = (N+63)/64;
        }
        lg = seg.length;
    }
    bool empty() const {
        return seg.back[0] != 0;
    }
    bool opBinaryRight(string op : "in")(size_t i) {
        assert(0 <= i && i < N);
        size_t D = i/64, R = i%64;
        return (seg[0][D] & (1UL << R)) != 0;
    }
    void insert(size_t x) {
        foreach (i; 0..seg.length) {
            size_t D = x/64, R = x%64;
            seg[i][D] |= (1UL << R);
            x /= 64;
        }
    }
    void remove(size_t x) {
        foreach (i; 0..seg.length) {
            size_t D = x/64, R = x%64;
            seg[i][D] &= ~(1UL << R);
            if (i && seg[i-1][x] != 0) {
                seg[i][D] |= (1UL << R);
            }
            x /= 64;
        }
    }
    static struct Range {
        FastSet* fs;
        size_t lower, upper;
        size_t front() const {
            return fs.next(lower);
        }
        bool empty() const {
            return lower >= fs.N || upper <= fs.next(lower);
        }
        void popFront() {
            if (lower < upper) lower = fs.next(lower)+1;
        }
    }
    size_t next(size_t x) const {
        for (int i = 0; i < lg; i++) {
            size_t D = x/64, R = x%64;
            if (D == seg[i].length) break;
            ulong B = seg[i][D]>>R;
            if (!B) {
                x = x/64+1;
                continue;
            }
            //find
            x += bsf(B);
            for (int j = i-1; j >= 0; j--) {
                x *= 64;
                size_t D2 = x/64;
                x += bsf(seg[j][D2]);
            }
            return x;
        }
        return N;
    }
    Range lowerBound(size_t x) {
        return Range(&this, x, N);
    }
    Range upperBound(size_t x) {
        return Range(&this, x+1, N);
    }
    // // x以下最大の要素
    // int back(int x) {
    //     for (int i = 0; i < lg; i++) {
    //         if (x == -1) break;
    //         int D = x/64, R = x%64;
    //         ull B = seg[i][D]<<(63-R);
    //         if (!B) {
    //             x = x/64-1;
    //             continue;
    //         }
    //         //find
    //         x += bsr(B)-63;
    //         for (int j = i-1; j >= 0; j--) {
    //             x *= 64;
    //             int D = x/64;
    //             x += bsr(seg[j][D]);
    //         }
    //         return x;
    //     }
    //     return -1;
    // }    
}

unittest {
    auto fs = FastSet(10);
    fs.insert(1);
    fs.insert(5);
    fs.insert(6);
    fs.remove(5);
    assert(1 in fs);
    assert(2 !in fs);
    assert(5 !in fs);
    assert(6 in fs);
    import std.algorithm : equal;
    assert(equal([1, 6], fs.lowerBound(1)));
    assert(equal([6], fs.upperBound(1)));
}

