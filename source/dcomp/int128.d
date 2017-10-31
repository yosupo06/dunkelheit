/**
64bit op 64bit -> 128bit の乗算/除算ライブラリ

TODO : 32bit環境での除算を真面目に実装する
 */

module dcomp.int128;

import dcomp.array;

version(LDC) {
    import dcomp.ldc.inline;
}

version(LDC) version(X86_64) {
    version = LDC_IR;
}

/// a * b = (return[1]<<64) + return[0]
ulong[2] mul128(ulong a, ulong b) {
    ulong[2] res;
    version(LDC_IR) {
        ulong upper, lower;
        inlineIR!(`
            %r0 = zext i64 %0 to i128 
            %r1 = zext i64 %1 to i128
            %r2 = mul i128 %r1, %r0
            %r3 = trunc i128 %r2 to i64
            %r4 = lshr i128 %r2, 64
            %r5 = trunc i128 %r4 to i64
            store i64 %r3, i64* %2
            store i64 %r5, i64* %3`, void)(a, b, &lower, &upper);
        return [lower, upper];
    } else version(D_InlineAsm_X86_64) {
        ulong upper, lower;
        asm {
            mov RAX, a;
            mul b;
            mov lower, RAX;
            mov upper, RDX;
        }
        return [lower, upper];
    } else {
        ulong B = 2UL^^32;
        ulong[2] a2 = [a % B, a / B];
        ulong[2] b2 = [b % B, b / B];
        ulong[4] c;
        foreach (i; 0..2) {
            foreach (j; 0..2) {
                c[i+j] += a2[i] * b2[j] % B;
                c[i+j+1] += a2[i] * b2[j] / B;
            }
        }
        foreach (i; 0..3) {
            c[i+1] += c[i] / B;
            c[i] %= B;
        }
        return [c[0] + c[1] * B, c[2] + c[3] * B];
    }
}

unittest {
    import std.random, std.algorithm, std.datetime, std.stdio, std.conv;
    StopWatch sw; sw.start;
    writeln("Start mul128");
    ulong[2] naive_mul(ulong a, ulong b) {
        import std.bigint, std.conv;
        auto a2 = BigInt(a), b2 = BigInt(b);
        auto c = a2*b2;
        auto m = BigInt(1)<<64;
        return [(c % m).to!string.to!ulong, (c / m).to!string.to!ulong];
    }
    ulong[] li;
    foreach (i; 0..100) {
        li ~= i;
        li ~= ulong.max - i;
    }
    foreach (i; 0..100) {
        li ~= uniform(0UL, ulong.max);
    }
    foreach (l; li) {
        foreach (r; li) {
            assert(equal(mul128(l, r)[], naive_mul(l, r)[]));
        }
    }
    writefln("%dms", sw.peek.msecs);
}

/// [a[1], a[0]] / b = return, 答えが64bitに収まらないとヤバイ
ulong div128(ulong[2] a, ulong b) {
    version(LDC_IR) {
        return inlineIR!(`
            %r0 = zext i64 %0 to i128
            %r1 = zext i64 %1 to i128
            %r2 = shl i128 %r1, 64
            %r3 = add i128 %r0, %r2
            %r4 = zext i64 %2 to i128
            %r5 = udiv i128 %r3, %r4
            %r6 = trunc i128 %r5 to i64
            ret i64 %r6`,ulong)(a[0], a[1], b);
    } else version(D_InlineAsm_X86_64) {
        ulong upper = a[1], lower = a[0];
        ulong res;
        asm {
            mov RDX, upper;
            mov RAX, lower;
            div b;
            mov res, RAX;
        }
        return res;
    } else {
        if (b == 1) return a[0];
        while (!(b & (1UL << 63))) {
            a[1] <<= 1;
            if (a[0] & (1UL << 63)) a[1] |= 1;
            a[0] <<= 1;
            b <<= 1;
        }
        ulong ans = 0;
        foreach (i; 0..64) {
            bool up = (a[1] & (1UL << 63)) != 0;
            a[1] <<= 1;
            if (a[0] & (1UL << 63)) a[1] |= 1;
            a[0] <<= 1;

            ans <<= 1;
            if (up || b <= a[1]) {
                a[1] -= b;
                ans++;
            }
        }
        return ans;
    }
}


/// [a[1], a[0]] % b = return, 答えが64bitに収まらないとヤバイ
ulong mod128(ulong[2] a, ulong b) {
    version(D_InlineAsm_X86_64) {
        ulong upper = a[1], lower = a[0];
        ulong res;
        asm {
            mov RDX, upper;
            mov RAX, lower;
            div b;
            mov res, RDX;
        }
        return res;
    } else {
        return a[0] - div128(a, b) * b;
    }
}

unittest {
    import std.bigint, std.conv, std.datetime, std.stdio;
    import std.random, std.algorithm;
    StopWatch sw; sw.start;
    writeln("Start div128");
    bool overflow_check(ulong[2] a, ulong b) {
        auto a2 = (BigInt(a[1]) << 64) + BigInt(a[0]);
        return (a2 / b) > BigInt(ulong.max);
    }
    ulong naive_div(ulong[2] a, ulong b) {
        auto a2 = (BigInt(a[1]) << 64) + BigInt(a[0]);
        return (a2 / b).to!string.to!ulong;
    }
    ulong naive_mod(ulong[2] a, ulong b) {
        auto a2 = (BigInt(a[1]) << 64) + BigInt(a[0]);
        return (a2 % b).to!string.to!ulong;
    }    
    ulong[2][] li;
    ulong[] ri;
    foreach (i; 0..100) {
        li ~= [i, 0UL];
        li ~= [ulong.max - i, 0UL];
    }
    foreach (i; 0..100) {
        ri ~= i;
        ri ~= ulong.max - i;
    }
    foreach (i; 0..100) {
        li ~= [uniform(0UL, ulong.max), 0UL];
    }
    foreach (i; 0..100) {
        li ~= [uniform(0UL, ulong.max), uniform(0UL, ulong.max)];
    }    
    foreach (i; 0..100) {
        ri ~= uniform(0UL, ulong.max);
    }
    li ~= [0, ulong.max];
    li ~= [ulong.max, ulong.max-1];
    foreach (l; li) {
        foreach (r; ri) {
            if (r == 0) continue;
            if (overflow_check(l, r)) continue;
            if (div128(l, r) != naive_div(l, r)) {
                writeln("ERR ", l, " ", r, " ", div128(l, r), " ", naive_div(l, r));
            }
            assert(div128(l, r) == naive_div(l, r));
            assert(mod128(l, r) == naive_mod(l, r));
        }
    }
    writefln("%dms", sw.peek.msecs);
}
