module dcomp.geo.circle;

import dcomp.geo.primitive;

struct Circre2D(R) {
    Point2D!R p;
    R r;
    this(Point2D!R p, R r) {
        this.p = p;
        this.r = r;
    }
}
