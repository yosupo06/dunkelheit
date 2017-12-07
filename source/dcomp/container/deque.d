module dcomp.container.deque;

struct DequePayload(T) {
    import core.exception : RangeError;

    private T* _data;
    private uint _start, _len, _cap;

    @property bool empty() const { return _len == 0; }
    @property size_t length() const { return _len; }
    alias opDollar = length;

    ref inout(T) opIndex(size_t i) inout {
        version(assert) if (_len <= i) throw new RangeError();
        if (_start + i < _cap) return _data[_start + i];
        else return _data[_start + i - _cap];
    }
    ref inout(T) front() inout { return this[0]; }
    ref inout(T) back() inout { return this[$-1]; }

    void reserve(size_t newCap) {
        import core.memory : GC;
        import std.algorithm : max;
        import std.conv : to;
        if (newCap <= _cap) return;
        T* newData = cast(T*)GC.malloc(newCap * T.sizeof);
        foreach (i; 0..length) {
            newData[i] = this[i];
        }
        _data = newData; _start = 0; _cap = newCap.to!uint;
    }
    void clear() {
        _start = _len = 0;
    }
    import std.algorithm : max;
    void insertFront(T item) {
        if (_len == _cap) reserve(max(_cap * 2, 4));
        if (_start == 0) _start += _cap;
        _start--; _len++;
        this[0] = item;
    }
    void insertBack(T item) {
        if (_len == _cap) reserve(max(_cap * 2, 4));
        _len++;
        this[_len-1] = item;
    }
    void removeFront() {
        assert(!empty, "Deque.removeFront: Deque is empty");
        _start++; _len--;
        if (_start == _cap) _start = 0;
    }
    void removeBack() {
        assert(!empty, "Deque.removeBack: Deque is empty");        
        _len--;
    }
}

/**
Deque on ring buffer
 */
struct Deque(T, bool mayNull = true) {
    import core.exception : RangeError;
    import core.memory : GC;
    import std.range : ElementType, isInputRange;
    import std.traits : isImplicitlyConvertible;

    alias Payload = DequePayload!T;
    Payload* _p;
    
    static if (!mayNull) @disable this();

    /// Deque(1, 2, 3)
    this(U)(U[] values...) if (isImplicitlyConvertible!(U, T)) {
        _p = new Payload();
        foreach (v; values) {
            insertBack(v);
        }
    }
    /// Deque(iota(3))
    this(Range)(Range r)
    if (isInputRange!Range &&
    isImplicitlyConvertible!(ElementType!Range, T) &&
    !is(Range == T[])) {
        _p = new Payload();
        foreach (v; r) {
            insertBack(v);
        }
    }
    private this(Payload* p) { _p = p; }
    static Deque make() { return Deque(new Payload()); }
    
    private bool havePayload() const { return (!mayNull || _p); }    
    @property bool empty() const { return (!havePayload || _p.empty); } ///
    @property size_t length() const { return (havePayload ? _p.length : 0); } ///
    alias opDollar = length; /// ditto

    ref inout(T) opIndex(size_t i) inout {
        assert(!empty, "Deque.opIndex: Deque is empty");
        return (*_p)[i];
    } ///
    ref inout(T) front() inout { return this[0]; } ///
    ref inout(T) back() inout { return this[$-1]; } ///

    void clear() { if (_p) _p.clear(); } ///

    /// Warning: break range
    void insertFront(T v) {
        if (mayNull && !_p) _p = new Payload();
        _p.insertFront(v);
    }
    void insertBack(T v) {
        if (mayNull && !_p) _p = new Payload();
        _p.insertBack(v);
    } ///
    alias opOpAssign(string op : "~") = insertBack; /// ditto
    alias stableInsertBack = insertBack; /// ditto

    /// Warning: break range
    void removeFront() {
        assert(!mayNull || _p, "Deque.removeFront: Deque is empty");
        _p.removeFront();
    }
    void removeBack() {
        assert(!mayNull || _p, "Deque.removeBack: Deque is empty");
        _p.removeBack();
    } ///
    alias stableRemoveBack = removeBack; /// ditto

    /// Random-access range    
    alias Range = RangeT!(DequePayload!T);
    alias ConstRange = RangeT!(const DequePayload!T); /// ditto
    alias ImmutableRange = RangeT!(immutable DequePayload!T); /// ditto

    size_t[2] opSlice(size_t dim : 0)(size_t start, size_t end) const {
        assert(start <= end && end <= length);
        return [start, end];
    } ///
    Range opIndex(size_t[2] rng) { return Range(_p, rng[0], rng[1]); } /// Get slice
    ConstRange opIndex(size_t[2] rng) const { return ConstRange(_p, rng[0], rng[1]); } /// ditto
    ImmutableRange opIndex(size_t[2] rng) immutable { return ImmutableRange(_p, rng[0], rng[1]); } /// ditto
    auto opIndex() inout { return this[0..$]; } /// ditto

    static struct RangeT(QualifiedPayload) {
        alias A = QualifiedPayload;
        import std.traits : CopyTypeQualifiers;
        alias E = CopyTypeQualifiers!(A, T);
        A *p;
        size_t l, r;

        @property bool empty() const { return r <= l; }
        @property size_t length() const { return r - l; }
        alias opDollar = length;

        @property auto save() { return this; }
        
        ref inout(E) opIndex(size_t i) inout {
            version(assert) if (empty) throw new RangeError();
            return (*p)[l+i];
        }
        @property ref inout(E) front() inout { return this[0]; }
        @property ref inout(E) back() inout { return this[$-1]; }

        void popFront() {
            version(assert) if (empty) throw new RangeError();
            l++;
        }
        void popBack() {
            version(assert) if (empty) throw new RangeError();
            r--;
        }
        
        size_t[2] opSlice(size_t dim : 0)(size_t start, size_t end) const {
            assert(start <= end && end <= length);
            return [start, end];
        }
        auto opIndex(size_t[2] rng) { return RangeT(p, l+rng[0], l+rng[1]); }
        auto opIndex(size_t[2] rng) const { return RangeT!(const A)(p, l+rng[0], l+rng[1]); }
        auto opIndex(size_t[2] rng) immutable { return RangeT!(immutable A)(p, l+rng[0], l+rng[1]); }
        auto opIndex() inout { return this[0..$]; }
    } 
}

///
unittest {
    import std.algorithm : equal;
    auto q = Deque!int();

    assert(equal(q[], new int[0]));
    q.insertBack(1);
    assert(equal(q[], [1]));
    q.insertBack(2);
    assert(equal(q[], [1, 2]));
    q.insertFront(3);
    assert(equal(q[], [3, 1, 2]));
    q.removeFront;
    assert(equal(q[], [1, 2]));
    q.insertBack(4);
    assert(equal(q[], [1, 2, 4]));
    q.insertFront(5);
    assert(equal(q[], [5, 1, 2, 4]));
    q.removeBack();
    assert(equal(q[], [5, 1, 2]));
}

unittest {
    import std.algorithm : equal;
    import std.range.primitives : isRandomAccessRange;
    import std.container.util : make;
    auto q = Deque!int();
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
    static assert( is(typeof(Deque!(int, true)())));
    static assert(!is(typeof(Deque!(int, false)())));
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
