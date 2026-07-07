{
  description = "yutotnh/dotfiles で使うコマンド一式";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
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
              nkf
              ripgrep
              rustup
              sourceHighlight
              starship
              vim
              zoxide
            ]
            ++ lib.optionals stdenv.isLinux [
              glibcLocales
              herdr
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
