{
  description = "yutotnh/dotfiles で使うコマンド一式";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  # nvmはnixpkgsにパッケージが存在しないため、本体のリポジトリから直接取得して
  # 自前でビルドする
  inputs.nvm-src = {
    url = "github:nvm-sh/nvm/v0.40.6";
    flake = false;
  };

  outputs =
    {
      self,
      nixpkgs,
      nvm-src,
    }:
    let
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
        ] (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: {
        default = pkgs.buildEnv {
          name = "dotfiles-env";
          paths =
            with pkgs;
            [
              bash-completion
              bat
              bottom
              coreutils
              delta
              eza
              fd
              fzf
              gh
              git
              gitui
              glow
              icdiff
              jq
              less
              lv
              msedit
              nkf
              # nvmはnixpkgsにパッケージが存在しないため、nvm-src(nvm-sh/nvm)から自前でビルドする
              (stdenvNoCC.mkDerivation {
                pname = "nvm";
                version = "0.40.6";
                src = nvm-src;
                dontBuild = true;
                installPhase = ''
                  mkdir -p "$out/share/nvm"
                  cp nvm.sh nvm-exec bash_completion "$out/share/nvm/"
                '';
              })
              ripgrep
              rustup
              sourceHighlight
              starship
              tmux
              vim
              zoxide
            ]
            ++ lib.optionals stdenv.isLinux [
              glibcLocales
              herdr
              luit
              xclip
            ];
          extraOutputsToInstall = [
            "man"
            "share"
          ];
        };
      });
    };
}
