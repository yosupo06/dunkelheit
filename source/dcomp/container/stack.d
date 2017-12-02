module dcomp.container.stack;

struct StackPayload(T, size_t MIN = 4) {
    import std.algorithm : max;
    import std.conv;
    import std.range.primitives : ElementEncodingType;
    import core.stdc.string : memcpy;

    private T* _data;
    private uint len, cap;
    /// length
    bool empty() const { return len == 0; }
    @property size_t length() const { return len; }
    alias opDollar = length;

    ref inout(T) opIndex(size_t i) inout { return _data[i]; }
    ref inout(T) front() inout { return _data[0]; }
    ref inout(T) back() inout { assert(len); return _data[len-1]; }
    
    /// C++のreserveと似たようなもの
    void reserve(size_t nlen) {
        import core.memory : GC;
        if (nlen <= cap) return;
        
        void* nx = GC.malloc(nlen * T.sizeof);

        cap = nlen.to!uint;
        if (len) memcpy(nx, _data, len * T.sizeof);
        _data = cast(T*)(nx);
    }
    void free() {
        import core.memory : GC;
        GC.free(_data);
    }
    /// 追加演算子
    void opOpAssign(string op : "~")(T item) {
        if (len == cap) {
            reserve(max(MIN, cap*2));
        }
        _data[len++] = item;
    }
    /// 末尾に追加
    void insertBack(T item) {
        this ~= item;
    }
    /// 末尾を削除
    void removeBack() {
        len--;
    }
    /// C++のvectorと似ている, 要素は空になるがメモリへの参照は手放さない
    void clear() {
        len = 0;
    }
    /**
    これで返した配列も, 元のStackPayloadに操作すると壊れる.
    必要ならばdupしておくこと.
    */
    T[] data() {
        return (_data) ? _data[0..len] : null;
    }
}

unittest {
    import std.algorithm : equal;
    auto u = StackPayload!int();
    u ~= 4; u ~= 5;
    assert(equal(u.data, [4, 5]));
}

//todo: add stack
