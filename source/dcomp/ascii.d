module dcomp.ascii;

/**
ASCII文字限定string

中身をASCII文字に限定したrange系の操作を実装したstring.

速度に困らないなら普通にstringを使ったほうが良いと思う.
 */
struct ASCIIString {
    string s;
    alias s this;
    this(string s) {
        this.s = s;
    }
    ref immutable(char) front() const {
        return s[0];
    }
    void popFront() {
        s = s[1..$];
    }
    ref immutable(char) back() const {
        return s[$-1];
    }
    void popBack() {
        s = s[0..$-1];
    }
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
