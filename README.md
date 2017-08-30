[![Build Status](http://drone.yosupo.com/api/badges/yosupo06/dcomp/status.svg)](http://drone.yosupo.com/yosupo06/dcomp)

dubには登録していないので、

```
dub add-local .
```

で手動で追加してください。(もっといい方法があるかも？)

sample.dを適当な名前でコピーして

```
dub run --single source.d
```

とすると、`./A`という名前の実行ファイルが出来ます。

```
dub run dcomp:combine -- -i=source.d -o=source_submit.d -c -u
```

とすると、`source_submit.d`という提出用ファイルが生成されます。

```
dub run dcomp:document
```

で `/docs` 以下にドキュメントが生成されます。
