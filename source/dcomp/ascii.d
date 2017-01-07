module dcomp.ascii;

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
}

ASCIIString ascii(string s) {
    return ASCIIString(s);
}

unittest {
    import std.algorithm;
    import std.range.primitives;
    auto s = "タネなし手品";
    auto asc = s.ascii;
    assert(s.front == 'タ');
    assert(asc.front == "タ"[0]);
    assert(asc.map!(c => 1).sum == s.length);
}
