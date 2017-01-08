module dcomp.container.quickfind;

struct QuickFind {
    import std.algorithm : map, swap, each;
    import std.range : iota, array;
    int[] group; // group id
    int[][] list; // group list
    int count; // group count
    this(int n) {
        group = iota(n).array;
        list = iota(n).map!(a => [a]).array;
        count = n;
    }
    void merge(int a, int b) {
        if (same(a, b)) return;
        count--;
        int x = group[a], y = group[b];
        if (list[x].length < list[y].length) swap(x, y);
        list[y].each!(a => group[a] = x);
        list[x] ~= list[y];
        list[y] = [];
    }
    bool same(int a, int b) {
        return group[a] == group[b];
    }
}

unittest {
    import std.algorithm : equal, sort;
    auto uf = QuickFind(5);
    assert(!uf.same(1, 3));
    assert(uf.same(0, 0));

    uf.merge(3, 2);
    uf.merge(1, 1);
    uf.merge(4, 2);
    uf.merge(4, 3);

    assert(uf.count == 3);
    assert(uf.group[2] == uf.group[3]);
    assert(uf.group[2] == uf.group[4]);
    assert(equal(uf.list[uf.group[0]], [0]));
    assert(equal(uf.list[uf.group[1]], [1]));
    assert(equal(sort(uf.list[uf.group[2]]), [2, 3, 4]));
}

unittest {
    import std.datetime, std.stdio, std.range;
    // speed check
    writeln("QuickFind Speed Test");
    StopWatch sw;
    sw.start;
    QuickFind uf;
    // line
    uf = QuickFind(1_000_000);
    foreach (i; 1..1_000_000) {
        uf.merge(i-1, i);
    }
    // line(reverse)
    uf = QuickFind(1_000_000);
    foreach_reverse (i; 1..1_000_000) {
        uf.merge(i-1, i);
    }
    // binary tree
    uf = QuickFind(1_000_000);
    foreach (lg; 1..20) {
        int len = 1<<lg;
        foreach (i; iota(0, 1_000_000-len/2, len)) {
            uf.merge(i, i+len/2);
        }
    }
    sw.stop;
    writeln(sw.peek.msecs, "ms");
}
