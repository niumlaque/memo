---
title: 自分用 LLM 用の WSL 準備
permalink: /misc/llmwsl/
---

wsl の挙動が定期的に変わって bat ファイル作っても動かなくなる。

## WSL の用意
WSL の Profile 名を hoge とする。

Profile の保存先を `D:\v\wsl` とし、  
使用するベースのイメージを "D:\v\wsl\debian.tar" とする。
```
wsl --import hoge "D:\v\wsl\hoge" "D:\v\wsl\debian.tar"
```

以下のコマンドでログイン。
```
wsl -d hoge -u <インストール時のユーザ名>
```

`/etc/wsl.conf` に以下の内容を追記する。
```sh
sudo vi /etc/wsl.conf
```
```diff
  [boot]
  systemd=true
+
+ [user]
+ default = <インストール時のユーザ名>
```

WSL  を再起動して反映されていることを確認する。
```
wsl --shutdown
wsl -d hoge
```

## WSL の初期設定

```sh
sudo apt update && sudo apt -y upgrade && sudo apt -y install git
```
### 自分の dotfiles を入れておく
```
git clone https://github.com/niumlaque/dotfiles.git $HOME/dotfiles
```
### [SSH Key を GitHub に登録しておく。]({{ site.baseurl }}/misc/ssh/)

### nvim も入れておく
```
git clone git@github.com:niumlaque/nvimprod.git $HOME/nvimprod
```

### LLM 用の dotfiles も入れておく
```
git clone git@github.com:niumlaque/dotfiles.ai.git $HOME/dotfiles.ai
```

### codex をインストールする
```
volta install node && npm i -g @openai/codex
```

### codex でログインしておく 
事前に `Codex に対してデバイスコード認証を有効にする` を有効にしておく。
```
codex login --device-auth
```

### Rust と Python をよく使うので予め入れておく
```
sudo aptitude -y install python3-venv
```
```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### apt で入る peco がバグってるので入れ直す
```
sudo aptitude purge peco
```

`sha256:93d4418ab1261eb723a1f614c2e652c9e912885cff7d969f913c0686459c62e8`
```
wget https://github.com/peco/peco/releases/download/v0.6.0/peco_0.6.0_linux_amd64.tar.gz
```
```
tar xf peco_0.6.0_linux_amd64.tar.gz && sudo cp peco /usr/local/bin/peco
```

