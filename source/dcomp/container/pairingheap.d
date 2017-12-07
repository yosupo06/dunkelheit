module dcomp.container.pairingheap;

private NP meldPairingHeapNode(alias less, NP)(NP x, NP y) {
    import std.algorithm : swap;
    if (!x) return y;
    if (!y) return x;
    if (less(x._item, y._item)) swap(x, y);
    y._next = x._head;
    x._head = y;
    return x;
}

///
struct PairingHeap(T, alias less = "a < b") {
    import std.functional : binaryFun;
    private alias _less = binaryFun!less;

    private alias NP = Node*;
    private static struct Node {
        T _item;
        NP _head, _next;
        this(T item) {
            _item = item;
        }
    }

    private struct Payload {
        import std.algorithm : swap;
        private NP _node;
        private uint _len;

        void insert(T item) {
            _len++;
            _node = meldPairingHeapNode!_less(_node, new Node(item));
        }
        inout(T) front() inout { return _node._item; }
        void removeFront() {
            _len--;

            NP s = _node._head;
            NP t;
            // merge and reverse: (s, s.next, s.next.next, ...)
            // result: (..., t.next.next, t.next, t)
            while (s) {
                // pop first 2 nodes
                NP first, second;
                first = s; s = s._next; first._next = null;
                if (s) {
                    second = s; s = s._next; second._next = null;
                }
                // merge 2 nodes and insert front of t
                auto v = meldPairingHeapNode!_less(first, second);
                v._next = t;
                t = v;
            }
            _node = null;
            // merge t
            while (t) {
                NP first = t; t = t._next; first._next = null;
                _node = meldPairingHeapNode!_less(first, _node);
            }
        }
        void meld(Payload* r) {
            _len += r._len; r._len = 0;
            _node = meldPairingHeapNode!_less(_node, r._node);
            r._node = null;
        }
    }
    private Payload* _p;

    @property bool empty() const { return !_p || _p._len == 0; } ///
    @property size_t length() const { return (!_p) ? 0 : _p._len; } ///

    void insert(T item) {
        if (!_p) _p = new Payload();
        _p.insert(item);
    } ///
    inout(T) front() inout {
        assert(!empty, "PairingHeap.front: heap is empty");
        return _p.front;
    } ///
    void removeFront() {
        assert(!empty, "PairingHeap.removeFront: heap is empty");
        _p.removeFront;
    } ///
    /**
    meld two heaps
    Warning: r become empty
    */
    void meld(PairingHeap r) { _p.meld(r._p); }
}

///
unittest {
    auto p1 = PairingHeap!int();
    auto p2 = PairingHeap!int();

    p1.insert(1);
    p1.insert(2);
    assert(p1.front == 2);

    p2.insert(3);
    assert(p2.front == 3);

    p1.meld(p2);
    assert(p1.length == 3 && !p2.length);

    assert(p1.front == 3); p1.removeFront();
    assert(p1.front == 2); p1.removeFront();
    assert(p1.front == 1); p1.removeFront();
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
    import dcomp.stopwatch;
    StopWatch sw; sw.start;
    foreach (i; 0..1000) {
        auto seed = u.front; u.popFront;
        assert(
            f!(PairingHeap!(int, "a<b"))(Random(seed)) ==
            f!(BinaryHeap!(Array!int))(Random(seed))
            );
    }
    import std.stdio;
    writeln("Start PairingHeap 1000: ", sw.peek.toMsecs);
}

unittest {
    auto cost(int i) {
        return i;
    }
    auto que = PairingHeap!(int, (a, b) => cost(a) < cost(b))();
    que.insert(10);
    que.removeFront();
}
