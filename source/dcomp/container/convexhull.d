module dcomp.container.convexhull;

import dcomp.container.deque;

enum CHMode { incr, decr }
struct ConvexHull(T, CHMode queryType) {
    import std.algorithm : max;
    //query x, this x is decrease
    alias L = T[2]; //[a, b] y = ax + b
    static T value(L l, T x) { return l[0]*x + l[1]; }
    
    Deque!L data;
    bool isNeed(L x, L l, L r) const {
        assert(l[0] <= x[0] && x[0] <= r[0], "x must be mid");
        return (r[0]-x[0])*(l[1]-x[1]) <= (x[0]-l[0])*(x[1]-r[1]);
    }
    void insertFront(L x) {
        if (data.empty) {
            data.insertFront(x);
            return;
        }
        assert(x[0] <= data.front[0]);
        if (x[0] == data.front[0]) {
            data.front[1] = max(data.front[1], x[1]);
            return;
        }
        while (data.length >= 2 && !isNeed(x, data[0], data[1])) {
            data.removeFront;
        }
        data.insertFront(x);
    }
    void insertBack(L x) {
        if (data.empty) {
            data.insertBack(x);
            return;
        }
        assert(data.back[0] <= x[0]);
        if (data.back[0] == x[0]) {
            data.back[1] = max(data.back[1], x[1]);
            return;
        }
        while (data.length >= 2 && !isNeed(data[$-1], data[$-2], x)) {
            data.removeBack;
        }
        data.insertBack(x);
    }
    long yMax(T x) {
        assert(data.length);
        static if (queryType == CHMode.incr) {
            while (data.length >= 2) {
                if (value(data[0], x) < value(data[1], x)) break;
                data.removeFront;
            }
            return value(data.front, x);
        } else {
            while (data.length >= 2) {
                if (value(data[$-2], x) < value(data[$-1], x)) break;
                data.removeBack;
            }
            return value(data.back, x);
        }
    }
}
