{
  description = "AT Garnix CI BUILD";

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    nix-github-actions = {
      url = "github:nix-community/nix-github-actions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #nixpkgs.url = "https://mirrors.ustc.edu.cn/nix-channels/nixos-23.11/nixexprs.tar.xz";
    #nixpkgs.url = "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/nixpkgs-23.11/nixexprs.tar.xz";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-master,
      nix-github-actions,
    }:
    let
      # Systems supported
      allSystems = [
        "x86_64-linux" # 64-bit Intel/AMD Linux
        "aarch64-linux" # 64-bit ARM Linux
        "x86_64-darwin" # 64-bit Intel macOS
        "aarch64-darwin" # 64-bit ARM macOS
      ];
      # Helper to provide system-specific attributes
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs allSystems (
          system:
          f {
            pkgs = import nixpkgs { inherit system; };
            pkgs-m = import nixpkgs-master { inherit system; };
          }
        );
    in
    {
      packages = forAllSystems (
        { pkgs, pkgs-m }:
        {
          #ncmpcpp-clang = (pkgs.callPackage ./ncmpcpp.nix { stdenv = pkgs.clangStdenv; });
          #ncmpcpp = (pkgs.callPackage ./ncmpcpp.nix { });
          #        cling = (pkgs.callPackage ./cling.nix { });
          arm-toolchain = (pkgs.callPackage ./default.nix { });
          #          keyviz = (pkgs.callPackage ./keyviz.nix { flutter = pkgs.flutter323; });
          #   boost = pkgs-m.boost;

          #
          #
          # stdenv = if stdenv.isDarwin then overrideSDK stdenv "11.0" else stdenv;
          #
          #
          #
          #
          #   info = pkgs.stdenv.mkDerivation {
          #     name = "info";
          #     phases = "buildPhase";
          #     buildPhase = ''
          #       echo "debug" > $out
          #       echo $($CC --version)
          #       echo ${pkgs.boost.stdenv.cc.version}
          #       echo nixpkgs-master ${pkgs-m.boost.stdenv.cc.version}
          #     '';
          #   };
        }
      );

      githubActions = nix-github-actions.lib.mkGithubMatrix {
        checks = nixpkgs.lib.getAttrs [
          "aarch64-darwin"
          "x86_64-darwin"
        ] self.packages;
      };
    };
}
