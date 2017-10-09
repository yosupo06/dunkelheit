module dcomp.container.pairingheap;

struct PairingHeapPayload(T, alias opCmp) {
    import std.range : iota;
    import std.algorithm : swap;
    alias NP = Node*;
    static struct Node {        
        T d;
        NP head, next;
        this(T d) {
            this.d = d;
        }
    }
    NP n;
    size_t length;
    bool empty() const { return length == 0; }
    static NP merge(NP x, NP y) {
        if (!x) return y;
        if (!y) return x;
        if (opCmp(x.d, y.d)) swap(x, y);
        y.next = x.head;
        x.head = y;
        return x;
    }
    void insert(T x) {
        length++;
        if (!n) n = new Node(x);
        else n = merge(n, new Node(x));
    }
    T front() const {
        assert(n);
        return n.d;
    }
    void removeFront() {
        assert(n);
        assert(length > 0);
        length--;
        NP x;
        NP s = n.head;
        while (s) {
            NP a, b;
            a = s; s = s.next; a.next = null;
            if (s) {
                b = s; s = s.next; b.next = null;
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
}

struct PairingHeap(T, alias _opCmp) {
    import std.stdio;
    import std.functional : binaryFun;
    alias opCmp = binaryFun!_opCmp;
    alias Payload = PairingHeapPayload!(T, opCmp);
    Payload* p;
    void I() { if (!p) p = new Payload(); }
    bool empty() const { return !p || p.empty(); }
    size_t length() const { return (!p) ? 0 : p.length; }
    void insert(T x) {
        I();
        assert(p);
        p.insert(x);
    }
    T front() const {
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
