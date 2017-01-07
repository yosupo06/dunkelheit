module dcomp.array;

import dcomp.memory;

struct FastAppender(A, bool useMyPool = false) {
    @disable this(this); //this is not reference type(don't copy!)

    import std.algorithm : max;
    import std.range.primitives : ElementEncodingType;
    import core.stdc.string : memcpy;

    private alias T = ElementEncodingType!A;
    private T* _data;
    private size_t len, cap;

    this(T[]* arr) {
        _data = (*arr).ptr;
        len = (*arr).length;
        cap = (*arr).length;
    }
    void reserve(size_t nlen) {
        import core.memory : GC;
        if (nlen <= cap) return;
        
        void* nx;
        static if (useMyPool) {
            nx = nowPool.malloc(nlen * T.sizeof);
        } else {
            nx = GC.malloc(nlen * T.sizeof);            
        }

        cap = nlen;
        if (len) memcpy(nx, _data, len * T.sizeof);
        _data = cast(T*)(nx);
    }
    void opOpAssign(string op : "~")(T item) {
        if (len == cap) {
            reserve(max(4, cap*2));
        }
        _data[len++] = item;
    }
    void clear() {
        len = 0;
    }    
    T[] data() {
        return (_data) ? _data[0..len] : null;
    }
}

T[N] fixed(T, int N)(T[N] a) {return a;}
