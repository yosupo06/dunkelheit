module dcomp.container.deque;

struct Deque(T) {
    import std.traits : isImplicitlyConvertible;
    import std.range : ElementType, isInputRange;
    import core.exception : RangeError;

    struct Payload {
        T[] d;
        size_t st, length;
        @property bool empty() const { return length == 0; }
        alias opDollar = length;
        ref inout(T) opIndex(size_t i) inout {
            version(assert) if (length <= i) throw new RangeError();
            return d[(st+i >= d.length) ? (st+i-d.length) : st+i];
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
    struct RangeT(A) {
        alias T = typeof(*(A.p));
        alias E = typeof(A.p.d[0]);
        T *p;
        size_t a, b;
        @property bool empty() const { return b <= a; }
        @property size_t length() const { return b-a; }
        @property RangeT save() { return RangeT(p, a, b); }
        @property RangeT!(const A) save() const {
            return typeof(return)(p, a, b);
        }
        alias opDollar = length;
        @property ref inout(E) front() inout { return (*p)[a]; }
        @property ref inout(E) back() inout { return (*p)[b-1]; }
        void popFront() {
            version(assert) if (empty) throw new RangeError();
            a++;
        }
        void popBack() {
            version(assert) if (empty) throw new RangeError();
            b--;
        }
        ref inout(E) opIndex(size_t i) inout { return (*p)[i]; }
        RangeT opSlice() { return this.save; }
        RangeT opSlice(size_t i, size_t j) {
            version(assert) if (i > j || a + j > b) throw new RangeError();
            return typeof(return)(p, a+i, a+j);
        }
        RangeT!(const A) opSlice() const { return this.save; }
        RangeT!(const A) opSlice(size_t i, size_t j) const {
            version(assert) if (i > j || a + j > b) throw new RangeError();
            return typeof(return)(p, a+i, a+j);
        }
    }
    
    alias Range = RangeT!Deque;
    alias ConstRange = RangeT!(const Deque);
    alias ImmutableRange = RangeT!(immutable Deque);

    Payload *p = new Payload;
    //some value
    this(U)(U[] values...) if (isImplicitlyConvertible!(U, T)) {
        foreach (v; values) {
            insertBack(v);
        }
    }
    //range
    this(Range)(Range r)
    if (isInputRange!Range &&
        isImplicitlyConvertible!(ElementType!Range, T) &&
        !is(Range == T[])) {
        foreach (v; r) {
            insertBack(v);
        }
    }
    
    @property bool empty() const { return p.empty; }
    @property size_t length() const { return p.length; }
    ref inout(T) opIndex(size_t i) inout { return (*p)[i]; }
    ref inout(T) front() inout { return (*p)[0]; }
    ref inout(T) back() inout { return (*p)[$-1]; }
    void insertFront(T v) { p.insertFront(v); }
    void insertBack(T v) { p.insertBack(v); }
    void removeFront() { p.removeFront(); }
    void removeBack() { p.removeBack(); }
    Range opSlice() { return Range(p, 0, length); }
}

unittest {
    import std.algorithm : equal;
    import std.range.primitives : isRandomAccessRange;
    import std.container.util : make;
    Deque!int q;
    assert(isRandomAccessRange!(typeof(q[])));

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
    assert(q.back == 4);
    assert(equal(q[], [1, 2, 4]));
    q.insertFront(5);
    assert(equal(q[], [5, 1, 2, 4]));
    assert(equal(q[][1..3], [1, 2]));
    const auto rng = q[];
    assert(rng.front == 5 && rng.back == 4);
    auto q2 = q;
    q2.insertBack(6);
    q2.insertFront(7);
    assert(equal(q[], q2[]));
    assert(equal(q[][][][], q[]));
    assert(q[].length == q2[].length);
    auto a = make!(Deque!int)(1, 2, 3);
    auto b = make!(Deque!int)([1, 2, 3]);
    assert(equal(a[], b[]));
}
