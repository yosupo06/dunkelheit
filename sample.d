/+ dub.sdl:
    name "A"
    dependency "dunkelheit" version="1.0.1"
+/

import std.stdio, std.algorithm, std.range, std.conv;
import dkh.foundation, dkh.scanner;

int main() {
    Scanner sc = new Scanner(stdin);
    scope(exit) assert(!sc.hasNext);
    int a, b;
    int[] c;
    sc.read(a, b, c);
    writeln(a, b, c);
    return 0;
}
