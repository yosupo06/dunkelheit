module dkh.graph.directedmst;

import std.stdio;

DirectedMSTInfo!(_E, D) directedMST(T, _E = EdgeType!T, D = typeof(_E.dist))(T _g, size_t r) {
    import std.algorithm, std.range, std.conv, std.typecons;
    alias E = Tuple!(int, "from", _E, "edge");

    static struct PairingHeapAllAdd {
        alias NP = Node*;
        static struct Node {        
            E e;
            D offset;
            NP head, next;
            this(E e) {
                this.e = e;
                offset = D(0);
            }
        }
        NP n;
        size_t length;
        this(E[] e) {
            length = e.length;            
            foreach (d; e) {
                n = merge(n, new Node(d));
            }
        }
        static NP merge(NP x, NP y) {
            if (!x) return y;
            if (!y) return x;
            if (x.e.edge.dist+x.offset > y.e.edge.dist+y.offset) swap(x, y);
            y.offset -= x.offset;
            y.next = x.head;
            x.head = y;
            return x;
        }
        void C() { assert(n); }
        E front() {C; return n.e; }
        void removeFront() {
            assert(n);
            assert(length > 0);
            length--;
            NP x;
            NP s = n.head;
            while (s) {
                NP a, b;
                a = s; s = s.next; a.next = null; a.offset += n.offset;
                if (s) {
                    b = s; s = s.next; b.next = null; b.offset += n.offset;
                }
                a = merge(a, b);
                assert(a);
                if (!x) x = a;
                else {
                    a.next = x.next;
                    x.next = a;
                }
            }
            n = null;
            while (x) {
                NP a = x; x = x.next;
                n = merge(a, n);
            }
        }
        void meld(PairingHeapAllAdd r) {
            length += r.length;
            n = merge(n, r.n);
        }
        ref D offset() {C; return n.offset; }
    }
    
    auto n = _g.length;
    auto heap = new PairingHeapAllAdd[2*n];
    foreach (i; 0..n) {
        heap[i] = PairingHeapAllAdd(_g[i].map!(e => E(i.to!int, e)).array);
    }

    //union find
    int[] tr = new int[2*n]; tr[] = -1;
    int[] uf = new int[2*n]; uf[] = -1;
    int root(int i) {
        if (uf[i] == -1) return i;
        return uf[i] = root(uf[i]);
    }

    int[] used = new int[2*n];
    E[] res = new E[2*n];
    int c = 1, pc = n.to!int;
    used[r] = 1;
    void mark(int p) {
        c++;
        while (used[p] == 0 || used[p] == c) {
            if (used[p] == c) {
                //compress
                int np = pc++;
                int q = p;
                do {
                    heap[q].offset -= res[q].edge.dist + heap[q].offset;
                    heap[np].meld(heap[q]);
                    tr[q] = uf[q] = np;
                    q = root(res[q].edge.to);
                } while (q != np);
                p = np;
            }
            assert(used[p] == 0);
            used[p] = c;

            assert(root(p) == p);
            while (heap[p].length && root(heap[p].front.edge.to) == p) {
                heap[p].removeFront;
            }
            assert(heap[p].length);
            E mi = heap[p].front;
            res[p] = mi;
            p = root(mi.edge.to);
        }
    }
    foreach (i; 0..n) {
        if (used[i]) continue;
        mark(i.to!int);
    }

    auto info = DirectedMSTInfo!(_E, D)(n);
    bool[] vis = new bool[pc];
    foreach_reverse (i; 0..pc) {
        if (i == r) continue;
        if (vis[i]) continue;
        int f = res[i].from.to!int;
        while (f != -1 && !vis[f]) {
            vis[f] = true;
            f = tr[f];
        }
        info.cost += res[i].edge.dist;
        info.res[res[i].from] = res[i].edge;
    }
    return info;
}



import dkh.algorithm;
import dkh.graph.primitive;
struct DirectedMSTInfo(E, C) {
    C cost;
    E[] res;
    this(size_t n) {
        cost = C(0);
        res = new E[n];
    }
}



DirectedMSTInfo!(E, typeof(E.dist)) directedMSTSlow(T, E = EdgeType!T)(T g, size_t r) {
    import std.algorithm : filter;
    auto n = g.length;
    auto info = DirectedMSTInfo!(E, typeof(E.dist))(n);
    with (info) {
        foreach (i; 0..n) {
            if (i == r) continue;
            assert(g[i].filter!(e => e.to != i).empty == false);
            res[i] = g[i].filter!(e => e.to != i).minimum!"a.dist < b.dist";
            cost += res[i].dist;
        }
        int[] i2g = new int[n]; i2g[] = -1;
        i2g[r] = 0;
 
        int gc = 1;
        for (int i = 0; i < n; i++) {
            if (i2g[i] != -1) continue;
            int j = i;
            do {
                i2g[j] = gc++;
                j = res[j].to;
            } while (i2g[j] == -1);
            if (i2g[j] < i2g[i]) continue;
            //roop
            int k = j;
            do {
                i2g[k] = i2g[j];
                k = res[k].to;
            } while(k != j);
            gc = i2g[j]+1;
        }
        if (gc == n) return info;
        E[][] ng = new E[][](gc);
        for (int i = 0; i < n; i++) {
            if (i == r) continue;
            foreach (e; g[i]) {
                if (i2g[e.to] == i2g[i]) continue;
                e.to = i2g[e.to];
                e.dist = e.dist - res[i].dist;
                ng[i2g[i]] ~= e;
            }
        }
        auto nme = directedMSTSlow(ng, 0).res;
        bool[] ok = new bool[gc];
        for (int i = 0; i < n; i++) {
            if (i == r || ok[i2g[i]]) continue;
            foreach (e; g[i]) {
                import std.math;
                immutable typeof(EdgeType!T.dist) EPS = cast(typeof(EdgeType!T.dist))(1e-9);
                if (abs(e.dist - res[i].dist - nme[i2g[i]].dist) <= EPS && i2g[e.to] == nme[i2g[i]].to) {
                    ok[i2g[i]] = true;
                    res[i] = e;
                    cost += nme[i2g[i]].dist;
                    break;
                }
            }
        }
 
    }
    return info;
}

