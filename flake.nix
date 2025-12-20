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

    version = "1.3.2";

    sources = {
      x86_64-linux = {
        url = "https://proton.me/download/pass-cli/${version}/pass-cli-linux-x86_64";
        hash = "sha256-X7FK1t0+SuBGgSsBuhYUCkcR8LtCQMjbplo5B1LSuh0=";
      };
      aarch64-linux = {
        url = "https://proton.me/download/pass-cli/${version}/pass-cli-linux-aarch64";
        hash = "sha256-w5mwbYQgqAU07T4+vUaYkcVp8XtMFNynGTV3jJQjAFw=";
      };
      x86_64-darwin = {
        url = "https://proton.me/download/pass-cli/${version}/pass-cli-macos-x86_64";
        hash = "sha256-VmkTLyHNZ8p8wgvzHOYiQsbDTjzKsjyGDShcQZlAH7A=";
      };
      aarch64-darwin = {
        url = "https://proton.me/download/pass-cli/${version}/pass-cli-macos-aarch64";
        hash = "sha256-B+hmxagP5Ls+Jc8DZN8Y9fvdrTq+HkMICUzMVsd8aU4=";
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
