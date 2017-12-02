module dcomp.foundation;

//fold(for old compiler)
static if (__VERSION__ <= 2070) {
    /*
    Copied by https://github.com/dlang/phobos/blob/master/std/algorithm/iteration.d
    Copyright: Andrei Alexandrescu 2008-.
    License: $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0).
    */
    template fold(fun...) if (fun.length >= 1) {
        auto fold(R, S...)(R r, S seed) {
            import std.algorithm : reduce;
            static if (S.length < 2) {
                return reduce!fun(seed, r);
            } else {
                import std.typecons : tuple;
                return reduce!fun(tuple(seed), r);
            }
        }
    }
    unittest {
        import std.stdio;
        auto l = [1, 2, 3, 4, 5];
        assert(l.fold!"a+b"(10) == 25);
    }
}

import core.bitop : popcnt;
static if (!__traits(compiles, popcnt(ulong.max))) {
    public import core.bitop : popcnt;
    int popcnt(ulong v) {
        return popcnt(cast(uint)(v)) + popcnt(cast(uint)(v>>32));
    }
}

bool poppar(ulong v) {
    v^=v>>1; v^=v>>2;
    v&=0x1111111111111111UL;
    v*=0x1111111111111111UL;
    return ((v>>60) & 1) != 0;
}


/// 静的配列のリテラルであると明示的に指定する
T[N] fixed(T, size_t N)(T[N] a) {return a;}

///
unittest {
    auto a = [[1, 2].fixed];
    assert(is(typeof(a) == int[2][]));
}

