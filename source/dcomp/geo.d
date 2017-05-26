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
    static if (isFloatingPoint!T) {
        T abs() {
            import std.math : sqrt;
            return (x*x+y*y).sqrt;
        }
        T arg() {
            import std.math : atan2;
            return atan2(y, x);
        }
    }
}

T dot(T)(in Point2D!T l, in Point2D!T r) {
    return l[0]*l[0] + l[1]*r[1];
}

T cross(T)(in Point2D!T l, in Point2D!T r) {
    return l[0]*r[1] - l[1]*r[0];
}

unittest {
    alias P = Point2D!int;
    P x = P(1, 2);
    P y = P(2, 2);
    assert((x+y).x == 3);
    assert((x+y)[1] == 4);
}

// cmp by argment, precise
// (-PI, PI], (-1, 0)=PI, (0, 0)=0, (1, 0) = 0
int argcmp(T)(Point2D!T l, Point2D!T r) if (isIntegral!T) {
    int sgn(Point2D!T p) {
        if (p[1] < 0) return -1;
        if (p[1] > 0) return 1;
        if (p[0] < 0) return 2;
        return 0;
    }
    int lsgn = sgn(l);
    int rsgn = sgn(r);
    if (lsgn < rsgn) return -1;
    if (lsgn > rsgn) return 1;

    T x = cross(l, r);
    if (x > 0) return -1;
    if (x < 0) return 1;

    return 0;
}


unittest {
    import std.math, std.random;
    int naive(Point2D!double l, Point2D!double r) {
        double la, ra;
        if (abs(l[1]) < 1e-9) {
            if (l[0] < -(1e-9)) la = PI;
            else la = 0;
        } else {
            la = l.arg;
        }
        if (abs(r[1]) < 1e-9) {
            if (r[0] < -(1e-9)) ra = PI;
            else ra = 0;
        } else {
            ra = r.arg;
        }

        if (abs(la-ra) < 1e-9) return 0;
        if (la < ra) return -1;
        return 1;
    }
    foreach (ya; -10..10) {
        foreach (yb; -10..10) {
            foreach (xa; -10..10) {
                foreach (xb; -10..10) {
                    auto pa = Point2D!long(xa, ya);
                    auto pb = Point2D!long(xb, yb);
                    auto qa = Point2D!double(xa, ya);
                    auto qb = Point2D!double(xb, yb);
                    assert(argcmp(pa, pb) == naive(qa, qb));
                }
            }
        }
    }
}
