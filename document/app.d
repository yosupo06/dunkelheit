import std.stdio, std.process;
import std.algorithm, std.string, std.range;
import std.file, std.path;

string toHTMLFileName(string s) {
    return s
        .stripExtension
        .replace("/", "_")
        ~ ".html";
}

class Node {
    string name;
    Node[] children;
    this(string name) {
        this.name = name;
    }
    this(string name, string[] sources) {
        this.name = name;
        bool[string] chName;
        string[] chNames = sources
            .filter!(s => s.count("/"))
            .map!(s => s.split("/")[0])
            .array.sort!"a<b".uniq.array;
        foreach (n; chNames) {
            children ~= new Node(n,
            sources
                .filter!(s => s.startsWith(n))
                .map!(s => s.chompPrefix(n ~ "/"))
                .array);
        }
        foreach (s; sources.filter!(s => !s.count("/"))) {
            children ~= new Node(s);
        }
        children.sort!"a.name < b.name";
    }
}

void makeNav(string[] sources) {
    auto f = File("navbar.ddoc", "w");
    f.writeln("NAVBODY = \n$(UL");
    void dump(Node n, int dps, string[] path) {
        path = path ~ n.name;
        if (dps == 0) {
            foreach (c; n.children) {
                dump(c, dps+1, path);
            }
            return;
        }        
        if (n.children.length == 0) {
            string url = path.join("_") ~ ".html";
            string name = n.name;
            f.write("\t".repeat.take(dps).join(""));
            f.writefln("$(LI $(LINK2 %s, %s))", url, name);
        } else {
            f.write("\t".repeat.take(dps).join(""));
            f.writefln("$(LI %s $(UL", n.name);
            foreach (c; n.children) {
                dump(c, dps+1, path);
            }
            f.write("\t".repeat.take(dps).join(""));
            f.writeln("))");
        }
    }
    auto n = new Node("", sources.map!(s => s.stripExtension).array);
    dump(n.children[0], 0, []);
    f.writeln(")");
}

int main(string[] args) {
    auto sources = execute(["find", "./source", "-name", "*.d"])
        .output.splitLines.map!(s => s.chompPrefix("./source/")).array;
    writeln(sources);
    writeln(sources.map!toHTMLFileName);
    makeNav(sources);
    if (!exists("docs")) mkdir("docs");
    foreach (s; sources) {
        auto cmd = ["dmd", "-D", "-o-", "-Isource", "-Dfdocs/"~s.toHTMLFileName,
            "base.ddoc", "navbar.ddoc", "source/"~s];
        writeln(cmd);
        execute(cmd);
    }
    return 0;
}
