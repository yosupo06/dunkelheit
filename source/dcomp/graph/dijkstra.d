module dcomp.graph.djikstra;

import dcomp.algorithm;

struct Dijkstra(T) {
    T[] dist;
}

Dijkstra!D dijkstra(D, T)(T g, size_t s, D inf = D.max) {
    import std.typecons : Tuple;
    import std.container : make, Array, heapify;

    size_t V = g.length;
    Dijkstra!D dijk;
    with (dijk) {
        dist = new D[](V); dist[] = inf;
        
        alias P = Tuple!(size_t, "to", D, "dist");
        auto q = heapify!"a.dist>b.dist"(make!(Array!P)([P(s, D(0))]));

        dist[s] = D(0);
        while (!q.empty) {
            P p = q.front; q.popFront();
            if (dist[p.to] < p.dist) continue;
            foreach (e; g[p.to]) {
                if (p.dist+e.dist < dist[e.to]) {
                    dist[e.to] = p.dist+e.dist;
                    q.insert(P(e.to, dist[e.to]));
                }
            }
        }
    }
    return dijk;
}

Dijkstra!D dijkstraDense(D, T)(T g, size_t s, D inf = D.max) {
    import std.typecons : Tuple;
    import std.container : make, Array, heapify;
    import std.range : enumerate;
    import std.algorithm : filter;

    size_t V = g.length;
    Dijkstra!D dijk;
    with (dijk) {
        dist = new D[](V); dist[] = inf;
        
        alias P = Tuple!(size_t, "to", D, "dist");

        bool[] used = new bool[](V);
        dist[s] = D(0);
        while (true) {
            //todo can optimize
            auto rng = dist.enumerate.filter!(a => !used[a.index]);
            if (rng.empty) break;
            auto nx = rng.minimum!"a.value < b.value";
            used[nx.index] = true;
            P p = P(nx.index, nx.value); 
            if (dist[p.to] < p.dist) continue;
            foreach (e; g[p.to]) {
                if (p.dist+e.dist < dist[e.to]) {
                    dist[e.to] = p.dist+e.dist;
                }
            }
        }
    }
    return dijk;
}
