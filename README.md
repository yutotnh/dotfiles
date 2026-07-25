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

### VS Code の統合ターミナルで EUC-JP を扱う

#### 理由

VS Code の統合ターミナル(xterm.js)は UTF-8 デコード固定で、端末のエンコーディングを変更する設定は存在しない

そのため EUC-JP のテキストはそのままでは文字化けする

これは VS Code 側の設定では解決できず、シェル側で UTF-8 に変換して渡すしかない

- [microsoft/vscode#45520](https://github.com/microsoft/vscode/issues/45520)
- [microsoft/vscode#19837](https://github.com/microsoft/vscode/issues/19837)

なお、エディタ側は問題ない(`files.encoding` に `eucjp` を指定すればよい)

詰まるのはターミナルだけである

#### 解決法1: ファイル閲覧・パイプ処理

本リポジトリが提供するヘルパー関数を使う

| 関数                    | 説明                                                           |
| ----------------------- | -------------------------------------------------------------- |
| `euc-cat [FILE...]`     | EUC-JP を UTF-8 に変換して表示する(引数なしなら標準入力を読む) |
| `euc-run CMD [ARGS...]` | EUC-JP を入出力する対話型アプリを `luit` で包んで実行する      |

素のコマンドでやる場合は `iconv` を使う

```bash
iconv -f EUC-JP -t UTF-8 FILE
```

`nix/flake.nix` に含まれている `lv` は多言語対応ページャで、EUC-JP を自動判別してそのまま読める

```bash
lv FILE
```

`nkf -w` は半角カナを勝手に全角化する(`ﾃﾞｰﾀ` が `データ` に変わることを確認済み)ため、バイト忠実性が必要な場面では `iconv` を使う

#### 解決法2: 対話型アプリ

`euc-run` を使う

```bash
euc-run vim file.txt
```

実体は `luit -encoding EUC-JP -- <cmd>` で、luit は UTF-8 端末とレガシーエンコーディングのアプリの間で入出力を双方向に変換する X.Org 製ツールである(X サーバは不要)

`nix/flake.nix` の Linux 専用パッケージとして導入している

`screen` を使う代替手段もある(Ubuntu の `/usr/bin/screen` 4.09 は `eucJP` サポート付きでビルドされていることを確認済み)

`screen -U` してから `Ctrl-a :` で以下を実行する

```text
encoding eucJP utf8
```

なお、tmux は UTF-8 専用で変換機能を持たないため使えない

#### 解決法3(補足): ロケールについて

`ja_JP.EUC-JP` ロケールが必要になる場面がある

ロケールの利用可否は、実行するコマンドがどこから来たかで二層に分かれる

| 実行するコマンド                | `ja_JP.eucjp`  | 理由                                                                              |
| ------------------------------- | -------------- | --------------------------------------------------------------------------------- |
| Nix 製 (`~/.nix-profile/bin/*`) | そのまま使える | `nix/flake.nix` の `glibcLocales` が持っており、`LOCALE_ARCHIVE` 経由で参照される |
| ディストリ製 (`/usr/bin/*`)     | 使えない       | Ubuntu などの glibc は `LOCALE_ARCHIVE` を見ない(これは nixpkgs 独自パッチのため) |

```console
$ LC_ALL=ja_JP.eucjp nix shell nixpkgs#glibc --command locale charmap
EUC-JP
$ LC_ALL=ja_JP.eucjp /usr/bin/locale charmap
/usr/bin/locale: Cannot set LC_ALL to default locale: No such file or directory
ANSI_X3.4-1968
```

Nix 製コマンドを使う限り追加作業は不要である

ディストリ製のコマンドで必要になったときだけ、以下を実行する(Debian/Ubuntu 系)

```bash
sudo sed -i 's/^# ja_JP.EUC-JP EUC-JP/ja_JP.EUC-JP EUC-JP/' /etc/locale.gen && sudo locale-gen
```
