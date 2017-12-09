module dcomp.datastructure.unionfind;

/// UnionFind (Disjoint Set Union)
struct UnionFind {
    import std.algorithm : map, swap, each;
    import std.range : iota, array;
    import std.conv : to;
    int[] id; // group id
    int[][] groups; // group list
    int count; // group count
    /// n:頂点数
    this(size_t n) {
        id = iota(n.to!int).array;
        groups = iota(n.to!int).map!(a => [a]).array;
        count = n.to!int;
    }
    /// a, bをmerge
    void merge(size_t a, size_t b) {
        if (same(a, b)) return;
        count--;
        int x = id[a], y = id[b];
        if (groups[x].length < groups[y].length) swap(x, y);
        groups[y].each!(a => id[a] = x);
        groups[x] ~= groups[y];
        groups[y] = [];
    }
    /// iと同じgroupの頂点を返す
    int[] group(size_t i) {
        return groups[id[i]];
    }
    /// a, bは同じgroupか？
    bool same(size_t a, size_t b) {
        return id[a] == id[b];
    }
}

///
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
    import std.stdio, std.range;
    import dcomp.stopwatch;
    // speed check
    StopWatch sw; sw.start;
    UnionFind uf;
    // line
    uf = UnionFind(100_000);
    foreach (i; 1..100_000) {
        uf.merge(i-1, i);
    }
    // line(reverse)
    uf = UnionFind(100_000);
    foreach_reverse (i; 1..100_000) {
        uf.merge(i-1, i);
    }
    // binary tree
    uf = UnionFind(100_000);
    foreach (lg; 1..17) {
        int len = 1<<lg;
        foreach (i; iota(0, 100_000-len/2, len)) {
            uf.merge(i, i+len/2);
        }
    }
    writeln("UnionFind Speed Test: ", sw.peek.toMsecs());
}
