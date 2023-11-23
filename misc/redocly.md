# Redocly を使用して openapi.json から HTML を出力する

Rust で API サーバを書いているとき、[utoipa](https://crates.io/crates/utoipa) や [utoipa-swagger-ui](https://crates.io/crates/utoipa-swagger-ui) を用いてこれをドキュメント代わりにしていたりする。  
コメントとちょっとのマクロを書くだけで[ここまで](https://petstore.swagger.io/)出せるのだから大したものだ。

しかしサーバの API を呼び出すチームからしたら毎回サーバを実行するのも面倒なわけで。  
HTML を出力する必要に迫られたのでメモ。

## openapi.json をダウンロードする
アプリを立ち上げ swagger-ui のページを開く。  
ページの先頭にアプリ名やらバージョンやらが書いてあるので、そこの下辺りの URL を保存する。  
デフォルトだと `/api-docs/openapi.json` になっている。

## HTML ファイル出力
```sh
$ npx @redocly/cli build-docs ./openapi.json -o output.html
```

## 他に試したこと
最初は Chrome の `名前を付けて保存` にて `ファイルの種類` - `ウェブページ、完全 (*.html; *.html)` で保存した。  
しかし、openapi.json を JavaScript で取得しに行くようで、サーバを落とすと NG。  
上記の方法でダウンロードした openapi.json を指定してもローカルのファイルを参照しようとすると CORS エラーで NG。