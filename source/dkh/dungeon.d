module dkh.dungeon;

/// [+row, +col, -row, -col]
immutable static int[2][4] direction4 = [
    [1, 0], [0, 1], [-1, 0], [0, -1],
];

/// [+col, +row+col, +row, +row-col, ...]
immutable static int[2][8] direction8 = [
    [1, 0],
    [1, 1],
    [0, 1],
    [-1, 1],
    [-1, 0],
    [-1, -1],
    [0, -1],
    [1, -1],
];

static int[2] addInt2(in int[2] a, in int[2] b) {
    int[2] c;
    c[] = a[] + b[];
    return c;
}

/**
プロコンでよくある2Dダンジョン探索を支援するライブラリ
$(D int[2] = [row, column])をベースとする
 */
struct Dungeon {
    /// pからdir方向に移動したときの座標
    static int[2] move4(int[2] p, int dir) {
        return addInt2(p, direction4[dir]);
    }
    /// pからdir方向に移動したときの座標, 8方向
    static int[2] move8(int[2] p, int dir) {
        return addInt2(p, direction8[dir]);
    }

    immutable int R, C;
    /**
    Params:
        R = row_max
        C = column_max
    */
    this(int R, int C) {
        this.R = R;
        this.C = C;
    }
    /// pが[0, 0] ~ [R-1, C-1]に入っているか？
    bool isInside(int[2] p) const {
        int r = p[0], c = p[1];
        return 0 <= r && r < R && 0 <= c && c < C;
    }
    /// 1次元に潰したときのID, r*R+c
    int getID(int[2] p) const {
        int r = p[0], c = p[1];
        return r*R+c;
    }
}

///
auto neighbors4(int[2] p) {
    static struct Rng {
        int[2] center;
        size_t i;
        bool empty() const { return i == 4;}
        int[2] front() const { return addInt2(center, direction4[i]); }
        void popFront() { i++; }
    }
    return Rng(p, 0);
}

///
unittest {
    import std.algorithm : equal;
    assert(equal(
        [3, 5].neighbors4,
        [[4, 5], [3, 6], [2, 5], [3, 4]],
        ));
}

/// list neighbors only inside
auto neighbors4(int[2] p, in Dungeon dg) {
    static struct Rng {
        int[2] center;
        Dungeon dg;
        size_t i;
        this(in int[2] center, in Dungeon dg) {
            this.center = center;
            this.dg = dg;
            while (!empty() && !dg.isInside(front)) i++;
        }
        bool empty() const { return i == 4;}
        int[2] front() const { return addInt2(center, direction4[i]); }
        void popFront() {
            i++;
            while (!empty() && !dg.isInside(front)) i++;
        }
    }
    return Rng(p, dg);
}

///
unittest {
    import std.algorithm : equal;
    assert(equal(
        [0, 0].neighbors4(Dungeon(3, 3)),
        [[1, 0], [0, 1]],
        ));
}
