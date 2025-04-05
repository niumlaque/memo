# Hyper-V を使用して比較的安全にブラウズ

数年に一度、調べ物に没頭してしまいうっかり怪しい URL にアクセスしてしまうことへの対策。  
Windows Sandbox を使えばいいのだが、毎回ブラウザや IME のインストール & 設定がめんどくさい。

Hyper-V が有効になっていることを前提とする。

## Hyper-V の初期設定

Hyper-V マネージャを起動し、左ペインのツリーから自身のマシン名を選択する。

右ペインから `[Hyper-V の設定...]` を選択する。

### サーバ
* 仮想ハードディスク
* 仮想マシン  
保存先を選択する。  
デフォルトがシステムドライブなのでできれば場所を変えたい。
* 拡張セッション モード ポリシー
拡張セッションモードを許可する。  
(RDP で接続できるようになる)

## ブラウズ用 VM 作成

右ペインから `[クイック作成...]` を選択する。

仮想マシン作成ウィザードが開くので、以下の内容を設定して `仮想マシンの作成` ボタンを押下する。  
(必要に応じて変更すること)

* オペレーティングシステムの作成  
Windows 11 開発環境 

* 名前  
WebSandbox  
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

## Nested Hyper-V
内で更に仮想化が必要な場合、起動する前に PowerShell で以下のコマンドを実行する。  
(起動中の場合は終了すること)
```ps
> Set-VMProcessor -VMName <VMName> -ExposeVirtualizationExtensions $true
```

## 起動
あとは接続なり起動なり。

## 初回セットアップ
いつかスクリプト化したい

### SID について
以下のコマンドで取得すること

```
> Get-WmiObject -Filter "name='<ユーザ名>'" win32_useraccount name, sid
```

### HKEY_USERS を変更したい場合
以下のコマンドを実行すること

```
> New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS
```

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

### エクスプローラ関連
スタートメニューを左寄せにする
```
> Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarAl' -Type 'DWord' -Value 0
```
検索ボックスを非表示にする
```
> Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search -Name SearchBoxTaskbarMode -Value 0 -Type DWord -Force
```
タスクビューを非表示にする
```
> Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'ShowTaskViewButton' -Type 'DWord' -Value 0
```
ウィジェットを非表示にする
```
> Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarDa' -Type 'DWord' -Value 0
```
チャットを非表示にする
```
> Set-ItemProperty -Path HKU:\<SID>\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'TaskbarMn' -Type 'DWord' -Value 0
```
Windows の Copilot (Preview) を非表示
```
> Set-ItemProperty -Path HKU:\<SID>\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'ShowCopilotButton' -Type 'DWord' -Value 0
```
ファイルの拡張子を表示する
```
> Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'HideFileExt' -Type 'DWord' -Value 0
> Set-ItemProperty -Path HKU:\<SID>\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'HideFileExt' -Type 'DWord' -Value 0
```
エクスプローラで開く
(1: PC, 2: ホーム)
```
> Set-ItemProperty -Path HKU:\<SID>\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name 'LaunchTo' -Type 'DWord' -Value 1
```
