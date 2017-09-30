module dcomp.graph.primitive;

/**
グラフライブラリ

基本的にグラフはEdge[][]の形で入力する
*/

import std.range : ElementType;
alias EdgeType(R) = ElementType!(ElementType!R);
