/**
Unstable
*/
module dkh.graph.hldecomp;

import dkh.container.stackpayload;

struct HLInfo {
    int[2][] id; //vertex -> [line id, line pos]
    int[][] lines; //line id -> line list(top to bottom)
    int[2][] par; //line id -> [parent line id, parent line pos]
    int[] lineDPS; //line id -> line depth
    this(size_t n) {
        id = new int[2][n];
    }
}

/// calc lca(a, b)
int calcLCA(in HLInfo hl, int a, int b) {
    import std.algorithm : swap;
    with (hl) {
        int[2] xl = id[a];
        int[2] yl = id[b];
        if (lineDPS[xl[0]] < lineDPS[yl[0]]) swap(xl, yl);
        while (lineDPS[xl[0]] > lineDPS[yl[0]]) {
            xl = par[xl[0]];
        }
        while (xl[0] != yl[0]) {
            xl = par[xl[0]];
            yl = par[yl[0]];
        }
        if (xl[1] > yl[1]) swap(xl, yl);
        return lines[xl[0]][xl[1]];
    }
}

HLInfo hlDecomposition(T)(in T g, int rt) {
    auto n = g.length;
    auto hl = HLInfo(n);
    with (hl) {
        int[] sz = new int[n];
        int calcSZ(int p, int b) {
            sz[p] = 1;
            foreach (e; g[p]) {
                if (e.to == b) continue;
                sz[p] += calcSZ(e.to, p);
            }
            return sz[p];
        }
        calcSZ(rt, -1);
        int idc = 0;
        StackPayload!(int[2]) par_buf;
        StackPayload!int line_buf, dps_buf;
        void dfs(int p, int b, int height) {
            line_buf ~= p;
            id[p] = [idc, height];
            int nx = -1, buf = -1;
            foreach (e; g[p]) {
                if (e.to == b) continue;
                if (buf < sz[e.to]) {
                    buf = sz[e.to];
                    nx = e.to;
                }
            }
            if (nx == -1) {
                //make line
                lines ~= line_buf.data.dup;
                line_buf.clear;
                idc++;
                return;
            }

            dfs(nx, p, height+1);
            foreach (e; g[p]) {
                if (e.to == b || e.to == nx) continue;
                par_buf ~= id[p];
                dps_buf ~= dps_buf.data[id[p][0]] + 1;
                dfs(e.to, p, 0);
            }
        }
        par_buf ~= [-1, -1];
        dps_buf ~= 0;
        dfs(rt, -1, 0);
        par = par_buf.data;
        lineDPS = dps_buf.data;
    }
    return hl;
}
