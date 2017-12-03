module dcomp.datastructure.convexhull;

import dcomp.container.deque;


/// Convex Hull's query type
enum CHMode { incr, decr }

/**
Convex Hull Trick

Params:
    T = value type
    queryType = if queries are increase order, use CHMode.incr.
                if queries are decrease order, use CHMode.decr.
 */
struct ConvexHull(T, CHMode queryType) {
    import std.algorithm : max;
    alias L = T[2]; /// Line
    static T value(L l, T x) { return l[0]*x + l[1]; }
    
    Deque!L data;
    bool isNeed(L x, L l, L r) const {
        assert(l[0] <= x[0] && x[0] <= r[0], "x must be mid");
        return (r[0]-x[0])*(l[1]-x[1]) < (x[0]-l[0])*(x[1]-r[1]);
    }
    /// insert line
    void insertFront(L x) {
        if (data.empty) {
            data.insertFront(x);
            return;
        }
        assert(x[0] <= data[0][0]);
        if (x[0] == data[0][0]) {
            if (x[1] <= data[0][1]) return;
            data.removeFront;
        }
        while (data.length >= 2 && !isNeed(data[0], x, data[1])) {
            data.removeFront;
        }
        data.insertFront(x);
        if (data.length >= 3) {
            assert(isNeed(data[1], data[0], data[2]));
        }
    }
    /// ditto
    void insertBack(L x) {
        if (data.empty) {
            data.insertBack(x);
            return;
        }
        assert(data[$-1][0] <= x[0]);
        if (data[$-1][0] == x[0]) {
            if (x[1] <= data[$-1][1]) return;
            data.removeBack;
        }
        while (data.length >= 2 && !isNeed(data[$-1], data[$-2], x)) {
            data.removeBack;
        }
        data.insertBack(x);
    }
    /// get maximum y
    long yMax(T x) {
        assert(data.length);
        static if (queryType == CHMode.incr) {
            while (data.length >= 2 &&
                value(data[0], x) <= value(data[1], x)) {
                data.removeFront;
            }
            return value(data.front, x);
        } else {
            while (data.length >= 2 &&
                value(data[$-2], x) >= value(data[$-1], x)) {
                data.removeBack;
            }
            return value(data.back, x);
        }
    }
}

unittest {
    ConvexHull!(int, CHMode.incr) c;
    c.insertFront([1, 1]);
    c.insertBack([2, 1]);
    c.insertBack([3, -100]);
    assert(c.yMax(-1) == 0);
    c.insertFront([0, 100]);
    assert(c.yMax(0) == 100);
}

unittest {
    import std.random;
    import std.algorithm;
    int getMax(int[2][] v, int x) {
        int ans = int.min;
        foreach (l; v) {
            ans = max(ans, l[0]*x + l[1]);
        }
        return ans;
    }
    void f1() {
        int[2][] v = new int[2][](100);
        int[] smp = new int[](100);
        foreach (i; 0..100) {
            v[i][0] = uniform(-100, 100);
            v[i][1] = uniform(-100, 100);
            smp[i] = uniform(-10000, 10000);
        }
        sort(v);
        sort(smp);
        ConvexHull!(int, CHMode.incr) c;
        if (uniform(0, 2)) {
            foreach_reverse (i; 0..100) {
                c.insertFront(v[i]);
            }
        } else {
            foreach (i; 0..100) {
                c.insertBack(v[i]);
            }
        }
        foreach (i; 0..100) {
            assert(c.yMax(smp[i]) == getMax(v, smp[i]));
        }
    }
    void f2() {
        int[2][] v = new int[2][](100);
        int[] smp = new int[](100);
        foreach (i; 0..100) {
            v[i][0] = uniform(-100, 100);
            v[i][1] = uniform(-100, 100);
            smp[i] = uniform(-10000, 10000);
        }
        sort(v);
        sort(smp); reverse(smp);
        ConvexHull!(int, CHMode.decr) c;
        if (uniform(0, 2)) {
            foreach_reverse (i; 0..100) {
                c.insertFront(v[i]);
            }
        } else {
            foreach (i; 0..100) {
                c.insertBack(v[i]);
            }
        }
        foreach (i; 0..100) {
            assert(c.yMax(smp[i]) == getMax(v, smp[i]));
        }
    }

    import std.stdio;
    import dcomp.stopwatch;
    auto ti = benchmark!(f1, f2)(500);
    writeln("ConvexHull Random500: ", ti[].map!(a => a.toMsecs()));
}
