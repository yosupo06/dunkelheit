module dcomp.container.radixheap;

import dcomp.container.stackpayload;

import std.functional : unaryFun;
import std.traits : isSigned, isUnsigned;

/**
Radix Heap
 */
template RadixHeap(T, alias pred = "a") {
    alias _pred = unaryFun!pred; // _pred(value) = key
    alias K = typeof(_pred(T())); // key type
    ///
    static if (isUnsigned!K) {
        // unsigned

        struct RadixHeap {
            static struct Payload {
                StackPayload!T[K.sizeof*8+1] _v;
                size_t _len;
                K _last;

                // bsr(x) + 1
                private static int bsr1(K x) {
                    import core.bitop : bsr;
                    return (x == 0) ? 0 : bsr(x)+1;
                }
                private void assign(T item) {
                    K key = _pred(item);
                    assert(_last <= key);
                    _v[bsr1(key^_last)] ~= item;
                }
                private void pull() {
                    import std.range, std.algorithm;
                    if (_v[0].length) return;
                    auto i = iota(K.sizeof*8+1).find!(a => _v[a].length).front;
                    // reassign _v[i]
                    _last = _v[i].data[].map!pred.reduce!min;
                    _v[i].data.each!(a => assign(a));
                    _v[i].clear();
                }

                void insert(T item) {
                    _len++;
                    assign(item);
                }
                T front() {
                    pull();
                    return _v[0].back;
                }
                void removeFront() {
                    pull();
                    _len--;
                    _v[0].removeBack();
                }
            }
            Payload* _p;

            @property bool empty() const { return (!_p || _p._len == 0); } ///
            @property size_t length() const { return (!_p ? 0 : _p._len); } ///
            alias opDollar = length; /// ditto

            /// Warning: return minimum
            T front() {
                assert(!empty, "RadixHeap.front: heap is empty");
                return _p.front;
            }
            void insert(T item) {
                if (!_p) _p = new Payload();
                _p.insert(item);
            } ///
            void removeFront() {
                assert(!empty, "RadixHeap.removeFront: heap is empty");
                _p.removeFront();
            } ///
        }
    } else static if (isSigned!K) {
        // signed
        import std.traits : Unsigned;
        static Unsigned!K pred2(in T item) {
            return _pred(item) ^ (K(1) << (K.sizeof*8 - 1));
        }
        alias RadixHeap = RadixHeap!(T, pred2);
    } else {
        static assert(false);
    }
}

///
unittest {
    RadixHeap!int q;
    q.insert(2);
    q.insert(1);
    assert(q.front == 1);
    q.removeFront();
    assert(q.front == 2);
}

unittest {
    import std.algorithm;
    import std.random;
    void test(T)() {
        RadixHeap!T q;
        T[] a = new T[100];
        a.each!((ref x) => x = uniform!"[]"(T.min, T.max));
        foreach (i; 0..100) {
            q.insert(a[i]);
        }
        a.sort!"a<b";
        foreach (i; 0..100) {
            assert(q.front() == a[i]);
            q.removeFront();
        }
    }
    test!ubyte();
    test!ushort();
    test!uint();
    test!ulong();

    test!byte();
    test!short();
    test!int();
    test!long();
}

unittest {
    RadixHeap!int r;
    r.insert(100);
    auto r2 = r;
    r2.insert(10);
    assert(r.length == 2);
    r.removeFront();
    assert(r2.length == 1);
}
