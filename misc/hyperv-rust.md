---
title: Hyper-V 上で Rust 開発
permalink: /misc/hyperv-rust/
---

レジストリを触るアプリを開発したいので、壊してもいい VM 上に環境を用意する。

Hyper-V の用意や初期設定は別記事を参照。

## 開発用 VM 作成

右ペインから `[クイック作成...]` を選択する。

仮想マシン作成ウィザードが開くので、以下の内容を設定して `仮想マシンの作成` ボタンを押下する。  
(必要に応じて変更すること)

* オペレーティングシステムの作成  
Windows 11 開発環境 

* 名前  
RustDev  
(その他のオプションを選択すると入力欄が現れる)

しばらく時間がかかるので待機する。

`仮想マシンが正常に作成されました` と表示されれば作成完了。

## ブラウズ用 VM 設定
仮想マシンが作成されたら `設定の編集` を押下する。

### ハードウェア
* メモリ  
動的メモリを有効にするのチェックを外す

* プロセッサ  
仮想プロセッサ数を 8 くらいまで減らす。

### 管理
* 統合サービス  
ゲストサービスにチェックを入れる  
(ホストと VM 間のファイルコピー用)

## 初回セットアップ
起動後、接続する。

### 言語関連の設定
Power Shell を管理者権限で起動後、以下のコマンドを実行する。  
(※参考: https://qiita.com/bibou6/items/0a136bca349050d42b20)
```
> Install-Language ja-jp -CopyToSettings
> Set-systemPreferredUILanguage ja-JP
> Set-WinUILanguageOverride -Language ja-JP
> Set-WinCultureFromLanguageListOptOut -OptOut $False
> Set-TimeZone -id "Tokyo Standard Time" # Get-TimeZone -ListAvailable で取得可能
> Set-WinHomeLocation -GeoId 0x7A  # https://learn.microsoft.com/ja-jp/windows/win32/intl/table-of-geographical-locations を参照
> Set-WinSystemLocale -SystemLocale ja-JP
> Restart-Computer
```

### ソフトウェアのインストール
Power Shell を起動後、以下のコマンドを実行する。  
UAC はいつか対処したい。今は毎回 はい を押下。
```
> winget install --accept-source-agreements --accept-package-agreements -e --id Google.JapaneseIME
> winget install --accept-source-agreements --accept-package-agreements -e --id Mozilla.Firefox
```

Firefox はアカウントログインすれば設定は同期されるが、Google IME は同期とかなさそうなのでホストの設定をコピーする。

以下のファイルをコピーすれば良い。
```
C:\Users\<ユーザ名>\AppData\LocalLow\Google\Google Japanese Input\config1.db
```

### Build Tools for Visual Studio 2022 のインストール
以下の URL からダウンロードし実行する。  
https://visualstudio.microsoft.com/ja/downloads/

ウィザードの中から `C++ によるデスクトップ開発` にチェックを入れる。

インストールボタンを押下し、完了後に再起動する。

### rustup のインストール
以下の URL から `Download rustup-init.exe (64-bit)` を選択しダウンロード、実行する。  
https://www.rust-lang.org/tools/install/

選択肢は Default で OK。

### WebView2 のダウンロード
以下の URL から `Evergreen Bootstrapper` を選択しダウンロード、実行する。
https://developer.microsoft.com/en-us/microsoft-edge/webview2/

### Git for Windows のインストール
以下の URL からダウンロードし実行する。  
https://gitforwindows.org/

### VSCode のインストール
以下の URL からダウンロードし実行する。  
https://code.visualstudio.com/

`settings.json` や `keybindings.json` は以下のディレクトリに配置する。
```
C:\Users\User\AppData\Roaming\Code\User
```

### フォントインストール
以下の URL の Release からダウンロードしインストールする。  
https://github.com/yuru7/HackGen