unittest {
    import std.typecons;
    alias E = Tuple!(int, "to", int, "dist");

    E[][] g = new E[][4];
    g[0] ~= E(1, 10);
    g[2] ~= E(1, 10);
    g[3] ~= E(1, 3);
    g[2] ~= E(3, 4);
    auto info = directedMSTSlow(g, 1);
    assert(info.cost == 17);
}

unittest {
    import std.range, std.algorithm, std.typecons, std.random, std.conv;
    alias E = Tuple!(int, "to", int, "dist");
    auto gen = Random(114514);
    void test() {
        size_t n = uniform(1, 20, gen);
        size_t m = uniform(1, 100, gen);
        E[][] g = new E[][n];
        foreach (i; 0..m) {
            auto a = uniform(0, n, gen);
            auto b = uniform(0, n, gen);
            int c = uniform(0, 15, gen);
            g[a] ~= E(b.to!int, c);
            g[b] ~= E(a.to!int, c);
        }
        size_t r = uniform(0, n, gen);
        foreach (i; 0..n) {
            g[i] ~= E(r.to!int, 10^^6);
        }

        bool check(I)(I info) {
            import dkh.datastructure.unionfind;
            auto uf = UnionFind(n.to!int);
            int sm = 0;
            foreach (i; 0..n) {
                if (i == r) continue;
                sm += info.res[i].dist;
                if (!g[i].count(info.res[i])) return false;
                if (uf.same(i, info.res[i].to)) return false;
                uf.merge(i, info.res[i].to);
            }
            if (sm != info.cost) return false;
            return true;
        }
        auto info1 = directedMSTSlow(g, r);
        auto info2 = directedMST(g, r);

        if (!check(info1)) {
            writeln("EEEEE");
            writeln(r);
            writeln(g.map!(to!string).join("\n"));
            writeln(info1);
            writeln(info2);
        }
        assert(check(info1));
        if (info1.cost != info2.cost || !check(info2)) {
            writeln("FIND ERROR!");
            writeln(r);
            writeln(g.map!(to!string).join("\n"));
            writeln(info1);
            writeln(info2);
        }
        assert(info1.cost == info2.cost);
    }
    import dkh.stopwatch;
    auto ti = benchmark!(test)(1000);
    writeln("DirectedMST int Random1000: ", ti[0].toMsecs);
}

unittest {
    import std.range, std.algorithm, std.typecons, std.random, std.conv, std.math;
    alias E = Tuple!(int, "to", double, "dist");
    auto gen = Random(114514);
    void test() {
        size_t n = uniform(1, 20, gen);
        size_t m = uniform(1, 100, gen);
        E[][] g = new E[][n];
        foreach (i; 0..m) {
            auto a = uniform(0, n, gen);
            auto b = uniform(0, n, gen);
            double c = uniform(0.0, 15.0, gen);
            g[a] ~= E(b.to!int, c);
            g[b] ~= E(a.to!int, c);
        }
        size_t r = uniform(0, n, gen);
        foreach (i; 0..n) {
            g[i] ~= E(r.to!int, 10^^6);
        }

        bool check(I)(I info) {
            import dkh.datastructure.unionfind;
            auto uf = UnionFind(n.to!int);
            double sm = 0;
            foreach (i; 0..n) {
                if (i == r) continue;
                sm += info.res[i].dist;
                if (!g[i].count(info.res[i])) return false;
                if (uf.same(i, info.res[i].to)) return false;
                uf.merge(i, info.res[i].to);
            }
            if (abs(sm - info.cost) > 1e-4) return false;
            return true;
        }
        auto info1 = directedMSTSlow(g, r);

        auto info2 = directedMST(g, r);

        if (!check(info1)) {
            writeln("EEEEE");
            writeln(r);
            writeln(g.map!(to!string).join("\n"));
            writeln(info1);
            writeln(info2);
        }
        assert(check(info1));
        if (abs(info1.cost - info2.cost) > 1e-4 || !check(info2)) {
            writeln("FIND ERROR!");
            writeln(r);
            writeln(g.map!(to!string).join("\n"));
            writeln(info1);
            writeln(info2);
        }
        assert(abs(info1.cost - info2.cost) <= 1e-4);
    }
    import dkh.stopwatch;
    auto ti = benchmark!(test)(1000);
    writeln("DirectedMST double Random1000: ", ti[0].toMsecs);
}
