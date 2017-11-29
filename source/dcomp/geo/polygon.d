module dcomp.geo.polygon;

import dcomp.geo.primitive;

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
