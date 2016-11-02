import std.stdio, std.process, std.exception, std.string;

string basePath = "";
string[] line2Imp(string s) {
	string[] res;
 	auto l = s.split;
	if (l.length >= 2 && l[0] == "import") {
		if (l[1].split(".")[0] == "dcomp") {
			//dcomp import
			foreach (ph; l[1..$]) {
				auto li = ph.split(".");
				res ~= basePath ~ "source/" ~ ph.replace(".", "/").replace(";", "").idup ~ ".d";
			}
		}
	}
	return res;
}

bool willCommentOut(string s) {
	auto l = s.split;
	if (l.length && l[0] == "module") return true;
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
	foreach (s, _; visited) {
		res ~= s;
	}
	return res;
}

int main(string[] argv) {
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
	enforce(argv.length == 3, "usage: dub run dcomp:combine -- [input] [output]");

	string[] imported = enumImport(argv[1]);
	writeln(imported);

	auto ouf = File(argv[2], "w");
	foreach (ph; imported) {
		auto inf = File(ph, "r");
		foreach (line; inf.byLine) {
			if (willCommentOut(line.idup)) {
				ouf.writeln("// " ~ line);
			} else {
				ouf.writeln(line);
			}
		}
	}

	return 0;
}