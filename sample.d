/+ dub.sdl:
	name "A"
	dependency "dcomp" version="~master"
+/

int main() {
	import std.stdio;
	import dcomp.scanner;
	auto sc = new Scanner();
	int a, b;
	int[] c;
	sc.read(a, b, c);
	writeln(a, b, c);
	return 0;
}