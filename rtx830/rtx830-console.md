---
title: RTX830 へのコンソール接続
permalink: /rtx830/rtx830-console/
---

接続には minicom を使用する。

```sh
$ sudo aptitude install minicom
```

ボーレートなどの設定を行う。  
デバイスは環境に応じて変更すること。

```sh
$ sudo minicom -D /dev/ttyUSB0
```

Ctrl-A Z でメニューを表示し、
[cOnfigure Minicom] > [Serial port setup] > [Bps/Par/Bits] を選択し、

```
Speed: 9600
Parity: None
Data: 8
Stopbits 1
```
で設定する。

最終的に以下の表示になっていれば良い。

```
    ┌───────────────────────────────────────────────────────────────────────┐
    │ A -    Serial Device      : /dev/ttyUSB0                              │
    │ B - Lockfile Location     : /var/lock                                 │
    │ C -   Callin Program      :                                           │
    │ D -  Callout Program      :                                           │
    │ E -    Bps/Par/Bits       : 9600 8N1                                  │
    │ F - Hardware Flow Control : Yes                                       │
    │ G - Software Flow Control : No                                        │
    │ H -     RS485 Enable      : No                                        │
    │ I -   RS485 Rts On Send   : No                                        │
    │ J -  RS485 Rts After Send : No                                        │
    │ K -  RS485 Rx During Tx   : No                                        │
    │ L -  RS485 Terminate Bus  : No                                        │
    │ M - RS485 Delay Rts Before: 0                                         │
    │ N - RS485 Delay Rts After : 0                                         │
    │                                                                       │
    │    Change which setting?                                              │
    └───────────────────────────────────────────────────────────────────────┘
```
設定完了後、
`[cOnfigure Miniom]` > `[Save setup as dfl]` を選択して保存する。

その後、 RTX830 から Username を問われれば成功している。

```sh
Welcome to minicom 2.8

OPTIONS: I18n 
Port /dev/ttyUSB0, 12:04:38

Press CTRL-A Z for help on special keys


Username: 
Password: 

RTX830 Rev.15.02.31 (Fri Jul  5 10:40:25 2024)
Copyright (c) 1994-2024 Yamaha Corporation. All Rights Reserved.
To display the software copyright statement, use 'show copyright' command.
**:**:**:**:**:**, **:**:**:**:**:**
Memory 256Mbytes, 2LAN
>
```

とりあえず初期設定として文字コードを UTF-8 に変更しておく。
```
> console charater ja.utf8
```
適当にコマンドを実行して日本語が表示されていることを確認する。
```
> show ip route summary
プロトコル   有効      無効
-----------------------------
<snip>
```
保存して終了する。
```
> administrator
Password: 
# save
# exit
> exit
```

Minicom は Ctrl-Z A からのメニューで終了する。
