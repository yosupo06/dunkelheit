/+ dub.sdl:
    name "A"
    dependency "dcomp" version=">=0.7.4"
+/

import std.stdio, std.algorithm, std.range, std.conv;
import dcomp.foundation, dcomp.scanner;

int main() {
    Scanner sc = new Scanner(stdin);
    int a, b;
    int[] c;
    sc.read(a, b, c);
    writeln(a, b, c);
    return 0;
}
