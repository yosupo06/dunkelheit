module dcomp.container.stack;

import dcomp.container.stackpayload;

struct Stack(T) {
    import core.exception : RangeError;
    import core.memory : GC;
    import std.range : ElementType, isInputRange;
    import std.traits : isImplicitlyConvertible;

    alias Payload = StackPayload!T;
    alias Range = Payload.Range;
    alias ConstRange = Payload.ConstRange;
    alias ImmutableRange = Payload.ImmutableRange;
    
    Payload* p;
    private void I() { if (!p) p = new Payload(); }
    private void C() const {
        version(assert) if (!p) throw new RangeError();
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
    static Stack make() { return Stack(new Payload()); }
    @property bool havePayload() const { return (p !is null); }
    /// 空かどうか取得
    @property bool empty() const { return (!havePayload || p.empty); }
    /// 長さを取得
    @property size_t length() const { return (havePayload ? p.length : 0); }
    @property inout(T)[] data() inout {C; return (!p) ? [] : p.data; }
    /// ditto
    alias opDollar = length;
    ref inout(T) opIndex(size_t i) inout {C; return (*p)[i]; }
    /// 先頭要素
    ref inout(T) front() inout {C; return (*p)[0]; }
    /// 末尾要素
    ref inout(T) back() inout {C; return (*p)[$-1]; }
    void clear() { if (p) p.clear(); }
    /// 末尾に追加
    void insertBack(T v) {I; p.insertBack(v); }
    /// ditto
    alias stableInsertBack = insertBack;
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
    auto q = Stack!int();

    //insert,remove
    assert(equal(q[], new int[](0)));
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
