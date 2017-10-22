module dcomp.datastructure.fastset;

struct FastSet {
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
    bool test(size_t x) const {
        assert(0 <= x && x < N);
        size_t D = x/64, R = x%64;
        return (seg[0][D] & (1UL << R)) != 0;
    }
    void set(int x) {
        foreach (i; 0..seg.length) {
            size_t D = x/64, R = x%64;
            seg[i][D] |= (1UL << R);
            x /= 64;
        }
    }
    void clear(int x) {
        foreach (i; 0..seg.length) {
            size_t D = x/64, R = x%64;
            seg[i][D] &= ~(1UL << R);
            if (i && seg[i-1][x] != 0) {
                seg[i][D] |= (1UL << R);
            }
            x /= 64;
        }
    }
    int next(int x) {
        for (int i = 0; i < lg; i++) {
            int D = x/64, R = x%64;
            if (D == seg[i].length) break;
            ull B = seg[i][D]>>R;
            if (!B) {
                x = x/64+1;
                continue;
            }
            //find
            x += bsf(B);
            for (int j = i-1; j >= 0; j--) {
                x *= 64;
                int D = x/64;
                x += bsf(seg[j][D]);
            }
            return x;
        }
        return N;
    }
    // x以下最大の要素
    int back(int x) {
        for (int i = 0; i < lg; i++) {
            if (x == -1) break;
            int D = x/64, R = x%64;
            ull B = seg[i][D]<<(63-R);
            if (!B) {
                x = x/64-1;
                continue;
            }
            //find
            x += bsr(B)-63;
            for (int j = i-1; j >= 0; j--) {
                x *= 64;
                int D = x/64;
                x += bsr(seg[j][D]);
            }
            return x;
        }
        return -1;
    }    
}

unittest {

}