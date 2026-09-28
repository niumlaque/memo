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

## WebView と GitHub 側の幅を確認する

前述のとおり `availableWidth = 28` になることはわかった。

ただし、WebView2 が GitHub に変な viewport 幅を渡しているのか、GitHub 内の layout で Breadcrumbs だけが狭くなっているのかはまだわからない。

Breadcrumbs から `html` まで祖先を辿り、それぞれの幅を取得する。

ついでに以下も取得した。

- `window.innerWidth`
- `window.outerWidth`
- `visualViewport.width`
- `documentElement.clientWidth`
- `body.clientWidth`
- `devicePixelRatio`
- アプリ側で指定している GitHub child WebView の物理幅

再現時に取得した値が以下。

```text
GitHub child WebView physical width = 328
devicePixelRatio = 1.25

window.innerWidth = 263
window.outerWidth = 263
visualViewport.width = 248

html = 248
body = 248
GlobalNav = 248
center = 52
Breadcrumbs = 52
```

アプリ側で指定している WebView の幅は 328px。

`devicePixelRatio = 1.25` なので CSS pixel にすると、

```text
328 / 1.25 = 262.4
```

`window.innerWidth = 263` とほぼ同じ。

WebView2 が意味不明な viewport 幅を GitHub に渡しているわけではなさそう。

以前の調査では `window.innerWidth = 508` という値も取得していたが、少なくとも今回問題が再現している状態では約 263 CSS px。

普通に狭い。

## GlobalNav の幅を確認する

GitHub の GlobalNav は 248px。

中身は以下だった。

```text
left   = 100px
center = 52px
right  = 96px
```

当然、

```text
100 + 52 + 96 = 248
```

となる。

center の style は以下。

```text
flex: 1 1 0%
min-width: 0px
```

left と right で 196px 使用し、残った 52px が center に割り当てられている。

つまり、

```text
WebView viewport 約263px
    ↓
GitHub GlobalNav 約248px
    ↓
left 100px + right 96px
    ↓
center 52px
```

ここまでは単純に GitHub の flex layout の結果。

WebView2 が突然 center を 52px にしているとかではない。

## Breadcrumbs の 28px は padding ではない

気になるのは、

```text
center = 52px
availableWidth = 28px
```

の差。

24px なので最初は Breadcrumbs の左右 padding かと思った。

box model を取得してみる。

```text
box-sizing = border-box
padding-left = 0px
padding-right = 0px
clientWidth = 52
offsetWidth = 52
getBoundingClientRect().width = 52
```

padding ではない。

この時点では Breadcrumbs 自体も 52px ある。

にも関わらず、その後 Primer React の `availableWidth` は 28 になる。

じゃあ 28px はどこから出てきたのか。

## ResizeObserver の値を確認する

Primer React の Breadcrumbs は `ResizeObserver` で幅を監視し、その値を `availableWidth` として overflow の計算に使用している。

`window.ResizeObserver` を document 開始時に wrap し、GitHub が登録した callback はそのまま実行しつつ、Breadcrumbs の entry だけ callback の直前にログへ出すようにした。

結果が以下。

```text
contentRect.width = 28
getBoundingClientRect().width = 28
clientWidth = 28
offsetWidth = 28
```

全部 28px。

`ResizeObserver` だけ変な値を返しているわけではなさそう。

callback が実行された時点では Breadcrumbs 自体が本当に 28px になっている。

つまり、

```text
Breadcrumbs = 52px
    ↓
何らかの layout 更新
    ↓
Breadcrumbs = 28px
    ↓
ResizeObserver
    ↓
availableWidth = 28
    ↓
calculateOverflow()
    ↓
menuButtonWidth = 32
    ↓
無限 loop
```

となっている。

## 何故 52px から 28px になるのか

ここはまだ完全にはわかっていない。

今のところ Breadcrumbs 自身の overflow 処理が影響しているように見える。

最初は center に 52px ある。

Primer はこの幅に Breadcrumbs を収めるため、表示する Breadcrumb を減らして overflow menu に移動する。

その後 Breadcrumbs 自体が 28px になり、`ResizeObserver` がその値を通知する。

再度 `calculateOverflow()` が実行されるが、

```text
availableWidth = 28
menuButtonWidth = 32
```

なので、前述の無限 loop に入る。

今のところ以下のような流れに見える。

```text
狭い WebView
    ↓
GitHub GlobalNav 約248px
    ↓
left / right に幅を取られる
    ↓
center 52px
    ↓
Primer が overflow の layout を変更
    ↓
Breadcrumbs 28px
    ↓
ResizeObserver が 28px を通知
    ↓
Primer calculateOverflow()
    ↓
32px の menu button すら入らない
    ↓
u が空になっても slice し続ける
    ↓
無限 loop
```

52px から 28px になる直接の理由についてはもう少し調べる必要がある。

## WebView2 固有の問題なのか

ここまで調べた限り、WebView2 の Renderer 自体がおかしくなっているようには見えない。

少なくとも、

- viewport の CSS pixel と `devicePixelRatio` は整合する
- DOM の幅も flex layout と整合する
- `ResizeObserver` の値も実際の DOM 幅と一致する
- Renderer が止まる場所は毎回 Primer React の同じ loop

となっている。

なので Renderer が止まる直接の原因はやはり Primer React 側。

ただ、Firefox や Chrome で普通に GitHub を開いている分には発生していない。

このアプリでは GitHub をかなり狭い child WebView に表示しているので、

```text
availableWidth < menuButtonWidth
```

という普通のブラウザではあまり踏まなさそうな条件になっている。

WebView2 だから壊れるというより、このアプリの狭い viewport で Primer React の edge case を踏んでいると考えるのが自然そう。

## 現在地

ここまでの調査結果をまとめると以下。

```text
GitHub child WebView
physical width = 328px
devicePixelRatio = 1.25
    ↓
CSS viewport ≒ 263px
    ↓
GitHub GlobalNav ≒ 248px
    ↓
left 100px
right 96px
center 52px
    ↓
Primer Breadcrumbs の overflow 処理
    ↓
Breadcrumbs 28px
    ↓
ResizeObserver contentRect.width = 28
    ↓
Primer availableWidth = 28
menuButtonWidth = 32
    ↓
calculateOverflow() が空配列から抜けられない
    ↓
無限 loop
    ↓
WebView2 RenderProcessUnresponsive
```

最初に疑っていた GPU、WebView2 Runtime、WebView 作成時の初期サイズはほぼ関係なさそう。

結局、

**狭い layout で Primer React の無限 loop を踏んでいる**

というところまで絞れた。

少なくとも「WebView2 で GitHub を開くと何故か固まる」という状態ではなくなった。

次は原因調査ではなく、アプリ側でこの条件を踏まないようにする。

※ Firefox や Chrome でも、サイドバーを表示した状態で Window を限界まで細くし、ログイン済みの GitHub Home を開くとハングすることが発覚。

