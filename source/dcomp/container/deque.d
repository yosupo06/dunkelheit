module dcomp.container.deque;

struct Deque(T) {
    T[] d = new T[](1);
    size_t st, length;
    @property bool empty() { return length == 0; }
    ref T opIndex(size_t i) {
        return d[(st+i >= d.length) ? (st+i-d.length) : st+i];
    }
    ref T front() { return d[0]; }
    ref T back() { return d[length-1]; }
    private void expand() {
        assert(length == d.length);
        T[] nd = new T[](2*d.length);
        foreach (i; 0..d.length) {
            nd[i] = this[i];
        }
        d = nd; st = 0;
    }
    void insertFront(T v) {
        if (length == d.length) expand();
        if (st == 0) st += d.length;
        st--; length++;
        this[0] = v; 
    }    
    void insertBack(T v) {
        if (length == d.length) expand();
        length++;
        this[length-1] = v; 
    }
    void removeFront() {
        assert(!empty, "Deque.removeFront: Deque is empty");        
        st++; length--;
        if (st == d.length) st = 0;
    }
    void removeBack() {
        assert(!empty, "Deque.removeBack: Deque is empty");        
        length--;
    }
}
