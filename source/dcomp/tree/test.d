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
