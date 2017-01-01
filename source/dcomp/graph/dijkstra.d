module dcomp.graph.djikstra;

struct Dijkstra(T) {
    T[] dist;
}

Dijkstra!D dijkstra(D, T)(T g, int s, D inf = D.max) {
    import std.typecons : Tuple;
    import std.container.array;
    import std.container.binaryheap;
    import std.container.util : make;
    size_t V = g.length;
    Dijkstra!D dijk;
    dijk.dist.length = V;
    dijk.dist[] = inf;

    alias P = Tuple!(int, "to", D, "dist");
    auto q = heapify!"a.dist>b.dist"(make!(Array!P)([P(D(0), s)]));

    dijk.dist[s] = D(0);
    while (!q.empty) {
        P p = q.front; q.popFront();
        if (dijk.dist[p[1]] < p[0]) continue;
        foreach (e; g[p[1]]) {
            if (p[0]+e.dist < dijk.dist[e.to]) {
                dijk.dist[e.to] = p[0] + e.dist;
                q.insert(P(dijk.dist[e.to], e.to));
            }
        }
    }
    return dijk;
}
