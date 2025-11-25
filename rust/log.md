---
title: tracing クレートを使用してログを出力する
permalink: /rust/log/
---

細かい使い方はともかく、単純な使い方と初期設定。

最新のバージョンについては crates.io を参照すること。

- [https://crates.io/crates/tracing](https://crates.io/crates/tracing)
- [https://crates.io/crates/tracing-subscriber](https://crates.io/crates/tracing-subscriber)

## 標準出力に出すだけ
```toml
[dependencies]
tracing = "0.1.40"
tracing-subscriber = "0.3.18"
```
```rs
fn init_log() {
    let format = tracing_subscriber::fmt::format()
        .with_level(true)
        .with_target(false)
        .with_thread_ids(true)
        .with_ansi(false)
        .compact();
    let subscriber = tracing_subscriber::FmtSubscriber::builder()
        .with_max_level(tracing::Level::TRACE)
        .event_format(format)
        .finish();
    tracing::subscriber::set_global_default(subscriber).expect("logging failed");
}

fn main() {
    init_log();
    tracing::trace!("TRACE");
    tracing::debug!("DEBUG");
    tracing::info!("INFO");
    tracing::warn!("WARNING");
    tracing::error!("ERROR");
}
```
```sh
$ cargo run
    Finished dev [unoptimized + debuginfo] target(s) in 0.30s
     Running `target/debug/example`
2023-11-29T06:53:41.872607Z TRACE ThreadId(01) TRACE
2023-11-29T06:53:41.872649Z DEBUG ThreadId(01) DEBUG
2023-11-29T06:53:41.872655Z  INFO ThreadId(01) INFO
2023-11-29T06:53:41.872680Z  WARN ThreadId(01) WARNING
2023-11-29T06:53:41.872687Z ERROR ThreadId(01) ERROR
```

## 日別にファイル出力する
```toml
[dependencies]
tracing = "0.1.40"
tracing-subscriber = "0.3.18"
tracing-appender = "0.2.3"
```
```rs
fn init_log(log_dir: impl AsRef<std::path::Path>) -> tracing_appender::non_blocking::WorkerGuard {
    use tracing_appender::rolling::{RollingFileAppender, Rotation};
    use tracing_subscriber::prelude::*;
    let format = tracing_subscriber::fmt::format()
        .with_level(true)
        .with_target(false)
        .with_thread_ids(true)
        .with_ansi(false)
        .compact();
    let file_appender = RollingFileAppender::new(Rotation::DAILY, log_dir, "example.log");
    let (non_blocking_file_appender, guard) = tracing_appender::non_blocking(file_appender);
    let file_layer = tracing_subscriber::fmt::Layer::default()
        .event_format(format.clone())
        .with_writer(non_blocking_file_appender);
    let subscriber = tracing_subscriber::FmtSubscriber::builder()
        .with_max_level(tracing::Level::TRACE)
        .event_format(format)
        .finish()
        .with(file_layer);
    tracing::subscriber::set_global_default(subscriber).expect("logging failed");
    guard
}

fn main() {
    let _guard = init_log(".");
    tracing::trace!("TRACE");
    tracing::debug!("DEBUG");
    tracing::info!("INFO");
    tracing::warn!("WARNING");
    tracing::error!("ERROR");
}
```
`init_log` の戻り値を束縛しておかないと終了時にバッファにたまったログをファイルに出力してくれないので注意。
```sh
$ cargo run
    Finished dev [unoptimized + debuginfo] target(s) in 0.01s
     Running `target/debug/example`
2023-11-29T07:27:19.795334Z TRACE ThreadId(01) TRACE
2023-11-29T07:27:19.795517Z DEBUG ThreadId(01) DEBUG
2023-11-29T07:27:19.795656Z  INFO ThreadId(01) INFO
2023-11-29T07:27:19.795812Z  WARN ThreadId(01) WARNING
2023-11-29T07:27:19.795942Z ERROR ThreadId(01) ERROR
```
ファイルにも出力されている。  
`RollingFileAppender::new` の引数に与えたファイル名の末尾に実行した日時が付与される。
```sh
$ cat example.log.2023-11-29
2023-11-29T07:27:19.795482Z TRACE ThreadId(01) TRACE
2023-11-29T07:27:19.795630Z DEBUG ThreadId(01) DEBUG
2023-11-29T07:27:19.795787Z  INFO ThreadId(01) INFO
2023-11-29T07:27:19.795916Z  WARN ThreadId(01) WARNING
2023-11-29T07:27:19.796086Z ERROR ThreadId(01) ERROR
```

## ログに出しておきたいもの(たまに更新)
### git の Hash 値
`"CARGO_PKG_VERSION"` で細かく管理すればよいかもしれないが、
開発中などちょっと直して動かすたびにバージョンを増やしていくのは現実的では無い気がする。  
ので、git の Hash 値を出すことで動かしているコミットを特定する。

出力方法に関しては[この記事](git_hash.md)を参照。

### ビルド時の最適化有無
動作環境で要件を十分に満たしたバイナリを納品したにも関わらず、「遅すぎる！どうなってんだ！！」とお叱りを受けたことがある。  
お客様がソースコードをビルドした際に最適化していないことが原因だった。  
(README とか手順書とか書いてるんだから読んでくださいよ...)
```rs
fn get_build_mode() -> &'static str {
    if cfg!(debug_assertions) {
        "Debug"
    } else {
        "Release"
    }
}
```
こんな感じの関数を書いて起動時に出力すれば良いだろう。

## 上記のコードを確認した環境

```sh
$ cat /etc/os-release
PRETTY_NAME="Debian GNU/Linux 11 (bullseye)"
NAME="Debian GNU/Linux"
VERSION_ID="11"
VERSION="11 (bullseye)"
VERSION_CODENAME=bullseye
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"
$ rustc --version
rustc 1.74.0 (79e9716c9 2023-11-13)
```
