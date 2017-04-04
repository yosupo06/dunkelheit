struct DungeonHelper {
    immutable static int[2][4] d4 = [
        [1, 0], [0, 1], [-1, 0], [0, -1],
    ];
    immutable static int[2][8] d8 = [
        [1, 0],
        [1, 1],
        [0, 1],
        [-1, 1],
        [-1, 0],
        [-1, -1],
        [0, -1],
        [1, -1],
    ];
    int h, w;
    this(int h, int w) {
        this.h = h; this.w = w;
    }
    bool isInside(int[2] p) const {
        int x = p[0], y = p[1];
        return 0 <= x && x < w && 0 <= y && y < h;
    }
    int getID(int[2] p) const {
        int x = p[0], y = p[1];
        return y*w+x;
    }
    int[2] move(int[2] p, int dir) const {
        int[2] res;
        res[] = p[] + d4[dir][];
        return res;
    }
    int[2] move8(int[2] p, int dir) const {
        int[2] res;
        res[] = p[] + d8[dir][];
        return res;
    }
}
