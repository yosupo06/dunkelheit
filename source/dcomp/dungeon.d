module dcomp.dungeon;


/**
プロコンでよくある2Dダンジョン探索を支援するライブラリ
$(D int[2] = [x座標, y座標])をベースとする
 */
struct DungeonHelper {
    /// 4方向移動距離, 時計回りで[+x, +y, -x, -y]
    immutable static int[2][4] d4 = [
        [1, 0], [0, 1], [-1, 0], [0, -1],
    ];
    /// 8方向移動距離, 時計回りで[+x, +x+y, +y, -x+y, ...]
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
    /// コンストラクタ, (h=y_max, w=x_max)
    this(int h, int w) {
        this.h = h; this.w = w;
    }
    /// pが[0, 0] ~ [w-1, h-1]に入っているか？
    bool isInside(int[2] p) const {
        int x = p[0], y = p[1];
        return 0 <= x && x < w && 0 <= y && y < h;
    }
    /// 1次元に潰したときのID, y*w+x
    int getID(int[2] p) const {
        int x = p[0], y = p[1];
        return y*w+x;
    }
    /// pからdir方向に移動したときの座標
    int[2] move(int[2] p, int dir) const {
        int[2] res;
        res[] = p[] + d4[dir][];
        return res;
    }
    /// pからdir方向に移動したときの座標, 8方向
    int[2] move8(int[2] p, int dir) const {
        int[2] res;
        res[] = p[] + d8[dir][];
        return res;
    }
}
