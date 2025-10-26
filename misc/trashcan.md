---
title: チラ裏メモ
permalink: /misc/trashcan/
---

# sudo がなぜホスト名を参照するのか？

`hostnamectl` でホスト名前を変えたら `sudo` にかなりの時間がかかるようになってしまった。  
`/etc/hosts` を更新することで直るのはわかるのだが、`sudo` とホスト名の関係がわからなかった。

以下の理由らしい。  
[https://superuser.com/questions/429790/sudo-command-trying-to-search-for-hostname](https://superuser.com/questions/429790/sudo-command-trying-to-search-for-hostname)

ChatGPT による翻訳。
> /etc/sudoersファイルは複数のサーバー間で配布できるように設計されています。これを実現するために、ファイル内の各権限にはホスト部分があります。  
> 通常、これはALL=に設定されており、これは権限がどのサーバーでも有効であることを意味しますが、特定のホストに設定することもできます。  
> ```
> %sudo    kaagini=(ALL) ALL
> ```  
> このルールが適用されるべきかどうかをsudoが知るためには、実行されているホストを調査する必要があります。これには/etc/hostsが正しいことを前提とした呼び出しが使われています。そのため、これが正しくない場合には失敗します。
> もし権限のホスト部分が全ての権限に対してALL=に設定されている場合、sudoは名前の検索をする必要がないと主張されるかもしれませんが、それはうまく機能しません。sudoはルールを処理する前に実行されている場所を把握するようです。  
> これは実際にはsudoが現在のマシンでユーザーが何ができるかを確認するためのもので、管理者としては、100台のサーバーがあれば、それぞれのマシンごとに異なる/etc/sudoersファイルを維持する必要があります。sudoersは権限にホスト部分を持っているので、1つのsudoersファイルを維持し、それをすべてのマシンに配布することができ、それでも各マシンでユーザーが何ができるかについて詳細な制御が可能です。

# Dev Containers テンプレ
## Rust 用
Dockerfile  
(refer: https://code.visualstudio.com/remote/advancedcontainers/add-nonroot-user)
```
FROM rust:1.84-bookworm

RUN apt update \
  && apt -y install libssl-dev pkg-config sudo \
  && apt clean \
  && rm -rf /var/lib/apt/lists/*

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
  && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
  && echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
  && chmod 0440 /etc/sudoers.d/$USERNAME 

RUN rustup component add rustfmt clippy

ENTRYPOINT ["/bin/bash"]
```
compose.yml
```yaml
services:
  rust_dev:
    build:
      context: .
      dockerfile: Dockerfile
    restart: always
    tty: true
    volumes:
      - ../:/workspace
    working_dir: /workspace
```
devcontainer.json
```
{
  "dockerComposeFile": ["compose.yml"],
  "service": "rust_dev",
  "workspaceFolder": "/workspace",
  "remoteUser": "vscode",
  "customizations": {
    "vscode": {
      "extensions": [
        "rust-lang.rust-analyzer",
        "vadimcn.vscode-lldb"
      ]
    }
  }
}

```

## Lambda 用
TODO: 上に追加して清書
```
apt -y install pipx
pipx install cargo-lambda
pipx ensurepath
```

# Bind Address の意味
keen さんが全て説明してくれた。  
https://keens.github.io/blog/2016/02/24/bind_addressnoimigayouyakuwakatta/

> 実際に使ってみても127.0.0.1を指定すればローカルホストから、0.0.0.0を指定すれば外部からでも参照出来るな、くらいの認識しかありませんでした。

上記記事を閲覧するまで本当にこの通りの認識で、  
何なら学生の頃は `192.168.12.255` とか指定すれば `192.168.12.*` からの接続のみ受け付けるのかな？などの勘違いをしていた。(実際にやってみて違うことは理解した)

関数名のとおり、本当に `Bind` なんだなぁ。

私自身最初は C# でプログラミングを始めたのだが、ネットワークのプログラムを書くときに最初に触るのは `System.Net.Sockets.TcpListener` だった。  
MSDN に記述された `TcpListener` のコンストラクタの説明は以下だ。

> ```cs
> public TcpListener (System.Net.IPAddress localaddr, int port);
> ```
> ### パラメーター
> `localaddr` IPAddress  
> ローカルIPアドレスを表す IPAddress。
>
> `port` Int32  
> 受信接続の試行を待機するポート。

今読むと「何故ローカルIPアドレスを指定する必要が？」と疑問が湧くのだが、当時はまぁいいやで済ませてしまっていた。どこのサンプルも大抵 `IPAddress.Any` を指定していたしそんなもんだろと思っていた。

# VSCode で日本語入力ができない
当然ディストロを入れ直すなんてことは滅多に無い。  
前回入れ直した際に VSCode 上で Input Method を切り替えることができずかなりの時間を浪費してしまった。  
今回もつい先程まで切り替えることができずうんざりしたので、VSCode 上で日本語入力できるまでの手順を記録しておく。

今回は Debian 12 を使用している。
```sh
$ sudo aptitude -y install fcitx5-mozc
$ sudo im-config -n fcitx5
$ sudo reboot
```
(再起動じゃなくてログオフでいい)

Fcitx Configuration を開き、`Input Method` に `Keyboard Japanese` と `Mozc` を設定する。
```sh
$ fcitx5-configtool
```

fcitx5 の自動起動設定。
```sh
$ mkdir -p ~/.config/autostart
$ cp /usr/share/applications/org.fcitx.Fcitx5.desktop ~/.config/autostart/.
```

以下の内容のファイルを作成する。
```sh
$ cat /etc/environment.d/fcitx5.conf
GTK_IM_MODULE=fcitx5
QT_IM_MODULE=fcitx5
XMODIFIERS=@im=fcitx5
```
前回までの環境はここまでの設定で VSCode で日本語が使えたはずだが今回は IM が切り替わらなかった。  
どうやら Debian インストール時に Language を English でインストールすると Gnome 側が IM をうまく認識できないらしい。

Gnome に IM に fcitx5 を使っているということをわからせてやる。

```sh
$ gsettings set org.gnome.settings-daemon.plugins.xsettings overrides "{'Gtk/IMModule':<'fcitx5'>}"
```
以下のコマンドで設定した値が表示されれば OK。
```sh
$ gsettings get org.gnome.settings-daemon.plugins.xsettings overrides
{'Gtk/IMModule': <'fcitx5'>}
```
この状態で再起動したところ、VSCode で日本語入力ができた。

# ディレクトリ及びフォルダのサイズを取得
現在携わっているプロジェクトで、特定のディレクトリの下のファイルを定期的に S3 上にアップロードする必要がある。  
アップロードするサイズが大きい場合にどのディレクトリ(or ファイル)が問題になっているかを調査したい。  
(アップロードの対象外にできるかどうかは人間の判断が必要になるので。)

```sh
# カレントディレクトリ下でサイズが大きいディレクトリ・ファイルの上位 10 件を出力
$ du -ahd 1 . | sort -rh | head -10
```
```
-a, --all:
    write counts for all files, not just directories

-h, --human-readable:
    print sizes in human readable format (e.g., 1K 234M 2G)

-d, --max-depth=N:
    print  the  total for a directory (or file, with --all) only if it is N or fewer levels below the command line argument;  --max-depth=0 is the same as --summarize
```
