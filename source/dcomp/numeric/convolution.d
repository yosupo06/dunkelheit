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

double[] fftSinList(size_t S) {
    import std.math : PI, sin;
    assert(2 <= S);
    size_t N = 1<<S;
    static double[][30] buf;
    if (!buf[S].length) {
        buf[S] = new double[3*N/4+1];
        foreach (i; 0..N/4+1) {
            buf[S][i] = sin(i*2*double(PI)/N);
            buf[S][N/2-i] = buf[S][i];
            buf[S][N/2+i] = -buf[S][i];
        }
    }
    return buf[S];
}

void fft(bool type)(Complex!double[] c) {
    import std.algorithm : swap;
    import core.bitop : bsr;
    alias P = Complex!double;
    size_t N = c.length;
    assert(N);
    size_t S = bsr(N);
    assert(1<<S == N);
    if (S == 1) {
        auto x = c[0], y = c[1];
        c[0] = x+y;
        c[1] = x-y;
        return;
    }
    auto rot = fftSinList(S);
    P[] a = c.dup, b = new P[c.length];
    foreach (i; 1..S+1) {
        size_t W = 1<<(S-i);
        for (size_t y = 0; y < N/2; y += W) {
            P now = P(rot[y + N/4], rot[y]);
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
                foreach (ref x; a) x = 100 * uniform01;
                foreach (ref x; b) x = 100 * uniform01;
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

import dcomp.modint;

Mint[] multiply(Mint, size_t M = 3, size_t W = 10)(Mint[] a, Mint[] b)
if (isModInt!Mint) {
    import std.math : round;
    alias P = Complex!double;

    size_t A = a.length, B = b.length;
    if (!A || !B) return [];
    auto N = A + B - 1;
    size_t lg = 1;
    while ((1<<lg) < N) lg++;
    N = 1<<lg;

    P[][M] x, y;
    foreach (ph; 0..M) {
        x[ph] = new P[N];
        y[ph] = new P[N];
        P[] z = new P[N]; z[] = P(0, 0);
        foreach (i; 0..A) z[i].re = (a[i].v >> (ph*W)) % (1<<W);
        foreach (i; 0..B) z[i].im = (b[i].v >> (ph*W)) % (1<<W);
        fft!false(z);
        foreach (i; 0..N) z[i] *= 0.5;
        foreach (i; 0..N) {
            auto j = i ? N-i : 0;
            x[ph][i] = P(z[i].re+z[j].re,  z[i].im-z[j].im);
            y[ph][i] = P(z[i].im+z[j].im, -z[i].re+z[j].re);
        }
    }
    P[][M] z;
    foreach (i; 0..M) {
        z[i] = new P[N]; z[i][] = P(0, 0);
    }
    foreach (af; 0..M) {
        foreach (bf; 0..M) {
            auto cf = af+bf;
            if (cf >= M) cf -= M;
            foreach (i; 0..N) {
                if (af + bf < M) {
                    z[cf][i] += x[af][i]*y[bf][i];
                } else {
                    z[cf][i] += x[af][i]*y[bf][i]*P(0, 1);
                }
            }
        }
    }
    foreach (i; 0..M) fft!true(z[i]);

    Mint[] c = new Mint[A+B-1];
    Mint base = 1;
    foreach (ph; 0..2*M-1) {
        foreach (i; 0..A+B-1) {
            if (ph < M) {
                z[ph][i].re *= 1.0/N;
                c[i] += Mint(cast(long)(round(z[ph][i].re)))*base;
            } else {       
                z[ph-M][i].im *= 1.0/N;
                c[i] += Mint(cast(long)(round(z[ph-M][i].im)))*base;
            }
        }
        base *= Mint(1<<W);
    }
    return c;
}

unittest {
    alias Mint = ModInt!(10^^9 + 7);
    import std.algorithm, std.datetime, std.stdio, std.random, std.math;
    StopWatch sw; sw.start;
    Mint rndM() { return Mint(uniform(0, 10^^9 + 7)); }
    foreach (L; 1..20) {
        foreach (R; 1..20) {
            foreach (ph; 0..10) {
                Mint[] a = new Mint[L];
                Mint[] b = new Mint[R];
                foreach (ref x; a) x = rndM();
                foreach (ref x; b) x = rndM();
                Mint[] c1 = multiply(a, b);
                Mint[] c2 = new Mint[L+R-1];
                foreach (i; 0..L) {
                    foreach (j; 0..R) {
                        c2[i+j] += a[i] * b[j];
                    }
                }
                assert(c1.length == c2.length);
                foreach (i; 0..L+R-1) {
                    if (c1[i] != c2[i]) {
                        writeln(a);
                        writeln(b);
                        writeln(c1);
                        writeln(c2);
                    }
                    assert(c1[i] == c2[i]);
                }
            }
        }
    }
    writeln("FFT(ModInt) Stress: ", sw.peek.msecs);    
}
