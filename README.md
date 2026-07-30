# dotfiles

## Install

```bash
git clone https://github.com/yutotnh/dotfiles.git
cd dotfiles
sudo true
./install.sh
exec bash -l
```

## Update

```bash
cd ${DOTFILES_DIRECTORY}
git pull
${DOTFILES_DIRECTORY}/install.sh
exec bash -l
```

### `nix/flake.nix` の変更を反映する

`install.sh` は2回目以降の実行では `nix/flake.nix` を読み直して `nix profile` を更新する。
そのため、ツールを追加・削除するために `nix/flake.nix` を編集したときも、
`git pull` は不要で `install.sh` を実行するだけでよい。

編集内容はコミット前でも反映される(このとき `warning: Git tree ... is dirty` が出る)。
ただし、NixはGitの追跡対象になっているファイルしか読まないため、
**新しく追加したファイルは `git add` しないと反映されない**

## Uninstall

```bash
${DOTFILES_DIRECTORY}/uninstall.sh
exec bash -l
```

## 補足

### WSL 使用時に `dotfiles/bashrc.sh` の実行が遅くなる

#### 解決法

`/etc/wsl.conf` に以下を書き込み、ホストのWindowsを再起動する

```text:/etc/wsl.conf
[interop]
appendWindowsPath = false
```

#### 理由

WSLのデフォルト設定だと Windows の PATH を引き継いでいる

`dotfiles/bashrc.sh` 内の bash_completion.sh を実行する箇所でインストールされていないコマンドを探索するときにWindowsのPATHも見ている

WSLからWindowsのディレクトリへのアクセスは非常に遅く、そしてPATHの中に非常にたくさんアクセスしているため実行時間が遅くなっている

### 共有マシンの共有アカウントで使う場合

`install.sh` は実行せず、本リポジトリを clone して `bashrc.sh` を読み込むだけでよい

```bash
git clone https://github.com/yutotnh/dotfiles.git
echo '[[ -r "'"$(pwd)"'/dotfiles/bashrc.sh" ]] && source "'"$(pwd)"'/dotfiles/bashrc.sh"' >>~/.bashrc
```

Nix(や、Nixでインストールしたコマンド)が無い状態でも、`bashrc.sh` はエラーなく読み込まれ、
Nixに依存しない設定(shopt, 履歴, cdの補助エイリアスなど)は有効になる
