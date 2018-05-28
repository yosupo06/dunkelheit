module dkh.scanner;

import dkh.container.stackpayload;

/**
Scanner, not slow, not fast.
*/
class Scanner {
    import std.stdio : File;
    import std.conv : to;
    import std.range : front, popFront, array, ElementType;
    import std.array : split;
    import std.traits : isSomeChar, isStaticArray, isArray; 
    import std.algorithm : map;
    private File f;
    /// f is source file
    this(File f) {
        this.f = f;
    }
    private char[512] lineBuf;
    private char[] line;
    private bool succW() {
        import std.range.primitives : empty, front, popFront;
        import std.ascii : isWhite;
        while (!line.empty && line.front.isWhite) {
            line.popFront;
        }
        return !line.empty;
    }
    private bool succ() {
        import std.range.primitives : empty, front, popFront;
        import std.ascii : isWhite;
        while (true) {
            while (!line.empty && line.front.isWhite) {
                line.popFront;
            }
            if (!line.empty) break;
            line = lineBuf[];
            f.readln(line);
            if (!line.length) return false;
        }
        return true;
    }

    private bool readSingle(T)(ref T x) {
        import std.algorithm : findSplitBefore;
        import std.string : strip;
        import std.conv : parse;
        if (!succ()) return false;
        static if (isArray!T) {
            alias E = ElementType!T;
            static if (isSomeChar!E) {
                //string or char[10] etc
                //todo optimize
                auto r = line.findSplitBefore(" ");
                x = r[0].strip.dup;
                line = r[1];
            } else static if (isStaticArray!T) {
                foreach (i; 0..T.length) {
                    assert(succW());
                    x[i] = line.parse!E;
                }
            } else {
                StackPayload!E buf;
                while (succW()) {
                    buf ~= line.parse!E;
                }
                x = buf.data;
            }
        } else {
            x = line.parse!T;
        }
        return true;
    }

    /// Read tokens. Return the number of success read
    int unsafeRead(T, Args...)(ref T x, auto ref Args args) {
        if (!readSingle(x)) return 0;
        static if (args.length == 0) {
            return 1;
        } else {
            return 1 + read(args);
        }
    }
    /// Read tokens. If can't read, throw exception.
    void read(Args...)(auto ref Args args) {
        import std.exception : enforce;
        static if (args.length != 0) {
            enforce(readSingle(args[0]));
            read(args[1..$]);
        }
    }
    /// Do file has next token?
    bool hasNext() {
        return succ();
    }
}


///
unittest {
    import std.path : buildPath;
    import std.file : tempDir;
    import std.algorithm : equal;
    import std.stdio : File;
    string fileName = buildPath(tempDir, "kyuridenanmaida.txt");
    auto fout = File(fileName, "w");
    fout.writeln("1 2 3");
    fout.writeln("ab cde");
    fout.writeln("1.0 1.0 2.0");
    fout.close;
    Scanner sc = new Scanner(File(fileName, "r"));
    int a;
    int[2] b;
    char[2] c;
    string d;
    double e;
    double[] f;
    sc.read(a, b, c, d, e, f);
    assert(a == 1);
    assert(equal(b[], [2, 3])); // array(except char) read whole line
    assert(equal(c[], "ab")); // char array(char[], char[2], ...) return token
    assert(equal(d, "cde")); // string is char array
    assert(e == 1.0);
    assert(equal(f, [1.0, 2.0]));
    assert(!sc.hasNext);
}

unittest {
    import std.path : buildPath;
    import std.file : tempDir;
    import std.algorithm : equal;
    import std.stdio : File, writeln;
    import dkh.stopwatch;
    string fileName = buildPath(tempDir, "kyuridenanmaida.txt");
    auto fout = File(fileName, "w");
    foreach (i; 0..1_000_000) {
        fout.writeln(3*i, " ", 3*i+1, " ", 3*i+2);
    }
    fout.close;
    StopWatch sw;
    sw.start;
    Scanner sc = new Scanner(File(fileName, "r"));
    foreach (i; 0..500_000) {
        int a, b, c;
        sc.read(a, b, c);
        assert(a == 3*i);
        assert(b == 3*i+1);
        assert(c == 3*i+2);
    }
    foreach (i; 500_000..700_000) {
        int[3] d;
        sc.read(d);
        int a = d[0], b = d[1], c = d[2];
        assert(a == 3*i);
        assert(b == 3*i+1);
        assert(c == 3*i+2);
    }
    foreach (i; 700_000..1_000_000) {
        int[] d;
        sc.read(d);
        assert(d.length == 3);
        int a = d[0], b = d[1], c = d[2];
        assert(a == 3*i);
        assert(b == 3*i+1);
        assert(c == 3*i+2);
    }
    writeln("Scanner Speed Test(3*1,000,000 int): ", sw.peek.toMsecs);
}
