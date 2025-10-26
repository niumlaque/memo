---
title: fish での環境変数の設定方法
permalink: /misc/fishenv/
---

ずっと fish を使っているくせに環境変数の設定方法をすぐに忘れて、  
実行だけ bash に切り替えるなどとしている。

```sh
$ fish --version
fish, version 3.6.0
```

## コマンドのみ適用
### bash
```sh
$ XDG_RUNTIME_DIR=/tmp weston
```
### fish
```sh
$ XDG_RUNTIME_DIR=/tmp weston
```
昔はやたらと面倒だった気がするが、3.1 以降は bash と同じでよいらしい。

## セッション内のみ適用
### bash
```sh
$ export XDG_RUNTIME_DIR=/tmp
$ weston
$ unset XDG_RUNTIME_DIR
```
### fish
```sh
$ set -x XDG_RUNTIME_DIR /tmp
$ weston
$ set -e XDG_RUNTIME_DIR
```
