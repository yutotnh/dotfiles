# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
./install.sh    # Nixのインストール、flake.nixのパッケージ導入、~/.bashrcへのフック追加。既に導入済みなら更新として動く(冪等)
./uninstall.sh  # Nix・導入したパッケージ・~/.bashrcのフックを削除する
```

Lint(GitHub ActionsのFormat/Spellワークフローと同じもの):

```bash
shellcheck --exclude=SC1090,SC1091,SC2046 *.sh bashrc.d/*.sh
npx prettier --check "**/*.{json,md,yml}"
npx cspell .
```

## Architecture

### パッケージ管理: flake.nix + `nix profile`

`flake.nix` の `packages.<system>.default` に全ツールを1つの `buildEnv` として宣言している。
`install.sh` は `nix profile install`(初回)/`nix profile upgrade '.*'`(2回目以降、
`nix profile list` に自分の flake パス文字列が含まれるかで判定)を使い分けて反映する。
ツールの追加・削除は `flake.nix` の `paths` を編集するだけでよい。

Nix自体の設定(`nix.conf`)も `~/.config/nix/nix.conf` ではなく `nix/nix.conf` としてdotfiles内で
管理し、`NIX_USER_CONF_FILES` 環境変数(`GIT_CONFIG_GLOBAL`や`MYVIMRC`と同じ発想)で参照させている。
`install.sh`・`uninstall.sh`・`bashrc.sh` それぞれが個別に `NIX_USER_CONF_FILES` を export する
必要がある(スクリプトをまたいで永続する状態ではないため)。

### `bashrc.sh` の graceful-degradation 設計(最重要の制約)

このdotfilesは共有マシンの共有アカウントでも clone されて `bashrc.sh` だけ読み込まれる
運用を想定している。そのため **Nix(や各種コマンド)が一切インストールされていなくても、
`bashrc.sh` はエラーを出さずに最後まで読み込まれる**ことが絶対の制約になっている。

この制約は個別の `if type <tool> &>/dev/null; then ... fi` / `[[ -r ... ]] &&` ガードで
実現しており、`bashrc.d/aliases.sh` と `bashrc.d/complete.sh` はそれぞれ `alias`/`complete`
組み込みコマンドを上書きして「実体のコマンドが存在するエイリアスだけ登録する」ようにしている
(ファイル末尾で `unset -f alias`/`unset -f complete` して元の挙動に戻す)。

新しいツールをdotfiles内のスクリプトから使うときは、必ずこのガードのパターンに従うこと。

### CI: install → update → uninstall のライフサイクル検証

`.github/workflows/main.yml` が Rocky Linux 9 / Ubuntu(コンテナ) と macOS 上で、
`install` → `update`(= もう一度 `install.sh` を実行する冪等性確認) → `uninstall` の
3つの複合アクション(`.github/workflows/{install,update,uninstall}/action.yml`)を順に実行する。
各アクションは `bash -c 'source "${HOME}/.bashrc" && type nix'` のように**新しいbashプロセスで
明示的に `~/.bashrc` を source してから**アサートする。`exec bash -l` で置き換える書き方は
それ以降の行が実行されなくなるため使わないこと(このリポジトリで過去に踏んだ罠)。

### CIコンテナは root で動く

`main.yml` の `install-linux` ジョブはコンテナ内で root として実行されるため、`sudo` コマンド
自体が存在しないことがある。root かどうかで `sudo` を挟むかどうかを切り替える必要がある箇所
(`uninstall.sh` など)では `id -u` で判定し、root ならプレフィックス無しで実行する。
