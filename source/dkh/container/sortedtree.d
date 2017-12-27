module dkh.container.sortedtree;

struct SortedTreePayload(T, alias less) {
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
            } else {
                if (!ch[1]) ch[1] = new Node(x);
                else ch[1] = ch[1].insert(x);
                ch[1].par = &this;
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
    alias at = opIndex;
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


unittest {
    import std.random;
    import std.algorithm;
    import std.conv;
    import std.container.rbtree;
    import std.stdio;
    import std.range;

    import dkh.stopwatch;
    StopWatch sw; sw.start;
    auto nv = redBlackTree!(true, int)([]);
    auto tr = SortedTreePayload!(int, (a, b) => a<b)();
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
            assert(u.front == tr.at(i));
            int x = tr.at(i);
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
    writeln("Set TEST: ", sw.peek.toMsecs);
}
