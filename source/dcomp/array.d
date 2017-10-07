module dcomp.array;

/// 静的配列のリテラルであると明示的に指定する
T[N] fixed(T, size_t N)(T[N] a) {return a;}

///
unittest {
    auto a = [[1, 2].fixed];
    assert(is(typeof(a) == int[2][]));
}

/**
std.array.appenderをより高速化したもの.

参照型のように動くが, コピーした後に操作するとそれ以外の参照が全部壊れる.
ブロック外に出さない一時バッファのような使い方を想定している.
速度が重要でないならばstd.array.appenderを使うこと.
 */
struct FastAppender(A) {
    import std.algorithm : max;
    import std.range.primitives : ElementEncodingType;
    import core.stdc.string : memcpy;

    private alias T = ElementEncodingType!A;
    private T* _data;
    private size_t len, cap;
    /// length
    @property size_t length() const {return len;}
    bool empty() const { return len == 0; }
    /// C++のreserveと似たようなもの
    void reserve(size_t nlen) {
        import core.memory : GC;
        if (nlen <= cap) return;
        
        void* nx = GC.malloc(nlen * T.sizeof);

        cap = nlen;
        if (len) memcpy(nx, _data, len * T.sizeof);
        _data = cast(T*)(nx);
    }
    /// 追加演算子
    void opOpAssign(string op : "~")(T item) {
        if (len == cap) {
            reserve(max(4, cap*2));
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
    ref inout(T) back() inout { assert(len); return _data[len-1]; }
    ref inout(T) opIndex(size_t i) inout { return _data[i]; }
    /**
    これで返した配列も, 元のFastAppenderに操作すると壊れる.
    必要ならばdupしておくこと.
    */
    T[] data() {
        return (_data) ? _data[0..len] : null;
    }
}

///
unittest {
    import std.stdio, std.algorithm;
    auto u = FastAppender!(int[])();
    u ~= 4; u ~= 5;
    assert(equal(u.data, [4, 5]));
}
