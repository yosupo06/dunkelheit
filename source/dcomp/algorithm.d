module dcomp.algorithm;

//[0,0,0,...,1,1,1]で、初めて1となる場所を探す。pred(l) == 0, pred(r) == 1と仮定
template binSearch(alias pred) {
    T binSearch(T)(T l, T r) {
        while (r-l > 1) {
            int md = (l+r)/2;
            if (!pred(md)) l = md;
            else r = md;
        }
        return r;
    }
}
