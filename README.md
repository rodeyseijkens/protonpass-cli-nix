# Proton Pass CLI Flake

This is a Nix flake for the [Proton Pass CLI](https://protonpass.github.io/pass-cli/).

## Usage

### Run directly

```bash
nix run .# -- --help
```

### Add to your system flake

Add this repository to your `flake.nix` inputs:

```nix
inputs = {
  protonpass-cli.url = "github:rodeyseijknes/protonpass-cli-nix";
};
```

Then add it to your system packages:

```nix
outputs = { self, nixpkgs, protonpass-cli, ... }: {
  nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
    # ...
    modules = [
      ({ pkgs, ... }: {
        environment.systemPackages = [
          protonpass-cli.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];
      })
    ];
  };
};
```
