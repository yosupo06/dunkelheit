module dcomp.container.radixheap;

import dcomp.foundation;
import dcomp.container.stack;


import std.functional : unaryFun;
import std.traits : isSigned, isUnsigned;

template RadixHeap(T, alias _pred = "a")
if (isSigned!(typeof(unaryFun!_pred(T())))) {
    import std.traits : Unsigned;
    alias pred = unaryFun!_pred;
    alias S = typeof(pred(T()));
    alias U = Unsigned!S;
    U pred2(in T x) {
        return pred(x) ^ (U(1) << (U.sizeof*8-1));
    }
    alias RadixHeap = RadixHeap!(T, pred2);
}

import core.bitop;

struct RadixHeap(T, alias _pred = "a")
if (isUnsigned!(typeof(unaryFun!_pred(T())))) {
    import std.algorithm;
    import core.exception : RangeError;
    alias pred = unaryFun!_pred;
    alias U = typeof(pred(T()));
    static int bsr1(U x) {
        return (x == 0) ? 0 : bsr(x)+1;
    }
    static struct Payload {
        StackPayload!T[U.sizeof*8+1] v;
        size_t length;
        U last;
        void insert(T p) {
            U x = pred(p);
            assert(last <= x);
            length++;
            v[bsr1(x^last)] ~= p;
        }
        bool empty() const {
            return length == 0;
        }
        T front() {
            if (!v[0].length) {
                int i = 1;
                while (!v[i].length) i++;
                last = v[i].data[].map!pred.fold!"min(a, b)";
                foreach (T p; v[i].data) {
                    v[bsr1(pred(p)^last)] ~= p;
                }
                v[i].clear();
            }
            return v[0].data[$-1];
        }
        void removeFront() {
            front();
            length--;
            v[0].removeBack();
        }        
    }
    Payload* p;
    private void I() { if (!p) p = new Payload(); }
    private void C() const {
        version(assert) if (!p) throw new RangeError();
    }
    void insert(T x) {I; p.insert(x); }
    @property bool empty() const { return (p == null || p.empty); }
    @property size_t length() const { return (p ? p.length : 0); }
    T front() {C; return p.front; }
    void removeFront() {I; p.removeFront(); }
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
