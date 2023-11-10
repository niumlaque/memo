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