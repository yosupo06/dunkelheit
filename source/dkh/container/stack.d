module dkh.container.stack;

import dkh.container.stackpayload;

/// Stack
struct Stack(T) {
    import core.exception : RangeError;

    alias Payload = StackPayload!T;
    private Payload* p;

    import std.traits : isImplicitlyConvertible;
    import std.range : ElementType, isInputRange, hasLength;
    /// Stack(1, 2, 3)
    this(U)(U[] values...) if (isImplicitlyConvertible!(U, T)) {
        p = new Payload();
        p.reserve(values.length);
        foreach (v; values) this ~= v;
    }
    /// Stack(iota(3))
    this(Range)(Range r)
    if (isInputRange!Range &&
    isImplicitlyConvertible!(ElementType!Range, T) &&
    !is(Range == T[])) {
        p = new Payload();
        static if (hasLength!Range) p.reserve(r.length);
        foreach (v; r) this ~= v;
    }

    @property bool empty() const { return (!p || p.empty); } ///
    @property size_t length() const { return (p ? p.length : 0); } ///
    alias opDollar = length; /// ditto
    @property inout(T)[] data() inout { return (!p) ? [] : p.data; } ///

    ref inout(T) opIndex(size_t i) inout {
        assert(!empty, "Stack.opIndex: Stack is empty");
        return (*p)[i];
    } ///
    ref inout(T) front() inout { return this[0]; } ///
    ref inout(T) back() inout { return this[$-1]; } ///
    
    void clear() { if (p) p.clear(); } ///

    void insertBack(T item) {
        if (!p) p = new Payload();
        p.insertBack(item);
    } ///
    alias opOpAssign(string op : "~") = insertBack; /// ditto
    alias stableInsertBack = insertBack; /// ditto
    void removeBack() {
        assert(!empty, "Stack.removeBack: Stack is empty");
        p.removeBack();
    } ///
    alias stableRemoveBack = removeBack; /// ditto

    /// Random-access range
    alias Range = RangeT!(StackPayload!T);
    alias ConstRange = RangeT!(const StackPayload!T); /// ditto
    alias ImmutableRange = RangeT!(immutable StackPayload!T); /// ditto

    size_t[2] opSlice(size_t dim : 0)(size_t start, size_t end) const {
        assert(start <= end && end <= length);
        return [start, end];
    } ///
    Range opIndex(size_t[2] rng) { return Range(p, rng[0], rng[1]); } /// Get slice
    ConstRange opIndex(size_t[2] rng) const { return ConstRange(p, rng[0], rng[1]); } /// ditto
    ImmutableRange opIndex(size_t[2] rng) immutable { return ImmutableRange(p, rng[0], rng[1]); } /// ditto
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
    import std.range.primitives : isRandomAccessRange;
    import std.container.util : make;
    auto q = Stack!int();

    assert(equal(q[], new int[0]));
    q.insertBack(1);
    assert(equal(q[], [1]));
    q.insertBack(2);
    assert(equal(q[], [1, 2]));
    q.insertBack(3);
    assert(equal(q[], [1, 2, 3]));
    q.removeBack();
    assert(equal(q[], [1, 2]));
    q.insertBack(4);
    assert(equal(q[], [1, 2, 4]));
    q.removeBack();
    assert(equal(q[], [1, 2]));
}

unittest {
    import std.range;
    auto q1 = Stack!int(1, 2, 3);
    auto q2 = Stack!int(iota(3));
}

unittest {
    import std.algorithm : equal;
    auto q = Stack!int(1, 2, 3, 4, 5);
    assert(equal(q[1..4], [2, 3, 4]));
    assert(q[1..4][1] == 3);
    const auto rng = q[1..4];
    assert(rng.front == 2 && rng.back == 4);
    assert(equal(rng[0..3], [2, 3, 4]));
    assert(equal(rng[], [2, 3, 4]));
}

unittest {
    import std.range : isRandomAccessRange;
    static assert(isRandomAccessRange!(Stack!int.Range));
    static assert(isRandomAccessRange!(Stack!int.ConstRange));
    static assert(isRandomAccessRange!(Stack!int.ImmutableRange));
}
