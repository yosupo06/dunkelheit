module dkh.container.sortedtree;

struct SortedTreePayload(T, alias less, bool allowDuplicates = false) {
    alias NP = Node*;
    static struct Node {
        NP[2] ch; NP par;
        uint len;
        immutable T v;
        this(T v) {
            len = 1;
            this.v = v;
        }
        uint chLength(uint ty) const {
            return ch[ty] ? ch[ty].len : 0;
        }
        uint chWeight(uint ty) const {
            return chLength(ty) + 1;
        }
        void update() {
            len = 1 + chLength(0) + chLength(1);
        }
        NP rot(uint ty) {
            NP n = ch[ty]; n.par = par;
            ch[ty] = n.ch[1-ty];
            if (ch[ty]) ch[ty].par = &this;
            n.ch[1-ty] = &this; par = n;
            update(); n.update();
            return n;
        }
        NP balanced() {
            foreach (f; 0..2) {
                if (chWeight(f) * 2 <= chWeight(1-f) * 5) continue;
                if (ch[f].chWeight(1-f) * 2 > chWeight(1-f) * 5 ||
                    ch[f].chWeight(f) * 5 < (ch[f].chWeight(1-f) + chWeight(1-f)) * 2) {
                    ch[f] = ch[f].rot(1-f);
                    ch[f].par = &this;
                    update();
                }
                return rot(f);
            }
            return &this;
        }
        NP insert(in T x) {
            if (less(x, v)) {
                if (!ch[0]) ch[0] = new Node(x);
                else ch[0] = ch[0].insert(x);
                ch[0].par = &this;
            } else if (allowDuplicates || less(v, x)) {
                if (!ch[1]) ch[1] = new Node(x);
                else ch[1] = ch[1].insert(x);
                ch[1].par = &this;
            } else {
                return &this;
            }
            update();
            return balanced();
        }
        T at(uint i) const {
            if (i < chLength(0)) return ch[0].at(i);
            else if (i == chLength(0)) return v;
            else return ch[1].at(i - chLength(0) - 1);
        }
        NP[2] removeBegin() { //[new child, removed node]
            if (!ch[0]) return [ch[1], &this];
            auto u = ch[0].removeBegin;
            ch[0] = u[0];
            if (ch[0]) ch[0].par = &this;
            update();
            return [balanced(), u[1]];
        }
        NP removeAt(uint i) {
            if (i < chLength(0)) {
                ch[0] = ch[0].removeAt(i);
                if (ch[0]) ch[0].par = &this;
            } else if (i > chLength(0)) {
                ch[1] = ch[1].removeAt(i - chLength(0) - 1);
                if (ch[1]) ch[1].par = &this;
            } else {
                if (!ch[1]) return ch[0];
                auto u = ch[1].removeBegin;
                auto n = u[1];
                n.ch[0] = ch[0];
                n.ch[1] = u[0];
                if (n.ch[0]) n.ch[0].par = n;
                if (n.ch[1]) n.ch[1].par = n;
                n.update();
                return n.balanced();
            }
            update();
            return balanced();
        }
        NP removeKey(in T x) {
            if (less(x, v)) {
                if (!ch[0]) return &this;
                ch[0] = ch[0].removeKey(x);
                if (ch[0]) ch[0].par = &this;
            } else if (less(v, x)) {
                if (!ch[1]) return &this;
                ch[1] = ch[1].removeKey(x);
                if (ch[1]) ch[1].par = &this;
            } else {
                if (!ch[1]) return ch[0];
                auto u = ch[1].removeBegin;
                auto n = u[1];
                n.ch[0] = ch[0];
                n.ch[1] = u[0];
                if (n.ch[0]) n.ch[0].par = n;
                if (n.ch[1]) n.ch[1].par = n;
                n.update();
                return n.balanced();
            }
            update();
            return balanced();
        }
        uint lowerCount(in T x) {
            if (less(v, x)) {
                return chLength(0) + 1 + (!ch[1] ? 0 : ch[1].lowerCount(x));
            } else {
                return !ch[0] ? 0 : ch[0].lowerCount(x);
            }
        }
        void validCheck() {
            assert(len == chLength(0) + chLength(1) + 1);
            if (ch[0]) {
                assert(ch[0].par == &this);
                assert(!less(v, ch[0].v));
            }
            if (ch[1]) {
                assert(ch[1].par == &this);
                assert(!less(ch[1].v, v));
            }
            assert(chWeight(0) * 2 <= chWeight(1) * 5);
            assert(chWeight(1) * 2 <= chWeight(0) * 5);
            if (ch[0]) ch[0].validCheck();
            if (ch[1]) ch[1].validCheck();
        }
    }
    NP n;
    @property size_t length() const { return !n ? 0 : n.len; }
    void insert(in T x) {
        if (!n) n = new Node(x);
        else {
            n = n.insert(x);        
        }
        n.par = null;
    }
    T opIndex(size_t i) const {
        assert(i < length);
        return n.at(cast(uint)(i));
    }
    void removeAt(uint i) {
        assert(i < length);
        n = n.removeAt(i);
        if (n) n.par = null;
    }
    void removeKey(in T x) {
        if (n) n = n.removeKey(x);
        if (n) n.par = null;
    }
    size_t lowerCount(in T x) {
        return !n ? 0 : n.lowerCount(x);
    }
    void validCheck() {
        //for debug
        if (n) {
            assert(!n.par);
            n.validCheck();
        }
    }
}


