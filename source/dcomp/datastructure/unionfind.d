module dcomp.datastructure.unionfind;

/// UnionFind (Disjoint Set Union)
struct UnionFind {
    private int[] id; /// group id
    private int[][] groups; /// group list
    size_t count; /// group count
    /**
    Params:
        n = # of element
     */
    this(size_t n) {
        import std.algorithm : map;
        import std.range : iota, array;
        import std.conv : to;
        int _n = n.to!int;
        id = _n.iota.array;
        groups = _n.iota.map!"[a]".array;
        count = n;
    }
    /// merge a, b
    void merge(size_t a, size_t b) {
        import std.algorithm : swap, each;
        if (same(a, b)) return;
        count--;
        uint x = id[a], y = id[b];
        if (groups[x].length < groups[y].length) swap(x, y);
        groups[y].each!(a => id[a] = x);
        groups[x] ~= groups[y];
        groups[y] = [];
    }
    /// elements that are same group with i
    const(int[]) group(size_t i) const {
        return groups[id[i]];
    }
    /**
    i がグループのリーダーか返す.
    各グループにはただ1つのみリーダーが存在する
     */
    bool isLeader(size_t i) const {
        return i == id[i];
    }
    /// Are a and b same group?
    bool same(size_t a, size_t b) const {
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
    assert(equal(sort(uf.group(2).dup), [2, 3, 4]));

    auto cnt = 0;
    foreach (i; 0..5) {
        if (!uf.isLeader(i)) continue;
        cnt += uf.group(i).length;
    }
    assert(cnt == 5); // view all element exactly once
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
