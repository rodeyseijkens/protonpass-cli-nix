{
  description = "Proton Pass CLI flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    nixpkgsFor = forAllSystems (system: import nixpkgs {inherit system;});

    version = "1.2.0";

    sources = {
      x86_64-linux = {
        url = "https://proton.me/download/pass-cli/${version}/pass-cli-linux-x86_64";
        hash = "sha256-x9vdFucgezmhb205OPrSO7IVQ0HjNzpHGAxoYEUmBj4=";
      };
      aarch64-linux = {
        url = "https://proton.me/download/pass-cli/${version}/pass-cli-linux-aarch64";
        hash = "sha256-lEmdVPgtjr5hk0FVzCpntMv9HG1tPObIAM0mALbFA9w=";
      };
      x86_64-darwin = {
        url = "https://proton.me/download/pass-cli/${version}/pass-cli-macos-x86_64";
        hash = "sha256-qiAqr9GNqs+OqpOlMWeSW49oEhJgU4fVgfghqjnxMr8=";
      };
      aarch64-darwin = {
        url = "https://proton.me/download/pass-cli/${version}/pass-cli-macos-aarch64";
        hash = "sha256-ZYPwbwk90tDlqWUZr5pFEnhfLDwXULyGbcbWNU0xwnk=";
      };
    };
  in {
    packages = forAllSystems (system: let
      pkgs = nixpkgsFor.${system};
      source = sources.${system} or (throw "Unsupported system: ${system}");
    in {
      default = pkgs.stdenv.mkDerivation {
        pname = "protonpass-cli";
        inherit version;

        src = pkgs.fetchurl {
          url = source.url;
          hash = source.hash;
        };

        dontUnpack = true;

        nativeBuildInputs =
          []
          ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
            pkgs.autoPatchelfHook
          ];

        buildInputs =
          []
          ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
            pkgs.stdenv.cc.cc.lib
          ];

        installPhase = ''
          runHook preInstall
          install -Dm755 $src $out/bin/pass-cli
          runHook postInstall
        '';

        meta = with pkgs.lib; {
          description = "Proton Pass CLI";
          homepage = "https://protonpass.github.io/pass-cli/";
          platforms = supportedSystems;
          mainProgram = "pass-cli";
        };
      };
    });
  };
}
