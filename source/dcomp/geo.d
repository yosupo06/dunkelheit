module dcomp.geo;

import std.traits;

struct Point2D(T) {
    T[2] d;
    this(T x, T y) {this.d = [x, y];}
    this(T[2] d) {this.d = d;}
    @property ref inout(T) x() inout {return d[0];}
    @property ref inout(T) y() inout {return d[1];}
    ref inout(T) opIndex(size_t i) inout {return d[i];}
    auto opBinary(string op:"+")(Point2D r) const {return Point2D(x+r.x, y+r.y);}
    auto opBinary(string op:"-")(Point2D r) const {return Point2D(x-r.x, y-r.y);}
}

T abs(T)(Point2D!T p) if (isFloatingPoint!T) {
    import std.math : sqrt;
    return (p.x*p.x+p.y*p.y).sqrt;
}

T arg(T)(Point2D!T p) if (isFloatingPoint!T) {
    import std.math : atan2;
    return atan2(p.y, p.x);
}

unittest {
    alias P = Point2D!int;
    P x = P(1, 2);
    P y = P(2, 2);
    assert((x+y).x == 3);
    assert((x+y)[1] == 4);
}
