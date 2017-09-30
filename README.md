[![Build Status](http://drone.yosupo.com/api/badges/yosupo06/dcomp/status.svg)](http://drone.yosupo.com/yosupo06/dcomp)

[Document](https://yosupo06.github.io/dcomp/)


D言語の競技プログラミング用ライブラリです	


dubの公式サイトには登録していないので、

```
git checkout https://github.com/yosupo06/dcomp
dub add-local .
```

で手動でパッケージとして追加してください。(もっといい方法があるかも？)

# 実行
sample.dを適当な名前(例えばA.d)としてコピーして

```
dub run --single A.d
```

とすると、`./A`という名前の実行ファイルが出来ます。

# ソースコード結合

提出用にソースコードを結合するスクリプトも付いていて、
```
dub run dcomp:combine -- -i=source.d -o=source_submit.d -c -u
```
とすると、`source_submit.d`という提出用ファイルが生成されます。
```
dub run dcomp:combine -- -h
```
でヘルプが出てきます

# ドキュメント

ドキュメントは
```
dub run dcomp:document
```
で `./docs` 以下に作成されます。
