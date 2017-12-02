module dcomp.array;

/// 静的配列のリテラルであると明示的に指定する
T[N] fixed(T, size_t N)(T[N] a) {return a;}

///
unittest {
    auto a = [[1, 2].fixed];
    assert(is(typeof(a) == int[2][]));
}

