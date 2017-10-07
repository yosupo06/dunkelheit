module dcomp.container.pairingheap;

import dcomp.array;

struct PairingHeapPayload(T, alias opCmp) {
    import std.range : iota;
    import std.algorithm : swap;
    alias NP = Node*;
    static struct Node {        
        T d;
        FastAppender!(NP[]) ch;
        this(T d) {
            this.d = d;
        }
    }
    size_t length;
    NP n;
    bool empty() {
        return length == 0;
    }
    static NP merge(NP x, NP y) {
        assert(x && y);
        if (opCmp(x.d, y.d)) swap(x, y);
        x.ch ~= y;
        return x;
    }
    void insert(T x) {
        length++;
        if (!n) n = new Node(x);
        else n = merge(n, new Node(x));
    }
    T front() {
        assert(n);
        return n.d;
    }
    void removeFront() {
        assert(n);
        assert(length > 0);
        length--;
        auto m = n.ch.length;                
        NP x;
        if (m % 2) {
            x = n.ch.back;
        }
        foreach_reverse (i; iota(0, m/2*2, 2)) {
            auto y = merge(n.ch[i], n.ch[i+1]);
            if (!x) x = y;
            else x = merge(x, y);
        }
        n = x;
    }
}

struct PairingHeap(T, alias _opCmp) {
    import std.stdio;
    import std.functional : binaryFun;
    alias opCmp = binaryFun!_opCmp;
    alias Payload = PairingHeapPayload!(T, opCmp);
    Payload* p;
    void I() { if (!p) p = new Payload(); }
    bool empty() { return !p || p.empty(); }
    size_t length() { return (!p) ? 0 : p.length; }
    void insert(T x) {
        I();
        assert(p);
        p.insert(x);
    }
    T front() {
        assert(p);
        return p.front;
    }
    void removeFront() {
        assert(p);
        p.removeFront;
    }
    void meld(PairingHeap r) {
        p.length += r.p.length;
        p.n = Payload.merge(p.n, r.p.n);
        r.p.n = null;
    }
}

unittest {
    import std.random, std.container.binaryheap, std.container.array;
    int f(T)(Random gen) {
        T t;
        int sm = 0;
        foreach (i; 0..1000) {
            int ty = uniform(0, 3, gen);
            if (ty == 0) {
                //push
                t.insert(uniform(0, 1000, gen));
            } else if (ty == 1) {
                //top
                if (t.length) sm ^= i * t.front;
            } else {
                //pop
                if (t.length) t.removeFront;
            }
        }
        return sm;
    }
    auto u = Random(unpredictableSeed);
    import std.stdio;
    writeln("Start PairingHeap 1000");
    foreach (i; 0..1000) {
        auto seed = u.front; u.popFront;
        assert(
            f!(PairingHeap!(int, "a<b"))(Random(seed)) ==
            f!(BinaryHeap!(Array!int))(Random(seed))
            );
    }
}
