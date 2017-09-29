import std.stdio, std.process, std.exception, std.string, std.algorithm;

import dparse.ast;
import dparse.lexer;
import dparse.parser;

import dparse.rollback_allocator : RollbackAllocator;

ubyte[] trimComment(ubyte[] fileBytes) {
    StringCache cache = StringCache(StringCache.defaultBucketCount);
    LexerConfig config;
    config.stringBehavior = StringBehavior.source;
    auto tokens = DLexer(fileBytes, config, &cache);
    ubyte[] res;
    while (!tokens.empty) {
        auto t = tokens.front;
        tokens.popFront;
        if (isBasicType(t.type) || isKeyword(t.type) || isOperator(t.type)) {
            res ~= str(t.type);
        } else if (t.type == tok!"comment") {
            res ~= " ";
        } else {
            res ~= t.text;
        }
    }
    return res;
}

ubyte[] trimUnittest(ubyte[] fileBytes) {
    StringCache cache = StringCache(StringCache.defaultBucketCount);
    LexerConfig config;
    config.stringBehavior = StringBehavior.source;
    auto tokens = getTokensForParser(fileBytes, config, &cache);
    RollbackAllocator rba;
    auto mod = parseModule(tokens, null, &rba);
    auto visitor = new Visitor(fileBytes);
    visitor.visit(mod);
    return visitor.getResult;
}

class Visitor : ASTVisitor {
    alias visit = ASTVisitor.visit;
    ubyte[] fileBytes;
    bool[size_t] utLocations;
    size_t[2][] utBodys;
    this(ubyte[] fileBytes) {
        this.fileBytes = fileBytes;
    }
    ubyte[] getResult() {
        StringCache cache = StringCache(StringCache.defaultBucketCount);
        LexerConfig config;
        config.stringBehavior = StringBehavior.source;
        auto tokens = DLexer(fileBytes, config, &cache);
        ubyte[] res;
        while (!tokens.empty) {
            auto t = tokens.front;
            tokens.popFront;
            if (t.type == tok!"unittest") {
                assert(t.index in utLocations);
            }
            if (t.type == tok!"unittest") continue;
            if (utBodys
                    .find!(x => x[0] <= t.index && t.index <= x[1]).empty == false) continue;
            
            if (isBasicType(t.type) || isKeyword(t.type) || isOperator(t.type)) {
                res ~= str(t.type);
            } else {
                res ~= t.text;
            }
        }
        return res;
    }
    override void visit(const Unittest n) {
        utLocations[n.location] = true;
        if (n.blockStatement !is null) {
            auto st = n.blockStatement.startLocation;
            auto ed = n.blockStatement.endLocation;
            utBodys ~= [st, ed];
        }
        super.visit(n);
    }
    override void visit(const Token n) {
        super.visit(n);
    }
}
