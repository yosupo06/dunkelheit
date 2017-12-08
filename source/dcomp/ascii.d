module dcomp.ascii;

/**
ASCII-Only String
 */
struct ASCIIString {
    string s;
    alias s this;
    this(string s) {
        this.s = s;
    }
    ref immutable(char) front() const { return s[0]; } ///
    ref immutable(char) back() const { return s[$-1]; } ///
    void popFront() { s = s[1..$]; } ///
    void popBack() { s = s[0..$-1]; } ///
}

///
unittest {
    import std.algorithm;
    import std.range.primitives;
    auto s = "タネなし手品";
    auto asc = s.ASCIIString;
    assert(s.front == 'タ');
    assert(asc.front == "タ"[0]);
    assert(s.back == '品');
    assert(asc.back == "品"[$-1]);
}
