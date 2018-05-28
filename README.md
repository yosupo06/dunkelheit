[![Build Status](http://drone.yosupo.com/api/badges/yosupo06/dunkelheit/status.svg)](http://drone.yosupo.com/yosupo06/dunkelheit)

[Document](https://yosupo06.github.io/dunkelheit/)

D language library for competitive programming.

# How to Execute

1. Copy sample.d to A.d
2. Type follow command
3. Get executable file as `./A`

```
dub run --single A.d
```

# Combine source code

Because for online judge, we can handle single file,
We prepared to script that combine source code and this library.

If you type,

```
dub run dunkelheit:combine -- -i=source.d -o=source_submit.d -c -u
```

you get `source_submit.d`.

You can view help of dunkelheit:combine with

```
dub run dunkelheit:combine -- -h
```

# Documents

You can make document with

```
dub run dunkelheit:document
```


# Online judge survey

- AtCoder : dmd(2.070.1), ldc(0.17.0), 60000 byte(acutually limit is more bigger?)
- Codeforces(Warning: windows, 32bit) : dmd(2.074) 64k(65535 byte)
- Hackerrank : dmd(2.076.1) 50kb(50*1024 ?)
- Yukicoder : dmd(2.076.0) 64k(65536 byte)
