module dcomp.foundation;
//fold
static if (__VERSION__ <= 2070) {
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