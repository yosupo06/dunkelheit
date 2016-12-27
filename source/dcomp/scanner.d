module dcomp.scanner;

class Scanner {
    import std.stdio : File, stdin;
    import std.conv : to;
    import std.range : front, popFront, array, ElementType;
    import std.array : split;
    import std.traits : isSomeString, isDynamicArray;
    import std.algorithm : map;
    File f;
    this(File f = stdin) {
        this.f = f;
    }
    string[] buf;
    bool succ() {
        while (!buf.length) {
            if (f.eof) return false;
            buf = f.readln.split;
        }
        return true;
    }
    int read(Args...)(auto ref Args args) {
        foreach (i, ref v; args) {
            if (!succ()) return i;
            alias VT = typeof(v);
            static if (!isSomeString!VT && isDynamicArray!VT) {
                v = buf.map!(to!(ElementType!VT)).array;
                buf.length = 0;
            } else {
                v = buf.front.to!VT;
                buf.popFront();
            }
        }
        return args.length;
    }
}
