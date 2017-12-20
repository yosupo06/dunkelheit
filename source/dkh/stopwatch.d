module dkh.stopwatch;

static if (2075 <= __VERSION__) {
    public import std.datetime.stopwatch;
    auto toMsecs(T)(T x) {
        return x.total!"msecs";
    }
} else {
    public import std.datetime;
    auto toMsecs(T)(T x) {
        return x.msecs;
    }
}
