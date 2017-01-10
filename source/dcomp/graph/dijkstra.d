module dcomp.graph.djikstra;

import dcomp.algorithm;

struct Dijkstra(T) {
    T[] dist;
    int[] from;
    this(int n, T inf) {
        dist = new T[n]; dist[] = inf;
        from = new int[n];
    }
}

Dijkstra!D dijkstra(D, T)(T g, int s, D inf = D.max) {
    import std.conv : to;
    import std.typecons : Tuple;
    import std.container : make, Array, heapify;

    int V = g.length.to!int;
    auto dijk = Dijkstra!D(V, inf);
    with (dijk) {        
        alias P = Tuple!(int, "to", D, "dist");
        auto q = heapify!"a.dist>b.dist"(make!(Array!P)([P(s, D(0))]));

        dist[s] = D(0);
        from[s] = -1;
        while (!q.empty) {
            P p = q.front; q.popFront();
            if (dist[p.to] < p.dist) continue;
            foreach (e; g[p.to]) {
                if (p.dist+e.dist < dist[e.to]) {
                    dist[e.to] = p.dist+e.dist;
                    from[e.to] = p.to;
                    q.insert(P(e.to, dist[e.to]));
                }
            }
        }
    }
    return dijk;
}

Dijkstra!D dijkstraDense(D, T)(T g, int s, D inf = D.max) {
    import std.conv : to;
    import std.typecons : Tuple;
    import std.container : make, Array, heapify;
    import std.range : enumerate;
    import std.algorithm : filter;

    int V = g.length.to!int;
    auto dijk = Dijkstra!D(V, inf);
    with (dijk) {
        alias P = Tuple!(int, "to", D, "dist");

        bool[] used = new bool[](V);
        dist[s] = D(0);
        from[s] = -1;
        while (true) {
            //todo can optimize
            auto rng = dist.enumerate.filter!(a => !used[a.index]);
            if (rng.empty) break;
            auto nx = rng.minimum!"a.value < b.value";
            used[nx.index] = true;
            P p = P(nx.index.to!int, nx.value); 
            if (dist[p.to] < p.dist) continue;
            foreach (e; g[p.to]) {
                if (p.dist+e.dist < dist[e.to]) {
                    dist[e.to] = p.dist+e.dist;
                    from[e.to] = p.to;
                }
            }
        }
    }
    return dijk;
}

unittest {
    import std.algorithm, std.conv, std.stdio, std.range;
    import std.random;
    import std.typecons;
    import std.datetime;

    alias E = Tuple!(int, "to", int, "dist");

    writeln("Dijkstra Random100000");
    void f(alias pred)() {
        int n = uniform(1, 100);
        int m = uniform(1, 1000);
        E[][] g = new E[][n];
        int[][] dist = new int[][](n, n);
        foreach (i, ref v; dist) {
            v[] = 10^^9;
        }
        iota(n).each!(i => dist[i][i] = 0);
        foreach (i; 0..m) {
            int a = uniform(0, n);
            int b = uniform(0, n);
            int c = uniform(0, 1000);
            g[a] ~= E(b, c);
            dist[a][b] = min(dist[a][b], c);
        }
        foreach (k; 0..n) {
            foreach (i; 0..n) {
                foreach (j; 0..n) {
                    dist[i][j] = min(dist[i][j], dist[i][k]+dist[k][j]);
                }
            }
        }
        foreach (i; 0..n) {
            auto dijk = pred!int(g, i, 10^^9);
            foreach (j; 0..n) {
                assert(dist[i][j] == dijk.dist[j]);
            }
            assert(dijk.from[i] == -1);
            foreach (j; 0..n) {
                if (i == j) continue;
                if (dist[i][j] == 10^^9) continue;
                int b = dijk.from[j];
                assert(dijk.dist[j] == dist[i][b]+dist[b][j]);
            }
        }
    }
    auto ti = benchmark!(f!dijkstra, f!dijkstraDense)(100);
    writeln(ti[0].msecs, "ms");
    writeln(ti[1].msecs, "ms");
}
