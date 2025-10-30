---
title: WSLg の pulseaudio に追加でモジュールをロードさせる
permalink: /misc/wslg-pa/
---

最近の WSL は特に意識しなくても GUI は Windows で表示され、音声も再生される。  
裏では pulseaudio が動いており、多分 `/mnt/wslg/PulseServer` が unix ソケットファイル。

諸事情で WSL の pulseaudio Server で動かしたいモジュールがあるのだが、`/etc/pulse/` 下のファイルに設定を記述しても全く反映されない。  
特にサービスなども無く、誰が `/mnt/wslg/PulseServer` を作成しているのかもわからない。  

## WSLg の構成
Microsoft の [WSLg のリポジトリ](https://github.com/microsoft/wslg)によると、以下の様に構成されているらしい。
![a](https://raw.githubusercontent.com/microsoft/wslg/main/docs/WSLg_ArchitectureOverview.png)

普段我々が触るのは `User Distro` である。  
どうやら `User Distro` 以外に `WSLg System Distro` というのが起動しており、
こいつが pulseaudio を起動しているようだ。  

さて、じゃあ `wsl --system` でログインした `WSLg System Distro` の `/etc/pulse/` 下のファイルをいじれば良いかと思ったが、うまくはいかないものだ。

読み取り権限しかついておらず設定ファイルを編集できない。  
(-> $HOME/.config/pulse 配下に設定ファイルを置いたがどうも反映されない。しかしこれは適当に書いたから間違っていた可能性がある。)

## 無理やりモジュールをロードする
`/usr/bin/WSLGd` というバイナリが pulseaudio を起動しているのだが、このプログラムは以下の様に文字列を組み立てて実行している。

```c
    // Construct pulseaudio launch command line.
    std::string pulseaudioLaunchArgs =
        "/usr/bin/dbus-launch "
        "/usr/bin/pulseaudio "
        "--log-time=true "
        "--disallow-exit=true "
        "--exit-idle-time=-1 "
        "--load=\"module-rdp-sink sink_name=RDPSink\" "
        "--load=\"module-rdp-source source_name=RDPSource\" "
        "--load=\"module-native-protocol-unix socket=" SHARE_PATH "/PulseServer auth-anonymous=true\" ";

    // Construct log file option string.
    std::string pulseaudioLogFileOption("--log-target=");
    auto pulseAudioLogFilePathEnv = getenv("WSLG_PULSEAUDIO_LOG_PATH");
    if (pulseAudioLogFilePathEnv) {
        pulseaudioLogFileOption += pulseAudioLogFilePathEnv;
    } else {
        pulseaudioLogFileOption += "newfile:" SHARE_PATH "/pulseaudio.log";
    }
    pulseaudioLaunchArgs += pulseaudioLogFileOption;

    // Launch pulseaudio and the associated dbus daemon.
    monitor.LaunchProcess(std::vector<std::string>{
        "/usr/bin/sh",
        "-c",
        std::move(pulseaudioLaunchArgs)
    });
```
もはや WSLGd の main.cpp を変更して `--load=\"module-....\"` を追加するしかないと思われたが、上記のコードには **環境変数の値をそのまま引数にする** というとんでもない処理がある。
```c
    // Construct log file option string.
    std::string pulseaudioLogFileOption("--log-target=");
    auto pulseAudioLogFilePathEnv = getenv("WSLG_PULSEAUDIO_LOG_PATH");
    if (pulseAudioLogFilePathEnv) {
        pulseaudioLogFileOption += pulseAudioLogFilePathEnv; // <<== こいつ
    } else {
        pulseaudioLogFileOption += "newfile:" SHARE_PATH "/pulseaudio.log";
    }
    pulseaudioLaunchArgs += pulseaudioLogFileOption;
```
さらに `WSLg System Distro` の環境変数は `C:\Users\<USER>\.wslgconfig` に定義したものがそのまま利用される。  
つまり、`.wslgconfig` に以下の内容を記述し、

```
WSLG_PULSEAUDIO_LOG_PATH=newfile:/mnt/wslg/pulseaudio.log --load="module-...""
```
(最後の " 2 つはミスではない)  
WSL を再起動すると WSLGd は以下のコマンドを実行することになる。

```
/usr/bin/dbus-launch 
/usr/bin/pulseaudio 
--log-time=true 
--disallow-exit=true 
--exit-idle-time=-1 
--load="module-rdp-sink sink_name=RDPSink" 
--load="module-rdp-source source_name=RDPSource" 
--load="module-native-protocol-unix socket=/mnt/wslg/PulseServer auth-anonymous=true"
--log-target=newfile:/mnt/wslg/pulseaudio.log 
--load="module-..."
```
私の環境ではこれで目当てのモジュールがロードされ動作することを確認できた。  
(wslrelay が127.0.0.1 にバインドされているので必要に応じて `netsh interface portproxy` でポートフォワードすること。)

それにしても悪意のあるコードが実行されそうな感じがする。
