module dcomp.container.deque;

struct Deque(T, bool mayNull = true) {
    import core.exception : RangeError;
    import core.memory : GC;
    import std.range : ElementType, isInputRange;
    import std.traits : isImplicitlyConvertible;

    struct Payload {
        T *d;
        size_t st, length, cap;
        @property bool empty() const { return length == 0; }
        alias opDollar = length;
        ref inout(T) opIndex(size_t i) inout {
            version(assert) if (length <= i) throw new RangeError();
            return d[(st+i >= cap) ? (st+i-cap) : st+i];
        }
        private void expand() {
            import std.algorithm : max;
            assert(length == cap);
            auto nc = max(size_t(4), 2*cap);
            T* nd = cast(T*)GC.malloc(nc * T.sizeof);
            foreach (i; 0..length) {
                nd[i] = this[i];
            }
            d = nd; st = 0; cap = nc;
        }
        void clear() {
            st = length = 0;
        }
        void insertFront(T v) {
            if (length == cap) expand();
            if (st == 0) st += cap;
            st--; length++;
            this[0] = v; 
        }
        void insertBack(T v) {
            if (length == cap) expand();
            length++;
            this[length-1] = v; 
        }
        void removeFront() {
            assert(!empty, "Deque.removeFront: Deque is empty");        
            st++; length--;
            if (st == cap) st = 0;
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

    Payload* p;
    private void I() { if (mayNull && !p) p = new Payload(); }
    private void C() const {
        version(assert) if (mayNull && !p) throw new RangeError();
    }
    static if (!mayNull) {
        @disable this();
    }
    //some value
    private this(Payload* p) {
        this.p = p;
    }
    this(U)(U[] values...) if (isImplicitlyConvertible!(U, T)) {
        p = new Payload();
        foreach (v; values) {
            insertBack(v);
        }
    }
    //range
    this(Range)(Range r)
    if (isInputRange!Range &&
    isImplicitlyConvertible!(ElementType!Range, T) &&
    !is(Range == T[])) {
        p = new Payload();
        foreach (v; r) {
            insertBack(v);
        }
    }
    static Deque make() { return Deque(new Payload()); }
    @property bool havePayload() const { return (!mayNull || p); }
    @property bool empty() const { return (!havePayload || p.empty); }
    @property size_t length() const { return (havePayload ? p.length : 0); }
    alias opDollar = length;
    ref inout(T) opIndex(size_t i) inout {C; return (*p)[i]; }
    ref inout(T) front() inout {C; return (*p)[0]; }
    ref inout(T) back() inout {C; return (*p)[$-1]; }
    void clear() { if (p) p.clear(); }
    void insertFront(T v) {I; p.insertFront(v); }
    void insertBack(T v) {I; p.insertBack(v); }
    void removeFront() {C; p.removeFront(); }
    void removeBack() {C; p.removeBack(); }
    Range opSlice() {I; return Range(p, 0, length); }
}

unittest {
    import std.algorithm : equal;
    import std.range.primitives : isRandomAccessRange;
    import std.container.util : make;
    auto q = make!(Deque!int);
    assert(isRandomAccessRange!(typeof(q[])));

    //insert,remove
    assert(equal(q[], new int[](0)));
    q.insertBack(1);
    assert(equal(q[], [1]));
    q.insertBack(2);
    assert(equal(q[], [1, 2]));
    q.insertFront(3);
    assert(equal(q[], [3, 1, 2]) && q.front == 3);
    q.removeFront;
    assert(equal(q[], [1, 2]) && q.length == 2);
    q.insertBack(4);
    assert(equal(q[], [1, 2, 4]) && q.front == 1 && q.back == 4 && q[$-1] == 4);
    q.insertFront(5);
    assert(equal(q[], [5, 1, 2, 4]));

    //range
    assert(equal(q[][1..3], [1, 2]));
    assert(equal(q[][][][], q[]));
    //const range
    const auto rng = q[];
    assert(rng.front == 5 && rng.back == 4);
    
    //reference type
    auto q2 = q;
    q2.insertBack(6);
    q2.insertFront(7);
    assert(equal(q[], q2[]) && q.length == q2.length);

    //construct with make
    auto a = make!(Deque!int)(1, 2, 3);
    auto b = make!(Deque!int)([1, 2, 3]);
    assert(equal(a[], b[]));
}

unittest {
    import std.algorithm : equal;
    import std.range.primitives : isRandomAccessRange;
    import std.container.util : make;
    auto q = make!(Deque!int);
    q.clear();
    assert(equal(q[], new int[0]));
    foreach (i; 0..100) {
        q.insertBack(1);
        q.insertBack(2);
        q.insertBack(3);
        q.insertBack(4);
        q.insertBack(5);    
        assert(equal(q[], [1,2,3,4,5]));
        q.clear();
        assert(equal(q[], new int[0]));
    }
}

unittest {
    Deque!(int, false) q1 = Deque!(int, false).make();
    q1.insertBack(3);
    assert(q1[0] == 3);
    Deque!(int, false) q2 = Deque!(int, false)(4, 2);
    assert(q2[0] == 4);
    Deque!(int, false) q3 = Deque!(int, false)([6, 9]);
    assert(q3[1] == 9);
}

unittest {
    Deque!int a;
    Deque!int b;
    a.insertFront(2);
    assert(b.length == 0);
}

unittest {
    import std.algorithm : equal;
    import std.range : iota;
    Deque!int a;
    foreach (i; 0..100) {
        a.insertBack(i);
    }
    assert(equal(a[], iota(100)));
}
