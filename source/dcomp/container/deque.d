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
    void insertFront(T v) {
        if (_len == _cap) reserve(max(_cap * 2, 4));
        if (_start == 0) _start += _cap;
        _start--; _len++;
        this[0] = v; 
    }
    void insertBack(T v) {
        if (_len == _cap) reserve(max(_cap * 2, 4));
        _len++;
        this[_len-1] = v; 
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
Deque リングバッファ実装でDListより速い
 */
struct Deque(T, bool mayNull = true) {
    import core.exception : RangeError;
    import core.memory : GC;
    import std.range : ElementType, isInputRange;
    import std.traits : isImplicitlyConvertible;

    alias Payload = DequePayload!T;
//    alias Range = Payload.Range;
//    alias ConstRange = Payload.ConstRange;
//    alias ImmutableRange = Payload.ImmutableRange;
    
    alias Range = RangeT!(DequePayload!T);
    alias ConstRange = RangeT!(const DequePayload!T);
    alias ImmutableRange = RangeT!(immutable DequePayload!T);

    static struct RangeT(A) {
        import std.traits : CopyTypeQualifiers;
        alias E = CopyTypeQualifiers!(A, T);
        A *p;
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
    /// 空かどうか取得
    @property bool empty() const { return (!havePayload || p.empty); }
    /// 長さを取得
    @property size_t length() const { return (havePayload ? p.length : 0); }
    /// ditto
    alias opDollar = length;
    ref inout(T) opIndex(size_t i) inout {C; return (*p)[i]; }
    /// 先頭要素
    ref inout(T) front() inout {C; return (*p)[0]; }
    /// 末尾要素
    ref inout(T) back() inout {C; return (*p)[$-1]; }
    void clear() { if (p) p.clear(); }
    /// 先頭に追加 rangeが壊れるので注意
    void insertFront(T v) {I; p.insertFront(v); }
    /// 末尾に追加
    void insertBack(T v) {I; p.insertBack(v); }
    /// ditto
    alias stableInsertBack = insertBack;
    /// 先頭を削除 rangeが壊れるので注意
    void removeFront() {C; p.removeFront(); }
    /// 末尾を削除
    void removeBack() {C; p.removeBack(); }
    /// 全体のrangeを取得
    Range opSlice() {I; return Range(p, 0, length); }
}

///
unittest {
    import std.algorithm : equal;
    import std.range.primitives : isRandomAccessRange;
    import std.container.util : make;
    auto q = Deque!int();

    //insert,remove
    assert(equal(q[], new int[](0)));
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
