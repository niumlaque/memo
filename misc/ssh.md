# SSH Key

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
