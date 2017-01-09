module dcomp.container.unionfind;

struct UnionFind {
    import std.algorithm : map, swap, each;
    import std.range : iota, array;
    int[] id; // group id
    int[][] groups; // group list
    int count; // group count
    this(int n) {
        id = iota(n).array;
        groups = iota(n).map!(a => [a]).array;
        count = n;
    }
    void merge(int a, int b) {
        if (same(a, b)) return;
        count--;
        int x = id[a], y = id[b];
        if (groups[x].length < groups[y].length) swap(x, y);
        groups[y].each!(a => id[a] = x);
        groups[x] ~= groups[y];
        groups[y] = [];
    }
    int[] group(int i) {
        return groups[id[i]];
    }
    bool same(int a, int b) {
        return id[a] == id[b];
    }
}

unittest {
    import std.algorithm : equal, sort;
    auto uf = UnionFind(5);
    assert(!uf.same(1, 3));
    assert(uf.same(0, 0));

    uf.merge(3, 2);
    uf.merge(1, 1);
    uf.merge(4, 2);
    uf.merge(4, 3);

    assert(uf.count == 3);
    assert(uf.id[2] == uf.id[3]);
    assert(uf.id[2] == uf.id[4]);
    assert(equal(uf.group(0), [0]));
    assert(equal(uf.group(1), [1]));
    assert(equal(sort(uf.group(2)), [2, 3, 4]));
}

unittest {
    import std.datetime, std.stdio, std.range;
    // speed check
    writeln("UnionFind Speed Test");
    StopWatch sw;
    sw.start;
    UnionFind uf;
    // line
    uf = UnionFind(1_000_000);
    foreach (i; 1..1_000_000) {
        uf.merge(i-1, i);
    }
    // line(reverse)
    uf = UnionFind(1_000_000);
    foreach_reverse (i; 1..1_000_000) {
        uf.merge(i-1, i);
    }
    // binary tree
    uf = UnionFind(1_000_000);
    foreach (lg; 1..20) {
        int len = 1<<lg;
        foreach (i; iota(0, 1_000_000-len/2, len)) {
            uf.merge(i, i+len/2);
        }
    }
    sw.stop;
    writeln(sw.peek.msecs, "ms");
}
