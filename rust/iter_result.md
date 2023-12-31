# Iterator で `Result` が出現する場合の対処
よく忘れて調べるか `for loop` で逃げてしまっているのでメモ  
`Result` を `Option` に置き換えてもよし

## `Error` を無視する
`flat_map` を使えば良い。
```rs
let source = vec!["3", ".", "1", "4"];
let v = source
    .iter()
    .flat_map(|x| x.parse::<u8>())
    .collect::<Vec<_>>();
assert_eq!(3, v[0]);
assert_eq!(1, v[1]);
assert_eq!(4, v[2]);
```

`flat_map` の[シグネチャ](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.flat_map)は以下の通り。  
クロージャの戻り値の型が `IntoIterator` を実装していれば良い。
```
fn flat_map<U, F>(self, f: F) -> FlatMap<Self, U, F> ⓘ
where
    Self: Sized,
    U: IntoIterator,
    F: FnMut(Self::Item) -> U,
```
`Result` は `IntoIterator` を[実装](https://doc.rust-lang.org/std/result/enum.Result.html#impl-IntoIterator-for-Result%3CT,+E%3E)しており、
`Ok` の場合は要素数 1 `Err` の場合は要素数 0 となる。
```rs
let x: Result<u32, &str> = Ok(5);
let v: Vec<u32> = x.into_iter().collect();
assert_eq!(v, [5]);

let x: Result<u32, &str> = Err("nothing!");
let v: Vec<u32> = x.into_iter().collect();
assert_eq!(v, []);
```

## `Result<Vec<_>, _>` の型として扱う
`colelct` 時に `Result<Vec<_>, _>` を指定すれば良い。
```rs
let source = vec!["3", ".", "1", "4"];
let v = source
    .iter()
    .map(|x| x.parse::<u8>())
    .collect::<Result<Vec<_>, _>>();
assert!(v.is_err());
```
イテレータの中で最初に発生したエラーをエラーとして返す。  
当然エラーが発生した時点で残りの要素は評価しない。
```rs
#[derive(PartialEq, Eq, Debug)]
enum Error {
    Zero,
    Minus,
}

struct X(i32);
impl X {
    // 1 以上の値でないとエラー
    fn value(&self) -> Result<i32, Error> {
        println!("X::value() = {}", self.0);
        if self.0 == 0 {
            Err(Error::Zero)
        } else if self.0 < 0 {
            Err(Error::Minus)
        } else {
            Ok(self.0)
        }
    }
}

```
```rs
let source = vec![X(0), X(-1), X(1)];
let v = source
    .iter()
    .map(|x| x.value())
    .collect::<Result<Vec<_>, _>>();
assert_eq!(Err(Error::Zero), v);

println!("--");
let source = vec![X(-1), X(0), X(1)];
let v = source
    .iter()
    .map(|x| x.value())
    .collect::<Result<Vec<_>, _>>();
assert_eq!(Err(Error::Minus), v);
```
```rs
$ cargo test -- --nocapture
...
running 1 test
X::value() = 0
--
X::value() = -1
...
```