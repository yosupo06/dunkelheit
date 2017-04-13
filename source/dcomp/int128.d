module dcomp.int128;

version(LDC) {
    import dcomp.ldc.inline;
}

version(LDC) version(X86_64) {
    version = LDC_IR;
}

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
        import std.bigint, std.conv;
        return ((BigInt(a[0].to!string) + (BigInt(a[1].to!string) << 64)) / BigInt(b.to!string)).to!string.to!ulong;
    }    
}
