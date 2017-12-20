module dkh.datastructure.fastset;

/**
almost same bool[int], except key range is stricted
 */
struct FastSet {
    import std.range : back;
    import core.bitop : bsr, bsf;
    private size_t n, len;
    ulong[][] seg;
    /// make set for [0, 1, ..., n-1]
    this(size_t n) {
        if (n == 0) n = 1;
        this.n = n;
        while (true) {
            seg ~= new ulong[(n+63)/64];
            if (n == 1) break;
            n = (n+63)/64;
        }
    }
    bool empty() const { return seg.back[0] != 0; } ///
    size_t length() const { return len; } /// count true

    bool opBinaryRight(string op : "in")(size_t i) {
        assert(i < n);
        //todo: consider bitop.bt
        size_t D = i/64, R = i%64;
        return (seg[0][D] & (1UL << R)) != 0;
    } ///
    void insert(size_t x) {
        if (x in this) return;
        len++;
        foreach (i; 0..seg.length) {
            size_t D = x/64, R = x%64;
            seg[i][D] |= (1UL << R);
            x /= 64;
        }
    } ///
    void remove(size_t x) {
        if (x !in this) return;
        len--;
        size_t D = x/64, R = x%64;
        seg[0][D] &= ~(1UL << R);
        foreach (i; 1..seg.length) {
            x /= 64;
            if (seg[i-1][x]) break;
            D = x/64; R = x%64;
            seg[i][D] &= ~(1UL << R);
        }
    } ///
    /// return minimum element that isn't less than x
    ptrdiff_t next(ptrdiff_t x) const {
        if (x < 0) x = 0;
        if (n <= x) return n;
        foreach (i; 0..seg.length) {
            if (x == seg[i].length * 64) break;
            size_t D = x/64, R = x%64;
            ulong B = seg[i][D]>>R;
            if (!B) {
                x = x/64+1;
                continue;
            }
            //find
            x += bsf(B);
            foreach_reverse (j; 0..i) {
                x *= 64;
                x += bsf(seg[j][x/64]);
            }
            return x;
        }
        return n;
    }
    /// return maximum element that isn't greater than x
    ptrdiff_t prev(ptrdiff_t x) const {
        if (n <= x) x = n-1;
        if (x < 0) return -1;
        foreach (i; 0..seg.length) {
            if (x == -1) break;
            size_t D = x/64, R = x%64;
            ulong B = seg[i][D]<<(63-R);
            if (!B) {
                x = x/64-1;
                continue;
            }
            //find
            x += bsr(B)-63;
            foreach_reverse (j; 0..i) {
                x *= 64;
                x += bsr(seg[j][x/64]);
            }
            return x;
        }
        return -1;
    }
    
    /// return range that contain less than x
    Range lowerBound(ptrdiff_t x) {
        return Range(&this, next(0), prev(x-1));
    }
    /// return range that contain greater than x
    Range upperBound(ptrdiff_t x) {
        return Range(&this, next(x+1), prev(n-1));
    }
    /// 
    Range opIndex() {
        return Range(&this, next(0), prev(n-1));
    }
    /// bidirectional range
    static struct Range {
        FastSet* fs;
        ptrdiff_t lower, upper;

        @property bool empty() const { return upper < lower; }

        size_t front() const { return lower; }
        size_t back() const { return upper; }
        void popFront() {
            assert(!empty);
            lower = fs.next(lower+1);
        }
        void popBack() {
            assert(!empty);
            upper = fs.prev(upper-1);
        }
    }
}

///
unittest {
    import std.algorithm : equal, map;
    import std.range : iota;
    auto fs = FastSet(10);
    fs.insert(1);
    fs.insert(5);
    fs.insert(6);
    fs.remove(5);
    fs.insert(4);
    // [1, 4, 6]
    assert(1 in fs);
    assert(2 !in fs);
    assert(5 !in fs);
    assert(6 in fs);
    assert(equal([1, 4, 6], fs[]));
    assert(equal(
        iota(8).map!(i => fs.next(i)),
        [1, 1, 4, 4, 4, 6, 6, 10]
    ));
    assert(equal(
        iota(8).map!(i => fs.prev(i)),
        [-1, 1, 1, 1, 4, 4, 6, 6]
    ));
    assert(equal([1], fs.lowerBound(4)));
    assert(equal([1, 4], fs.lowerBound(5)));
    assert(equal([1, 4, 6], fs.upperBound(0)));
    assert(equal([4, 6], fs.upperBound(1)));
}
