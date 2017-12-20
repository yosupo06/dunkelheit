module dkh.geo.circle;

import dkh.geo.primitive;

struct Circre2D(R) {
    Point2D!R p;
    R r;
    this(Point2D!R p, R r) {
        this.p = p;
        this.r = r;
    }
}

int crossSC(R)(Line2D!R l, Circre2D!R c) {
    R mi = distSP(l, c.p);
    if (sgn(mi - c.r) == 1) return 0;
    if (sgn(c.r - mi) == 0) return 1;
    int u = 0;
    if (sgn((l.x-c.p).abs - c.r) != -1) u++;
    if (sgn((l.y-c.p).abs - c.r) != -1) u++;
    return u;
}

unittest {
    EPS!double = 1e-6;
    alias P = Point2D!double;
    auto l = Line2D!double(P(0, 0), P(1, 0));
    auto c = Circre2D!double(P(3, 3), 1);
    assert(crossSC(l, c) == 0);
}
