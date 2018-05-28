/**
Unstable
*/

module dkh.graph.bipatitematching;

struct BipatiteMatching {
    import std.conv : to;
    int L, R, count;
    int[][] g;
    int[] lmt, rmt;
    int[] visited; int vc;
    this(size_t L, size_t R) {
        this.L = L.to!int; this.R = R.to!int;
        g = new int[][L];
        visited = new int[L];
        lmt = new int[L]; lmt[] = -1;
        rmt = new int[R]; rmt[] = -1;
    }
    bool dfs(int l) {
        if (l == -1) return true;
        if (visited[l] == vc) return false;
        visited[l] = vc;
        foreach (r; g[l]) {
            if (dfs(rmt[r])) {
                lmt[l] = r;
                rmt[r] = l;
                return true;
            }
        }
        return false;
    }
    void maximize() {
        vc++;
        foreach (i; 0..L) {
            if (lmt[i] != -1) continue;
            if (g[i].length == 0) continue;
            if (dfs(i)) count++;
        }
    }
    /// add edge(l, r)
    void addEdge(size_t l, size_t r) {
        g[l] ~= r.to!int;
        maximize();
    }
    /// del edge(l, r)
    void delEdge(size_t l, size_t r) {
        import std.algorithm : remove;
        g[l] = g[l].remove!(a => a == r.to!int);
        if (rmt[r] == l.to!int) {
            count--;
            lmt[l] = rmt[r] = -1;
            maximize();
        }
    }
    /// cng left_l's edge
    void cngLeftVertexEdge(size_t l, in int[] v) {
        g[l] = v.dup;
        vc++;
        if (lmt[l] == -1) {
            if (dfs(l.to!int)) count++;
        } else {
            count--;
            int r = lmt[l];
            lmt[l] = rmt[r] = -1;
            maximize();
        }
    }
}

///
unittest {
    auto bm = BipatiteMatching(3, 3);
    bm.addEdge(0, 0);
    bm.addEdge(0, 1);
    bm.addEdge(1, 1);
    bm.addEdge(2, 1);
    assert(bm.count == 2); // example: (0, 0), (1, 1)
    bm.addEdge(1, 2);
    assert(bm.count == 3); // (0, 0), (1, 2), (2, 1)
    bm.delEdge(2, 1);
    assert(bm.count == 2); // example: (0, 0) (1, 2)
}
