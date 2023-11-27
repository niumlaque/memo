# ビルド時に git の Hash 値を埋め込む

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

## .git を削除してビルドしようとするお客様
がいらっしゃる。あと `git` が無い環境でビルドしようとしたり(いるのか？)。  
`GIT_HASH` 取得時のマクロを `env!` ではなく `option_env!` にすることで、
Hash 値を埋め込めない場合に対処している。
