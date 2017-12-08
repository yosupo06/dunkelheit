module dcomp.datastructure.convexhull;

import dcomp.container.deque;


/// Convex Hull's query type
enum CHQueryType {
    incr, ///
    decr, ///
}

/**
Convex Hull Trick

Params:
    T = value type
    queryType = if queries are increase, use CHMode.incr.
                if queries are decrease, use CHMode.decr.
 */
struct ConvexHull(T, CHQueryType queryType) {
    import std.algorithm : max;
    alias L = T[2]; /// Line type $(D y = L[0] * x + L[1])
    private static T value(L l, T x) { return l[0]*x + l[1]; }
    
    Deque!L lines;
    // can remove mid?
    private static bool isNeed(L mid, L left, L right) {
        assert(left[0] <= mid[0] && mid[0] <= right[0]);
        return (right[0]-mid[0])*(left[1]-mid[1]) < (mid[0]-left[0])*(mid[1]-right[1]);
    }
    private void insertFront(L l) {
        if (lines.empty) {
            lines.insertFront(l);
            return;
        }
        assert(l[0] <= lines[0][0]);
        if (l[0] == lines[0][0]) {
            if (l[1] <= lines[0][1]) return;
            lines.removeFront;
        }
        while (lines.length >= 2 && !isNeed(lines.front, l, lines[1])) {
            lines.removeFront;
        }
        lines.insertFront(l);
    }
    private void insertBack(L l) {
        if (lines.empty) {
            lines.insertBack(l);
            return;
        }
        assert(lines[$-1][0] <= l[0]);
        if (lines[$-1][0] == l[0]) {
            if (l[1] <= lines[$-1][1]) return;
            lines.removeBack;
        }
        while (lines.length >= 2 && !isNeed(lines.back, lines[$-2], l)) {
            lines.removeBack;
        }
        lines.insertBack(l);
    }
    /**
    Insert line

    line's degree must be minimum or maximum
     */
    void insertLine(L line) {
        if (lines.empty) {
            lines.insertBack(line);
            return;
        }
        if (line[0] <= lines[0][0]) insertFront(line);
        else if (lines[$-1][0] <= line[0]) insertBack(line);
        else {
            assert(false, "line's degree must be minimum or maximum");
        }
    }
    /// get maximum y
    long maxY(T x) {
        assert(lines.length);
        static if (queryType == CHQueryType.incr) {
            while (lines.length >= 2 &&
                value(lines[0], x) <= value(lines[1], x)) {
                lines.removeFront;
            }
            return value(lines.front, x);
        } else {
            while (lines.length >= 2 &&
                value(lines[$-2], x) >= value(lines[$-1], x)) {
                lines.removeBack;
            }
            return value(lines.back, x);
        }
    }
}

///
unittest {
    ConvexHull!(int, CHQueryType.incr) c;
    c.insertLine([1, 4]);
    c.insertLine([2, 1]);
    c.insertLine([3, -100]);
    assert(c.maxY(-1) == 3); // 1 * (-1) + 4 = 3
    c.insertLine([-10, 100]);
    assert(c.maxY(2) == 80); // 2 * (-10) + 100 = 80
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
        ConvexHull!(int, CHQueryType.incr) c;
        if (uniform(0, 2)) {
            foreach_reverse (i; 0..100) {
                c.insertLine(v[i]);
            }
        } else {
            foreach (i; 0..100) {
                c.insertLine(v[i]);
            }
        }
        foreach (i; 0..100) {
            assert(c.maxY(smp[i]) == getMax(v, smp[i]));
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
        ConvexHull!(int, CHQueryType.decr) c;
        if (uniform(0, 2)) {
            foreach_reverse (i; 0..100) {
                c.insertLine(v[i]);
            }
        } else {
            foreach (i; 0..100) {
                c.insertLine(v[i]);
            }
        }
        foreach (i; 0..100) {
            assert(c.maxY(smp[i]) == getMax(v, smp[i]));
        }
    }

    import std.stdio;
    import dcomp.stopwatch;
    auto ti = benchmark!(f1, f2)(500);
    writeln("ConvexHull Random500: ", ti[].map!(a => a.toMsecs()));
}