/**
std.container.rbtree on weighted-balanced tree
 */
struct SortedTree(T, alias less, bool allowDuplicates = false) {
    alias Payload = SortedTreePayload!(T, less, allowDuplicates);
    Payload* _p;
    @property size_t empty() const { return !_p || _p.length == 0; }
    @property size_t length() const { return !_p ? 0 : _p.length; }
    alias opDollar = length;
    void insert(in T x) {
        if (!_p) _p = new Payload();
        _p.insert(x);
    }
    T opIndex(size_t i) const {
        assert(i < length);
        return (*_p)[i];
    }
    void removeAt(uint i) {
        assert(i < length);
        _p.removeAt(i);
    }
    void removeKey(in T x) {
        _p.removeKey(x);
    }
    size_t lowerCount(in T x) {
        return !_p ? 0 : _p.lowerCount(x);
    }
    void validCheck() {
        //for debug
        if (_p) _p.validCheck();
    }    
}

unittest {
    import std.random;
    import std.algorithm;
    import std.conv;
    import std.container.rbtree;
    import std.stdio;
    import std.range;

    void check(bool allowDup)() {
        auto nv = redBlackTree!(allowDup, int)([]);
        auto tr = SortedTreePayload!(int, (a, b) => a<b, allowDup)();
        foreach (ph; 0..10000) {
            int ty = uniform(0, 3);
            if (ty == 0) {
                int x = uniform(0, 100);
                nv.insert(x);
                tr.insert(x);
            } else if (ty == 1) {
                if (!nv.length) continue;
                int i = uniform(0, nv.length.to!int);
                auto u = nv[];
                foreach (_; 0..i) u.popFront();
                assert(u.front == tr[i]);
                int x = tr[i];
                nv.removeKey(x);
                if (uniform(0, 2) == 0) {
                    tr.removeAt(i);
                } else {
                    tr.removeKey(x);
                }
            } else {
                int x = uniform(0, 101);
                assert(nv.lowerBound(x).array.length == tr.lowerCount(x));
            }
            tr.validCheck();
            assert(nv.length == tr.length);
        }
    }
    import dkh.stopwatch;
    StopWatch sw; sw.start;
    check!true();
    check!false();
    writeln("Set TEST: ", sw.peek.toMsecs);
}


unittest {
    import std.random;
    import std.algorithm;
    import std.conv;
    import std.container.rbtree;
    import std.stdio;
    import std.range;

    void check(bool allowDup)() {
        auto nv = redBlackTree!(allowDup, int)([]);
        auto tr = SortedTree!(int, (a, b) => a<b, allowDup)();
        foreach (ph; 0..10000) {
            int ty = uniform(0, 3);
            if (ty == 0) {
                int x = uniform(0, 100);
                nv.insert(x);
                tr.insert(x);
            } else if (ty == 1) {
                if (!nv.length) continue;
                int i = uniform(0, nv.length.to!int);
                auto u = nv[];
                foreach (_; 0..i) u.popFront();
                assert(u.front == tr[i]);
                int x = tr[i];
                nv.removeKey(x);
                if (uniform(0, 2) == 0) {
                    tr.removeAt(i);
                } else {
                    tr.removeKey(x);
                }
            } else {
                int x = uniform(0, 101);
                assert(nv.lowerBound(x).array.length == tr.lowerCount(x));
            }
            tr.validCheck();
            assert(nv.length == tr.length);
        }
    }
    import dkh.stopwatch;
    StopWatch sw; sw.start;
    check!true();
    check!false();
    writeln("Set TEST: ", sw.peek.toMsecs);
}
