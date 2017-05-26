import std.stdio, std.process, std.exception, std.string, std.algorithm;
import std.array, std.conv;
import std.getopt;

import shrink;

string basePath = "";

int main(string[] args) {
    string inputName;
    string outputName;
    bool removeComment;
    bool removeUnittest;
    auto rslt = getopt(args,
        config.required,
        "input|i", &inputName,
        config.required,
        "output|o", &outputName,
        "c", &removeComment,
        "u", &removeUnittest,
        );
    if (rslt.helpWanted) {
        defaultGetoptPrinter("dlang source combiner.",
            rslt.options);
    }

    auto f = execute(["dub", "list"]);
    enforce(f.status == 0, "failed execute");
    foreach (s; f.output.splitLines) {
        auto l = s.split;
        if (l.length == 0 || l[0] != "dcomp") continue;
        basePath = l[2];
        break;
    }
    enforce(basePath != "", "dcomp not found");
    writeln(basePath);

    string[] imported = enumImport(inputName);
    writeln(imported);

    auto ouf = File(outputName, "w");
    foreach (ph; imported) {
        auto inf = File(ph, "r");
        auto data = new ubyte[inf.size()];
        inf.rawRead(data);
        bool first = (ph == inputName);
        if (!first) {
            ouf.writeln("/* IMPORT " ~ ph ~ " */");
            if (removeComment) {
                data = data.trimComment;
            }
            if (removeUnittest) {
                data = data.trimUnittest;
            }
        }
        foreach (line; data.map!(to!char).array.splitLines) {
            if (willCommentOut(line.idup, first)) {
                ouf.writeln("// " ~ line);
            } else {
                ouf.writeln(line);
            }
        }
    }
    return 0;
}


string[] line2Imp(string s) {
    string[] res;
    auto l = s.split;
    if (l.length >= 2 && l[0] == "import") {
        if (l[1].split(".")[0] == "dcomp") {
            //dcomp import
            foreach (ph; l[1..$]) {
                ph = ph.replace(".", "/");
                ph = ph.removechars([';', ',']);
                res ~= basePath ~ "source/" ~ ph ~ ".d";
            }
        }
    }
    return res;
}

bool willCommentOut(string s, bool first) {
    auto l = s.split;
    if (l.length && l[0] == "module" && !first) return true;
    if (line2Imp(s).length) return true;
    return false;
}

string[] enumImport(string fn) {
    bool[string] visited;
    string[] stack;
    stack ~= fn;
    while (stack.length) {
        auto path = stack[$-1];
        stack = stack[0..$-1];
        if (path in visited) continue;
        visited[path] = true;
        auto f = File(path, "r");
        foreach (line; f.byLine) {
            auto imp = line2Imp(line.idup);
            stack ~= imp;
        }
    }

    string[] res;
    res ~= fn;
    foreach (s, _; visited) {
        if (s == fn) continue;
        res ~= s;
    }
    return res;
}

