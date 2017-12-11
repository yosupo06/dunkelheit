module dcomp.geo.primitive;

import std.traits;

template EPS(R) {
    R EPS;
}

int sgn(R)(R a) {
    static if (isFloatingPoint!R) {
        import std.math : isNaN;
        assert(!isNaN(EPS!R));
    }
    if (a < -EPS!R) return -1;
    if (a > EPS!R) return 1;
    return 0;
}

struct Point2D(T) {
    T[2] d;
    this(T x, T y) {this.d = [x, y];}
    this(T[2] d) {this.d = d;}
    @property ref inout(T) x() inout {return d[0];}
    @property ref inout(T) y() inout {return d[1];}
    ref inout(T) opIndex(size_t i) inout {return d[i];}
    auto opOpAssign(string op)(in Point2D r) {
        return mixin("this=this"~op~"r");
    }
    auto opBinary(string op:"+")(in Point2D r) const {return Point2D(x+r.x, y+r.y);}
    auto opBinary(string op:"-")(in Point2D r) const {return Point2D(x-r.x, y-r.y);}
    static if (isFloatingPoint!T) {
        T abs() {
            import std.math : sqrt;
            return (x*x+y*y).sqrt;
        }
        T arg() {
            import std.math : atan2;
            return atan2(y, x);
        }
        Point2D rot(T ar) {
            import std.math : cos, sin;
            auto cosAr = cos(ar), sinAr = sin(ar);
            return Point2D(x*cosAr - y*sinAr, x*sinAr + y*cosAr);
        }
    }
}

int robustCmp(T)(Point2D!T a, Point2D!T b) {
    if (sgn(a.x-b.x)) return sgn(a.x-b.x);
    if (sgn(a.y-b.y)) return sgn(a.y-b.y);
    return 0;
}

bool near(T)(Point2D!T a, Point2D!T b) if (isIntegral!T) {
    return a == b;
}

bool near(T)(Point2D!T a, Point2D!T b) if (isFloatingPoint!T) {
    return !sgn((a-b).abs);
}

T dot(T)(in Point2D!T l, in Point2D!T r) {
    return l[0]*r[0] + l[1]*r[1];
}

T cross(T)(in Point2D!T l, in Point2D!T r) {
    return l[0]*r[1] - l[1]*r[0];
}


unittest {
    alias P = Point2D!int;
    P x = P(1, 2);
    P y = P(3, 4);
    assert((x+y).x == 4);
    assert((x+y)[1] == 6);
    assert(dot(x, y) == 11);
    assert(cross(x, y) == -2);
}


int ccw(R)(Point2D!R a, Point2D!R b, Point2D!R c) {
    import std.stdio;
    assert(!near(a, b));
    if (near(a, c) || near(b, c)) return 0;
    int s = sgn(cross(b-a, c-a));
    if (s) return s;
    if (dot(b-a, c-a) < 0) return 2;
    if (dot(a-b, c-b) < 0) return -2;
    return 0;
}


struct Line2D(R) {
    Point2D!R x, y;
    this(Point2D!R x, Point2D!R y) {
        this.x = x;
        this.y = y;
    }
    Point2D!R vec() const { return y-x; }
}

R distLP(R)(in Line2D!R l, in Point2D!R p) if (isFloatingPoint!R) {
    import std.math : abs;
    return abs(cross(l.vec, p-l.x) / l.vec.abs);
}
R distSP(R)(in Line2D!R s, in Point2D!R p) if (isFloatingPoint!R) {
    import std.algorithm : min;
    auto s2 = Point2D!R(-s.vec.y, s.vec.x);
    if (ccw(s.x, s.x+s2, p) == 1) return (s.x-p).abs;
    if (ccw(s.y, s.y+s2, p) == -1) return (s.y-p).abs;
    return min((s.x-p).abs, (s.y-p).abs, distLP(s, p));
}

unittest {
    import std.math;
    alias P = Point2D!double;
    alias L = Line2D!double;
    EPS!double = 1e-6;
    assert(approxEqual(
        distLP(L(P(-1, 0), P(1, 0)), P(0, 1)),
        1.0
    ));
    assert(approxEqual(
        distSP(L(P(-1, 0), P(1, 0)), P(-2, 1)),
        sqrt(2.0)
    ));
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
