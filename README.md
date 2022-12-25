# dotfiles

## Install

```bash
git clone https://github.com/yutotnh/dotfiles.git
cd dotfiles
sudo
./install.sh
exec bash -l
```

## Uninstall

```bash
./uninstall.sh
exec bash -l
```

## 補足

### WSL 使用時に `dotfiles/bashrc.sh` の実行が遅くなる

__解決法__

`/etc/wsl.conf` に以下を書き込み、ホストのWindowsを再起動する

```text:/etc/wsl.comf
[interop]
appendWindowsPath = false
```

__理由__

WSLのデフォルト設定だと Windows の PATH を引き継いでいる

`dotfiles/bashrc.sh` 内の bash_completion.sh を実行する箇所でインストールされていないコマンドを探索するときにWindowsのPATHも見ている

WSLからWindowsのディレクトリへのアクセスは非常に遅く、そしてPATHの中に非常にたくさんアクセスしているため実行時間が遅くなっている
