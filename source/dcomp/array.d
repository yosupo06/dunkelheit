module dcomp.array;

/// 静的配列のリテラルであると明示的に指定する
T[N] fixed(T, size_t N)(T[N] a) {return a;}

///
unittest {
    auto a = [[1, 2].fixed];
    assert(is(typeof(a) == int[2][]));
}

///
int[2] findFirst2D(T, U)(in T mp, in U c) {
    import std.conv : to;
    int R = mp.length.to!int;
    int C = mp[0].length.to!int;
    foreach (i; 0..R) {
        foreach (j; 0..C) {
            if (mp[i][j] == c) return [i, j];
        }
    }
    assert(false);
}

///
unittest {
    string[] mp = [
        "s..",
        "...",
        "#g#"];
    assert(mp.findFirst2D('s') == [0, 0]);
    assert(mp.findFirst2D('g') == [2, 1]);
}

///
auto ref at2D(T, U)(ref T mp, in U idx) {
    return mp[idx[0]][idx[1]];
}

///
unittest {
    string[] mp = [
        "s..",
        "...",
        "#g#"];
    assert(mp.at2D([0, 0]) == 's');
    assert(mp.at2D([2, 1]) == 'g');
}
