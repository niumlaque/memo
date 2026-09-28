---
title: WebView2 上で GitHub が固まる原因を調査
permalink: /misc/primer-react-inf-loop/
---

Tauri + WebView2 を使ったアプリで GitHub を子 WebView として表示しているのだが、GitHub にログインすると画面が固まる。

Firefox や Chrome から GitHub を開く場合は問題なし。  
同じアプリ内の別 WebView も問題なし。  
GitHub もログアウト状態なら問題なし。

最初は WebView2 や GPU 周りを疑っていたが、調べていったところ GitHub が使用している Primer React の Breadcrumbs で無限 loop しているところまで辿り着いたのでメモ。

## 発生条件

以下の条件で発生する。

- GitHub を WebView2 内で表示
- GitHub にログイン済み
- JavaScript が有効

GitHub の子 WebView だけ JavaScript を無効にすると発生しない。

なので描画というより、ログイン後に実行される JavaScript が怪しそう。

GPU 無効化も試したが変わらず。

WebView2 Runtime もインストール済みの 153 系と Fixed Version の 154 系で試したが両方発生した。  
特定の Runtime の問題というわけでもなさそう。

WebView 作成時のサイズも最初は 1x1 だったので、800x600 で作成するように変更してみたが同じ場所で固まった。

WebView2 のバージョンは以下。

```text
> Get-ItemProperty 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}' -ErrorAction SilentlyContinue | Select-Object pv

pv
--
153.0.4234.48
```

## ProcessFailed を取得する

とりあえず WebView2 の以下のイベントをログに出す。

- NavigationStarting
- NavigationCompleted
- ProcessFailed

GitHub への Navigation 自体は正常に完了していた。

その後 20 秒くらいすると以下が発生する。

```text
COREWEBVIEW2_PROCESS_FAILED_KIND(2)
```

`RenderProcessUnresponsive` らしい。

つまり GitHub の読み込みに失敗しているわけではなく、読み込み完了後に Renderer Process が応答しなくなっている。

## CDP で固まっている JavaScript を調べる

`RenderProcessUnresponsive` が発生した際に Chrome DevTools Protocol から `Debugger.pause` を実行するようにした。

Pause 自体は成功。

取得した call stack の一番上が以下だった。

```text
primer-react-3ca70c6e707ba409.js
```

その下には React DOM の処理が続いている。

React の work loop から Primer React に入ったあと、Primer React から戻ってきていないっぽい。

minify 済みのコードを見ると Breadcrumbs の overflow 計算だった。

```text
if (e > 0 && u.length > 0) {
    let t = c(u);
    for (;
        ("menu" === l || "menu-with-root" === l) &&
        (t > e || u.length > d);
    ) {
        if (
            p += 1,
            t = c(u = u.slice(1)) + n,
            1 === u.length && t > e
        ) {
            o = !0;
            break
        }
        o = r
    }
}
```

公開されている Primer React のコードと見比べると Breadcrumbs の `calculateOverflow()` に相当する。

変数は大体以下。

- `e`: availableWidth
- `u`: currentVisibleItemWidths
- `t`: visibleItemsWidthTotal
- `n`: menuButtonWidth
- `d`: MIN_VISIBLE_ITEMS
- `o`: effectiveHideRoot
- `l`: overflow
- `p`: menuItemCount

## ローカル変数を確認する

最初は `Debugger.evaluateOnCallFrame` でローカル変数を直接取得しようとした。

Production build なので当然元の変数名は残っていない。  
minify 後の変数についても V8 に最適化されているためか Debugger から取得できないものがあった。

`Debugger.paused` の `scopeChain` を取得し、各 scope に対して `Runtime.getProperties` を実行する。

すると以下の値が取得できた。

```text
availableWidth = 28
menuButtonWidth = 32
overflow = "menu"
effectiveHideRoot = true
menuItemCount = 1168774335
```

`menuItemCount` が 11 億を超えている。

Breadcrumbs の項目数が 11 億個あるわけがないので、どう見ても loop し続けている。

## 無限 loop する理由

原因は以下の値。

```text
availableWidth = 28
menuButtonWidth = 32
```

Breadcrumbs が使える幅より overflow menu のボタンの方がでかい。

loop 内では

```text
u = u.slice(1)
```

しているので、表示する Breadcrumb を一つずつ減らしている。

そのうち `u` は空になる。

しかし空になった後も、

```text
t = c([]) + menuButtonWidth
```

となる。

今回は `effectiveHideRoot = true` なので `c([])` は実質 0。

つまり

```text
t = 32
```

になる。

一方で、

```text
availableWidth = 28
```

なので、

```text
32 > 28
```

は当然ずっと真。

空配列に対して `slice(1)` を何回実行しても空配列のまま。

さらに break 条件が

```text
1 === u.length
```

なので、`u.length === 0` になってしまうとここにも入らない。

最終的に

```text
u = []
t = 32
availableWidth = 28
```

の状態から抜けられなくなり、`menuItemCount` だけが増え続ける。

そりゃ Renderer も応答しなくなる。

## WebView2 自体が固まっているわけではなかった

最初は WebView2 の不具合をかなり疑っていた。

Firefox や Chrome だと発生しないのでなおさら。

ただ、少なくとも Renderer が応答しなくなる直接の原因は Primer React の Breadcrumbs 内で JavaScript が無限 loop しているためだった。

WebView2 は単にその JavaScript を実行し続けている。

ただし一つわからないことが残っている。

**何故このアプリの WebView2 だと `availableWidth = 28` になるのか。**

ハング時の `window.innerWidth` は 508。

WebView 全体が 28px というわけではなく、GitHub 内のレイアウト結果として Breadcrumbs のコンテナだけが 28px になっているらしい。

WebView 作成時のサイズを 1x1 から 800x600 に変更しても同じ call stack で発生したので、最初の WebView サイズだけが原因というわけでもなさそう。

今のところ以下の状態。

```text
作成中アプリ内の何らかの条件
    ↓
GitHub の Breadcrumbs が 28px になる
    ↓
Primer React calculateOverflow()
    ↓
menuButtonWidth 32px > availableWidth 28px
    ↓
u が空になっても loop 条件が成立
    ↓
無限 loop
    ↓
WebView2 RenderProcessUnresponsive
```

## 現在地

とりあえず、どの JavaScript が Renderer を固めているのかまでは特定できた。

次に調べるのは Primer React ではなく、

**何故作成中のアプリ内だと GitHub の Breadcrumbs が 28px になるのか**

の方。

ここがわかれば GitHub 側をどうこうしなくても、アプリ側の WebView やレイアウトを変更して回避できるかもしれない。

少なくとも「WebView2 で GitHub を開くと何故か固まる」という状態から、

**Primer React の Breadcrumbs の overflow 計算が `availableWidth < menuButtonWidth` の場合に無限 loop する**

ところまでは追えた。

