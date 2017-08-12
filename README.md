[![Build Status](http://jenkins.yosupo.com/buildStatus/icon?job=dcomp-test)](http://jenkins.yosupo.com/job/dcomp-test/)

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
