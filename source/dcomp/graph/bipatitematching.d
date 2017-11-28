module dcomp.graph.bipatitematching;

struct BipatiteMatching {
    int L, R, count;
    int[][] g;
    int[] lmt, rmt;
    int[] visited; int vc;
    this(int L, int R) {
        this.L = L; this.R = R;
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
    void exec() {
        vc++;
        foreach (i; 0..L) {
            if (lmt[i] != -1) continue;
            if (g[i].length == 0) continue;
            if (dfs(i)) count++;
        }
    }
    void add(int l, int r) {
        g[l] ~= r;
        exec();
    }
    void del(int l, int r) {
        g[l] = g[l].remove!(a => a == r);
        if (rmt[r] == l) {
            count--;
            lmt[l] = rmt[r] = -1;
            exec();
        }
    }
    void addL(int l, int[] v) {
        g[l] = v.dup;
        vc++;
        if (dfs(l)) count++;
    }
    void delL(int l) {
        g[l] = [];
        if (lmt[l] != -1) {
            int r = lmt[l];
            count--;
            lmt[l] = rmt[r] = -1;
            exec();
        }
    }
}
