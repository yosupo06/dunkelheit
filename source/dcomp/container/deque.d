module dcomp.container.deque;

struct Deque(T) {
    import std.range.primitives : ElementType;

    struct Payload {
        T[] d;
        size_t st, length;
        @property bool empty() { return length == 0; }
        ref T opIndex(size_t i) {
            assert(i < length);
            return d[(st+i >= d.length) ? (st+i-d.length) : st+i];
        }
        ref T front() { return d[st]; }
        ref T back() {
            size_t pre = st+length-1;
            return (pre < d.length) ? d[pre] : d[pre-d.length];
        }
        private void expand() {
            import std.algorithm : max;
            assert(length == d.length);
            T[] nd = new T[](max(4L, 2*d.length));
            foreach (i; 0..d.length) {
                nd[i] = this[i];
            }
            d = nd; st = 0;
        }
        void insertFront(T v) {
            if (length == d.length) expand();
            if (st == 0) st += d.length;
            st--; length++;
            this[0] = v; 
        }
        void insertBack(T v) {
            if (length == d.length) expand();
            length++;
            this[length-1] = v; 
        }
        void removeFront() {
            assert(!empty, "Deque.removeFront: Deque is empty");        
            st++; length--;
            if (st == d.length) st = 0;
        }
        void removeBack() {
            assert(!empty, "Deque.removeBack: Deque is empty");        
            length--;
        }        
    }
    struct RangeT(T) {
        typeof(T.p) p;
        int now;
        bool empty() { return p.length <= now; }
        auto ref front() { return (*p)[now]; }
        auto ref back() { return p.back; }
        void popFront() { now++; }
        auto save() {
            return this;
        }
    }
    
    alias Range = RangeT!Deque;

    Payload *p = new Payload;
    this(Range)(Range r)
    if (is(ElementType!Range == T)) {
        foreach (v; r) {
            insertBack(v);
        }
    }
    @property bool empty() { return p.empty; }
    ref T opIndex(size_t i) { return (*p)[i]; }
    ref T front() { return p.front; }
    ref T back() { return p.back; }
    void insertFront(T v) { p.insertFront(v); }
    void insertBack(T v) { p.insertBack(v); }
    void removeFront() { p.removeFront(); }
    void removeBack() { p.removeBack(); }
    Range opSlice() { return Range(p, 0); }
}

unittest {
    import std.algorithm : equal;
    Deque!int q;
    assert(equal(q[], new int[](0)));
    q.insertBack(1);
    assert(equal(q[], [1]));
    q.insertBack(2);
    assert(equal(q[], [1, 2]));
    q.insertFront(3);
    assert(q.front == 3);
    assert(equal(q[], [3, 1, 2]));
    q.removeFront;
    q.insertBack(4);
    assert(q.front == 1);
    assert(equal(q[], [1, 2, 4]));
    q.insertFront(5);
    assert(equal(q[], [5, 1, 2, 4]));
    auto q2 = q;
    q2.insertBack(6);
    q2.insertFront(7);
    assert(equal(q[], q2[]));
}
