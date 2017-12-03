module dcomp.tree.test;

import dcomp.tree.primitive;
import dcomp.tree.avl;

unittest {
    import std.traits : AliasSeq;
    alias Engines = AliasSeq!(AVLNode);
    import std.random;
    import dcomp.modint;
    alias Mint = ModInt!(10^^9 + 7);
    auto rndM = (){ return Mint(uniform(0, 10^^9 + 7)); };
    void check(alias E)() {
        alias T = Tree!(E, Mint, "a+b", Mint(0));
        T t;
        Mint sm = 0;
        foreach (i; 0..100) {
            auto x = rndM();
            sm += x;
            t.insert(0, x);
        }
        assert(sm == t[0..$].sum);
    }
    foreach (E; Engines) {
        check!E();
    }
}

unittest {
    import std.random;
    import std.algorithm;
    import std.conv;
    import std.container.rbtree;
    import std.stdio;

    import dcomp.stopwatch;
    StopWatch sw; sw.start;
    auto nv = redBlackTree!(true, int)([]);
    auto tr = Tree!(AVLNode, int, max, int.min)();
    foreach (ph; 0..10000) {
        int ty = uniform(0, 2);
        if (ty == 0) {
            int x = uniform(0, 100);
            nv.insert(x);
            tr.insert(tr.binSearchLeft!(y => x <= y)(0, tr.length), x);
        } else {
            if (!nv.length) continue;
            int i = uniform(0, nv.length.to!int);
            auto u = nv[];
            foreach (_; 0..i) u.popFront();
            assert(u.front == tr[i]);
            int x = tr[i];
            nv.removeKey(x);
            tr.removeAt(i);
        }
        assert(nv.length == tr.length);
    }
    writeln("Set TEST: ", sw.peek.toMsecs);
}
