module dkh.ldc.inline;

version(LDC) {
    pragma(LDC_inline_ir) R inlineIR(string s, R, P...)(P);
}
