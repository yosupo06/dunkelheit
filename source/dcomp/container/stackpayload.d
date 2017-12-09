module dcomp.container.stackpayload;

/**
Stack Payload

If you don't need dark speed, you should use dcomp.container.stack
 */
struct StackPayload(T, size_t MINCAP = 4) if (MINCAP >= 1) {
    import core.exception : RangeError;

    private T* _data;
    private uint len, cap;

    @property bool empty() const { return len == 0; }
    @property size_t length() const { return len; }
    alias opDollar = length;

    /**
    Data Slice
    Warning: Return value points same place with stackpayload
     */
    inout(T)[] data() inout { return (_data) ? _data[0..len] : null; }
    
    ref inout(T) opIndex(size_t i) inout {
        version(assert) if (len <= i) throw new RangeError();
        return _data[i];
    } ///
    ref inout(T) front() inout { return this[0]; } ///
    ref inout(T) back() inout { return this[$-1]; } ///

    void reserve(size_t newCap) {
        import core.memory : GC;
        import core.stdc.string : memcpy;
        import std.conv : to;
        if (newCap <= cap) return;
        void* newData = GC.malloc(newCap * T.sizeof);
        cap = newCap.to!uint;
        if (len) memcpy(newData, _data, len * T.sizeof);
        _data = cast(T*)(newData);
    } ///
    void free() {
        import core.memory : GC;
        GC.free(_data);
    } ///
    /// This method don't release memory
    void clear() {
        len = 0;
    }

    void insertBack(T item) {
        import std.algorithm : max;
        if (len == cap) reserve(max(cap * 2, MINCAP));
        _data[len++] = item;
    } ///
    alias opOpAssign(string op : "~") = insertBack; /// ditto
    void removeBack() {
        assert(!empty, "StackPayload.removeBack: Stack is empty");
        len--;
    } ///
}

unittest {
    import std.algorithm : equal;
    auto u = StackPayload!int();
    u ~= 4; u ~= 5;
    assert(equal(u.data, [4, 5]));
}
