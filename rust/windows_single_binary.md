# Windows でシングルバイナリを生成する

「Linux なんてよくわからん」「Windows しか使いたくない」「設定とか何もわからん」というお客様向け。

そのようなお客様に  
「Microsoft Visual C++ xxxx 再頒布可能パッケージをインストールしてください」  
とお願いしても  
「よくわからない」  
と返ってくるのが目に見えるので、静的リンクしたバイナリを送付してさしあげる。

## 静的リンクの設定

プロジェクトのルートから `.config/config` というファイルを作成する。
```sh
.
├── .cargo
│   └── config
︙
```

作成した config 内に以下を記述後、

```toml
[target.x86_64-pc-windows-msvc]
rustflags = ["-Ctarget-feature=+crt-static"]
```

ビルドすればよい。

```sh
> cargo build --release
```

## 静的リンクの確認

Windows では `dumpbin` を使うことで依存関係を確認できる。  
```sh
> dumpbin.exe /DEPENDENTS <BINARY>
```
`dumpbin.exe` は大抵
```
Program Files (x86)\Microsoft Visual Studio\<VERSION>\BuildTools\VC\Tools\MSVC\<BUILD VERSION>\bin\Hostx64\x64
```
あたりにいる。

### 静的リンク設定前の依存関係
以下の例だと、`VCRUNTIME140.dll` や `api-ms-win-crt` で始まる C ランタイムに依存してしまっている。

うっかりこのバイナリをお客様に納品してしまうと「動かないぞ！バグってる！お前らは信用できない！」とお叱りを受けること間違いなし。
```sh
> dumpbin.exe /DEPENDENTS example.exe
Microsoft (R) COFF/PE Dumper Version 14.34.31937.0
Copyright (C) Microsoft Corporation.  All rights reserved.


Dump of file example.exe

File Type: EXECUTABLE IMAGE

  Image has the following dependencies:

    kernel32.dll
    ws2_32.dll
    secur32.dll
    crypt32.dll
    advapi32.dll
    ntdll.dll
    bcrypt.dll
    VCRUNTIME140.dll
    api-ms-win-crt-math-l1-1-0.dll
    api-ms-win-crt-runtime-l1-1-0.dll
    api-ms-win-crt-stdio-l1-1-0.dll
    api-ms-win-crt-locale-l1-1-0.dll
    api-ms-win-crt-heap-l1-1-0.dll

  Summary

        6000 .data
       81000 .pdata
      453000 .rdata
       1A000 .reloc
      950000 .text
```

### 静的リンク設定後の依存関係

先の例で依存していた `VCRUNTIME140.dll` や `api-ms-win-crt` で始まる C ランタイムが消えていることを確認できる。

このバイナリをお客様に納品すれば「動くのは当たり前だろ？」とお褒め頂けるだろう。

```sh
> dumpbin.exe /DEPENDENTS example.exe
Microsoft (R) COFF/PE Dumper Version 14.34.31937.0
Copyright (C) Microsoft Corporation.  All rights reserved.


Dump of file example.exe

File Type: EXECUTABLE IMAGE

  Image has the following dependencies:

    kernel32.dll
    ws2_32.dll
    secur32.dll
    crypt32.dll
    advapi32.dll
    ntdll.dll
    bcrypt.dll

  Summary

        7000 .data
       82000 .pdata
      45E000 .rdata
       1B000 .reloc
      960000 .text
        1000 _RDATA
```