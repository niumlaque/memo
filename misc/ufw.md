# UFW
Uncomplicated Firewall の略で debian 系列で利用される、NetFilter を管理するための iptables のフロントエンドである。

## UFW を有効にする
現在の設定を確認する。
```sh
$ ufw status
```
```sh
Status inactive
```
初回は大体無効になっている。  
これを有効にするには
```sh
$ ufw enable
```
```sh
Firewall is active and enabled on system startup
```
このメッセージで有効となった。

## incoming を全て拒否する
```sh
$ ufw default deny incoming
$ ufw status verbose
Status: active
Logging: on (low)
Default: deny (incoming), deny (outgoing), disabled (routed)
New profiles: skip
```
外から入ってくることができなくなる。  


