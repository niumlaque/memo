# RTX830 のファームウェア更新

## 最新のファームウェアを DL
以下のページから RTX830 用のファームウェアと MD5 チェックサムを DL する。
https://www.rtpro.yamaha.co.jp/RT/firmware/index.php

ファームウェアの MD5 が、配布されている MD5 チェックサムのファイルの内容と同じことを確認する。
```sh
$ md5sum rtx830.bin
```

## ファームウェアの更新
ルータの管理画面で
[管理] > [保守] > [ファームウェアの更新] を選択し、
`ファームウェアの更新`ページへ遷移する。

遷移した画面の `PCからファームウェアを更新`を選択し、
`更新ファイルの指定` で DL した `rtx830.bin` を指定し実行する。

しばらくすると、
```
ファームウェアの更新
-------------------------------------
ファームウェアの更新が完了しました。
本製品を再起動します。
LEDの点滅終了後、下のボタンを押してください
                  [トップへ戻る]
```
と表示されるので指示に従う。

ダッシュボードのシステム情報の `ファームウェアRev.` が更新されていれば成功。