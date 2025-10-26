---
title: ビルド時に git の Hash 値を埋め込む
permalink: /rust/git_hash/
---

不具合発生時に、動作している実行媒体のバージョンを特定したい。  
`build.rs` に以下のコードを記述する。`build.rs` については [The Cargo Book](https://doc.rust-lang.org/cargo/reference/build-scripts.html) を参照。


```rs
use std::process::Command;

fn main() {
    if let Ok(output) = Command::new("git").args(["rev-parse", "HEAD"]).output() {
        if let Ok(git_hash) = String::from_utf8(output.stdout) {
            if !git_hash.is_empty() {
                println!("cargo:rustc-env=GIT_HASH={git_hash}");
            }
        }
    }
}
```

実行媒体側では以下のコードを記述する。

```rs
fn get_version() -> String {
    let version = env!("CARGO_PKG_VERSION");
    if let Some(git_hash) = option_env!("GIT_HASH") {
        format!("{version} ({git_hash})")
    } else {
        version.into()
    }
}

fn main() {
    println!("{}", get_version());
}
```

上記コードを実行すると以下のテキストが出力される。

```sh
$ cargo run
   Finished dev [unoptimized + debuginfo] target(s) in 0.00s
    Running `target/debug/example`
0.1.0 (6b1d344097cd3d63e61ca5400f13295ce02bcf82)
```

## お客様！！困ります！！あーっ！！
`.git` を削除してビルドしようとするお客様がいらっしゃる。  
あと `git` が無い環境でビルドしようとしたり(いるのか？)。  
`GIT_HASH` 取得時のマクロを `env!` ではなく `option_env!` にすることで、
Hash 値を埋め込めない場合に対処している。

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
