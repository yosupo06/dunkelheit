/+ dub.sdl:
    name "A"
    dependency "dunkelheit" version=">=0.9.0"
+/

import std.stdio, std.algorithm, std.range, std.conv;
import dkh.foundation, dkh.scanner;

int main() {
    Scanner sc = new Scanner(stdin);
    scope(exit) sc.read!true;
    int a, b;
    int[] c;
    sc.read(a, b, c);
    writeln(a, b, c);
    return 0;
}
