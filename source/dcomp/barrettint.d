module dcomp.barrettint;

version(LDC) {
    import dcomp.ldc.inline;
}

struct BarrettULong {
    ulong value, inv;
    this(ulong value) {
        this.value = value;
        if (value == 1) return;
        version(LDC) {
            inv = inlineIR!(`
                %r0 = zext i64 %0 to i128 
                %r1 = add i128 %r0, 18446744073709551615
                %r2 = udiv i128 %r1, %r0
                %r3 = trunc i128 %r2 to i64
                ret i64 %r3`, ulong)(value);
        } else version(D_InlineAsm_X86_64) {
            asm {
                mov RBX, this;
                mov RDX, 1;
                mov RAX, value;
                dec RAX;
                div value;
                mov inv[RBX], RAX;
            }
        } else {
            pragma(msg, "BarrettULong is slow in this environment");
        }
    }
    ulong opBinaryRight(string op:"/")(ulong x) const {
        assert(value != 0);
        if (value == 1) return x;
        ulong r;
        version(LDC) {
            r = inlineIR!(`
                %r0 = zext i64 %0 to i128 
                %r1 = zext i64 %1 to i128
                %r2 = mul i128 %r1, %r0
                %r3 = lshr i128 %r2, 64
                %r4 = trunc i128 %r3 to i64
                ret i64 %r4`, ulong)(inv, x);
        } else version(D_InlineAsm_X86_64) {
            asm {
                mov RBX, this;
                mov RAX, inv[RBX];
                mul x;
                mov r, RDX;
            }
        } else {
            r = x/value;
        }
        return r;
    }
    ulong opBinaryRight(string op:"%")(ulong x) const {
        return x - x/this*value;
    }
}

unittest {
   foreach (ulong i; 1..100) {
        auto b = BarrettULong(i);
        foreach (ulong j; 0..100) {
//            writeln(j, " ", i, " ", j/b, " ", j/i);
            assert(j/b == j/i);
        }
    }
    foreach (ulong i; 1..100) {
        auto b = BarrettULong(i);
        foreach (ulong j; 0..100) {
            assert(j%b == j%i);
        }
    }
}