module dkh.container.radixheap;

import dkh.container.stackpayload;

import std.functional : unaryFun;
import std.traits : isSigned, isUnsigned;

/**
Radix Heap
 */
template RadixHeap(T, alias pred = "a") {
    alias _pred = unaryFun!pred; // pred(value) = key
    alias K = typeof(_pred(T())); // key type
    ///
    static if (isUnsigned!K) {
        // unsigned

        struct RadixHeap {
            static struct Payload {
                StackPayload!T[K.sizeof*8+1] v;
                size_t len;
                K last;

                // bsr(x) + 1
                private static int bsr1(K x) {
                    import core.bitop : bsr;
                    return (x == 0) ? 0 : bsr(x)+1;
                }
                private void assign(T item) {
                    K key = _pred(item);
                    assert(last <= key);
                    v[bsr1(key^last)] ~= item;
                }
                private void pull() {
                    import std.range, std.algorithm;
                    if (v[0].length) return;
                    auto i = iota(K.sizeof*8+1).find!(a => v[a].length).front;
                    // reassign v[i]
                    last = v[i].data[].map!_pred.reduce!min;
                    v[i].data.each!(a => assign(a));
                    v[i].clear();
                }

                void insert(T item) {
                    len++;
                    assign(item);
                }
                T front() {
                    pull();
                    return v[0].back;
                }
                void removeFront() {
                    pull();
                    len--;
                    v[0].removeBack();
                }
            }
            Payload* p;

            @property bool empty() const { return (!p || p.len == 0); } ///
            @property size_t length() const { return (!p ? 0 : p.len); } ///
            alias opDollar = length; /// ditto

            /// Warning: return minimum
            T front() {
                assert(!empty, "RadixHeap.front: heap is empty");
                return p.front;
            }
            void insert(T item) {
                if (!p) p = new Payload();
                p.insert(item);
            } ///
            void removeFront() {
                assert(!empty, "RadixHeap.removeFront: heap is empty");
                p.removeFront();
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
