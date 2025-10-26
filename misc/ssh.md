---
title: SSH 関連
permalink: /misc/ssh/
---

## SSH Key 生成

以下のコマンドで生成する。  
基本的に `Ed25519` で良い。
```sh
$ ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_<FILENAME>
```

`~/.ssh/config` にホストを追加する。例えば以下は github に登録する場合。
```
Host github.com
  HostName github.com
  User git
  Port 22
  IdentityFile ~/.ssh/id_ed25519_github
  IdentitiesOnly yes
```

## 同じ Host に対して複数の鍵を使い分ける
例えば会社の GitHub と個人の GitHub 両方から SSH で clone したい場合、  
以下の用に別 Host で `~/.ssh/config` に個人用に登録している鍵の設定を追加する。
```
Host github.com.private
  HostName github.com
  User git
  Port 22
  IdentityFile ~/.ssh/id_gh_private
  IdentitiesOnly yes
```
この private なリポジトリから clone したい場合は以下の記述で clone 可能。
```sh
$ git clone git@github.com.private:niumlaque/repo.git
```

## sshd

以下のコマンドで SSH サーバをインストールする。
```sh
$ aptitude -y install openssh-server
```

`/etc/ssh/sshd_config` の設定を変更する。  
(ポート番号は任意の値, 例として 40932 を使用する。)
```diff
--- a/etc/ssh/sshd_config
+++ b/etc/ssh/sshd_config
@@ -11,7 +11,7 @@

 Include /etc/ssh/sshd_config.d/*.conf

-#Port 22
+Port 40932
 #AddressFamily any
 #ListenAddress 0.0.0.0
 #ListenAddress ::
@@ -30,7 +30,7 @@ Include /etc/ssh/sshd_config.d/*.conf
 # Authentication:

 #LoginGraceTime 2m
-#PermitRootLogin prohibit-password
+PermitRootLogin no
 #StrictModes yes
 #MaxAuthTries 6
 #MaxSessions 10
@@ -54,7 +54,7 @@ Include /etc/ssh/sshd_config.d/*.conf
 #IgnoreRhosts yes

 # To disable tunneled clear text passwords, change to no here!
-#PasswordAuthentication yes
+PasswordAuthentication no
 #PermitEmptyPasswords no

 # Change to yes to enable challenge-response passwords (beware issues with
```
クライアント側で作成した公開鍵を `$HOME/.ssh/authorized_keys` に保存する。

### WSL で sshd を起動する場合の追加の設定
ポートフォワーディングや Windows FW の設定が必要

#### ポートフォワーディング
以下のコマンドで sshd が起動している WSL の IP アドレスを取得する。
```sh
$ ip -4 a show dev eth0 | grep inet | awk '{print $2}'
```

その後、管理者権限で起動した Windows の cmd で以下のコマンドを実行する。
```sh
> netsh.exe interface portproxy delete v4tov4 listenport=40932
> netsh.exe interface portproxy add v4tov4 listenport=40932 connectaddress=<WSLのIP>
> sc.exe config iphlpsvc start=auto
> sc.exe start iphlpsvc
```
以下のコマンドで反映されているかを確認できる。
```sh
> netsh.exe interface portproxy show v4tov4
```

#### FW
[Windows Defender ファイアウォール] > [受信の規則] > [新しい規則...] > [ポート] > [TCP, 特定のローカルポート: 40932] > [接続を許可する] > [プライベート(※)]

※必要に応じて変更
