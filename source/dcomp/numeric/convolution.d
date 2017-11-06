module dcomp.numeric.convolution;

/// Zeta変換
T[] zeta(T)(T[] v, bool rev) {
    import core.bitop : bsr;
    int n = bsr(v.length);
    assert(1<<n == v.length);
    foreach (fe; 0..n) {
        foreach (i, _; v) {
            if (i & (1<<fe)) continue;
            if (!rev) {
                v[i] += v[i|(1<<fe)];
            } else {
                v[i] -= v[i|(1<<fe)];
            }
        }
    }
    return v;
}

/// hadamard変換
T[] hadamard(T)(T[] v, bool rev) {
    import core.bitop : bsr;
    int n = bsr(v.length);
    assert(1<<n == v.length);
    foreach (fe; 0..n) {
        foreach (i, _; v) {
            if (i & (1<<fe)) continue;
            auto l = v[i], r = v[i|(1<<fe)];
            if (!rev) {
                v[i] = l+r;
                v[i|(1<<fe)] = l-r;
            } else {
                v[i] = (l+r)/2;
                v[i|(1<<fe)] = (l-r)/2;
            }
        }
    }
    return v;
}

import std.complex;

void fft(bool type)(Complex!double[] c) {
    import std.algorithm : swap;
    import std.math : PI, sin, cos;
    import core.bitop : bsr;
    alias P = Complex!double;
    size_t N = c.length;
    assert(N);
    size_t S = bsr(N);
    assert(1<<S == N);
    static P[][30] buf;
    if (!buf[S].length) {
        buf[S] = new P[N/2];
        foreach (i; 0..N/2) {
            buf[S][i].re = cos(i*2*double(PI)/N);
            buf[S][i].im = sin(i*2*double(PI)/N);
        }
    }
    P[] rot = buf[S];
    P[] a = c.dup, b = new P[c.length];
    foreach (i; 1..S+1) {
        size_t W = 1<<(S-i);
        for (size_t y = 0; y < N/2; y += W) {
            P now = rot[y];
            if (type) now = conj(now);
            foreach (x; 0..W) {
                auto l =       a[y<<1 | x];
                auto r = now * a[y<<1 | x | W];
                b[y | x]        = l+r;
                b[y | x | N>>1] = l-r;
            }
        }
        swap(a, b);
    }
    c[] = a[];
}

double[] multiply(double[] a, double[] b) {
    alias P = Complex!double;
    size_t A = a.length, B = b.length;
    if (!A || !B) return [];
    size_t lg = 1;
    while ((1<<lg) < A+B-1) lg++;
    size_t N = 1<<lg;
    P[] d = new P[N];
    d[] = P(0, 0);
    foreach (i; 0..A) d[i].re = a[i];
    foreach (i; 0..B) d[i].im = b[i];
    fft!false(d);
    foreach (i; 0..N/2+1) {
        auto j = i ? (N-i) : 0;
        P x = P(d[i].re+d[j].re, d[i].im-d[j].im);
        P y = P(d[i].im+d[j].im, -d[i].re+d[j].re);
        d[i] = x * y / 4;
        if (i != j) d[j] = conj(d[i]);
    }
    fft!true(d);
    double[] c = new double[A+B-1];
    foreach (i; 0..A+B-1) {
        c[i] = d[i].re / N;
    }
    return c;
}

unittest {
    import std.algorithm, std.datetime, std.stdio, std.random, std.math;
    StopWatch sw; sw.start;
    foreach (L; 1..20) {
        foreach (R; 1..20) {
            foreach (ph; 0..10) {
                double[] a = new double[L];
                double[] b = new double[R];
                a.each!((ref x) => x = 100*uniform01());
                b.each!((ref x) => x = 100*uniform01());
                double[] c1 = multiply(a, b);
                double[] c2 = new double[L+R-1]; c2[] = 0.0;
                foreach (i; 0..L) {
                    foreach (j; 0..R) {
                        c2[i+j] += a[i] * b[j];
                    }
                }
                assert(c1.length == c2.length);
                foreach (i; 0..L+R-1) {
                    assert(approxEqual(c1[i], c2[i]));
                }
            }
        }
    }
    writeln("FFT Stress: ", sw.peek.msecs);
}
