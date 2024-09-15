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

# Dev Containers に感動した
VSCode に乗り換えてから日が浅い & キャッチアップしていないので全く知らなかった。

今まで特殊な環境で作業したい場合は docker で image を作成後、  
```sh
$ docker run -v ./share:/mnt/host --name=$NAME -ti $NAME
```
のようなコマンドでコンテナ起動し、`./share` にコンテナ内で使用したいファイルを配置していた。  

この方式には
* ホストの環境を汚さずに済む
* 間違って開発環境の構成を壊してしまってもすぐ復旧できる
* ソースコードはホストに保存されるのでコンテナを削除しても成果は消えない

といったメリットを感じつつも
* 一々ファイル群を `./share` へ配置しなくてはならない  
* コード補完などが一切効かない(補完はあまり当てにしていないが、ジャンプがしづらいのが嫌)  
* ビルドのためにコンテナに一々アタッチしないといけない 
* 何か権限関連でエラーが出る(昔のことなので覚えていない)  

といった不満を常に抱えていた。  
Dev Containers は上記の不満を解決してくれつつ、
ウィザードに沿って設定してボタン一つで開発できる状態にしてくれるのには感動した。

低スペックマシンでコーディングして高スペックマシンでビルドしたい場合は、
高スペックマシンに SSH で接続して Dev Containers を使うしかなさそうかな。

git のホスティングサービスとして GitHub を利用する開発であれば、GitHub Coodespaces で出来たりするんだろうか。

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

