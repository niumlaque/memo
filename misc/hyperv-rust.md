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
購入した Windows 11 のイメージを選択する。  
新しい Windows 11 のバージョンでの動作確認を実施する場合は `Windows 11 開発環境` で良い。

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
以下は自分用の bat ファイル。  
`setup.cmd` として保存し、管理者権限で実行する。

```
@echo off
chcp 65001 >nul

echo === Dev environment setup (Firefox / Google IME / VS Build Tools / Rust / Git / Hackgen NG) ===

:: 管理者チェック
net session >nul 2>&1
if not %errorlevel%==0 (
    echo.
    echo このスクリプトは「管理者として実行」したコマンドプロンプトから実行してください。
    echo いったん閉じて、cmd.exe を右クリック -> 「管理者として実行」で開き直してください。
    echo.
    pause
    exit /b 1
)

echo.
echo [1/5] winget source update...
winget source update
if not %errorlevel%==0 (
    echo winget source update に失敗しました。（errorlevel=%errorlevel%）
    echo winget が使えない環境かもしれません。
    echo.
    pause
)

echo.
echo [2/5] Installing Mozilla Firefox...
winget install -e --id Mozilla.Firefox --accept-source-agreements --accept-package-agreements
if not %errorlevel%==0 (
    echo Firefox のインストールでエラーが発生しました。（errorlevel=%errorlevel%）
)

echo.
echo [3/5] Installing Google Japanese IME...
winget install -e --id Google.JapaneseIME --accept-source-agreements --accept-package-agreements
if not %errorlevel%==0 (
    echo Google 日本語入力のインストールでエラーが発生しました。（errorlevel=%errorlevel%）
)

echo.
echo [4/5] Installing Visual Studio 2022 Build Tools (C++ workload)...
echo    ※このステップは特に時間がかかります。
winget install -e --id Microsoft.VisualStudio.2022.BuildTools ^
  --accept-source-agreements --accept-package-agreements ^
  --override "--quiet --wait --norestart --nocache --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
if not %errorlevel%==0 (
    echo Visual Studio Build Tools のインストールでエラーが発生しました。（errorlevel=%errorlevel%）
)

echo.
echo [5/5] Installing Rust (rustup)...
winget install -e --id Rustlang.Rustup --accept-source-agreements --accept-package-agreements
if not %errorlevel%==0 (
    echo Rust のインストールでエラーが発生しました。（errorlevel=%errorlevel%）
)

echo.
echo [6/6] Installing Visual Studio Code...
winget install -e --id Microsoft.VisualStudioCode --accept-source-agreements --accept-package-agreements
if not %errorlevel%==0 (
    echo VSCode のインストールでエラーが発生しました。（errorlevel=%errorlevel%）
)

echo.
echo [7/7] Installing Git...
winget install -e --id Git.Git --accept-source-agreements --accept-package-agreements
if not %errorlevel%==0 (
    echo git のインストールでエラーが発生しました。（errorlevel=%errorlevel%）
)

echo.
echo [Extra] Installing HackGen NF font...
set "FONT_URL=https://github.com/yuru7/HackGen/releases/download/v2.10.0/HackGen_NF_v2.10.0.zip"
set "FONT_ZIP=%TEMP%\HackGenNF.zip"
set "FONT_DIR=%TEMP%\HackGenNF"

:: 古いファイルを掃除
if exist "%FONT_ZIP%" del /f /q "%FONT_ZIP%"
if exist "%FONT_DIR%" rd /s /q "%FONT_DIR%"

echo Downloading ZIP...
curl -L -o "%FONT_ZIP%" "%FONT_URL%"
if not %errorlevel%==0 (
    echo HackGen フォント ZIP のダウンロードに失敗しました。（errorlevel=%errorlevel%）
) else (
    echo Extracting ZIP...
    mkdir "%FONT_DIR%"
    tar -xf "%FONT_ZIP%" -C "%FONT_DIR%"

    echo   -> Copying and registering fonts...
    for %%F in (%FONT_DIR%\*.ttf) do (
        echo        Installing %%F
        copy /y "%%F" "%WINDIR%\Fonts" >nul
        reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" ^
            /v "%%~nF (TrueType)" /t REG_SZ /d "%%~nxF" /f >nul
    )

    echo HackGen フォントのインストール完了。
)

echo.
echo === Setup finished. ===
pause

```

Firefox はアカウントログインすれば設定は同期されるが、Google IME は同期とかなさそうなのでホストの設定をコピーする。

以下のファイルをコピーすれば良い。
```
C:\Users\<ユーザ名>\AppData\LocalLow\Google\Google Japanese Input\config1.db
```

