module dkh.geo.polygon;

import dkh.geo.primitive;

inout(Point2D!R) at(R)(inout Point2D!R[] pol, size_t i) {
    return pol[i<pol.length?i:i-pol.length];
}

//0:P is out 1:P is on line 2:P is in
int contains(R)(Point2D!R[] pol, Point2D!R p) {
    import std.algorithm : swap;
    int res = -1;
    foreach (i; 0..pol.length) {
        auto a = pol.at(i) - p, b = pol.at(i+1) - p;
        if (ccw(a, b, Point2D!R(0, 0)) == 0) return 1;
        if (a.y > b.y) swap(a, b);
        if (a.y <= 0 && 0 < b.y) {
            if (cross(a, b) < 0) res *= -1;
        }
    }
    return res+1;
}

unittest {
    alias P = Point2D!int;
    P[] pol = [P(0, 0), P(2, 0), P(2, 2), P(0, 2)];
    assert(contains(pol, P(-1, 0)) == 0);
    assert(contains(pol, P(0, 0)) == 1);
    assert(contains(pol, P(1, 1)) == 2);
}

R area2(R)(Point2D!R[] pol) {
    R u = 0;
    foreach (i; 0..pol.length) {
        auto a = pol.at(i), b = pol.at(i+1);
        u += cross(a, b);
    }
    return u;
}

unittest {
    alias P = Point2D!int;
    P[] pol = [P(0, 0), P(2, 0), P(2, 2), P(0, 2)];
    assert(area2(pol) == 8);
}

import dkh.container.stackpayload;

Point2D!R[] convex(R)(Point2D!R[] _pol) {
    import std.algorithm : sort;
    import std.range : retro, array;
    auto pol = _pol.dup;
    pol.sort!((a, b) => robustCmp(a, b) == -1);
    if (pol.length <= 2) return pol;
    StackPayload!(Point2D!R) up;
    foreach (d; pol) {
        while (up.length >= 2 && ccw(up[$-2], up[$-1], d) == 1) up.removeBack();
        up ~= d;
    }
    StackPayload!(Point2D!R) down;
    foreach (d; pol) {
        while (down.length >= 2 && ccw(down[$-2], down[$-1], d) == -1) down.removeBack();
        down ~= d;
    }
    return up.data.retro.array[1..$-1] ~ down.data();
}

unittest {
    EPS!double = 1e-9;
    alias P = Point2D!double;
    P[] pol = [P(0, 0), P(2, 2), P(1, 1), P(0, 2), P(2, 0)];
    import std.stdio;
    assert(pol.convex.length == 4);
}
