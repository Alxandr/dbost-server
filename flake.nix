{
  description = "NixOS configuration for my personal systems";

  # the nixConfig here only affects the flake itself, not the system configuration!
  nixConfig = {
    experimental-features = [
      "nix-command"
      "flakes"
      "pipe-operators"
    ];
    trusted-users = [ "alxandr" ];

    substituters = [
      "https://cache.nixos.org"
    ];

    # nix community's cache server
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://nixpkgs-wayland.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
    ];
  };

  # This is the standard format for flake.nix. `inputs` are the dependencies of the flake,
  # Each item in `inputs` will be passed as a parameter to the `outputs` function after being pulled and built.
  inputs = {
    # Pin our primary nixpkgs repository. This is the main nixpkgs repository
    # we'll use for our configurations. Be very careful changing this because
    # it'll impact your entire system.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    nix-system = {
      url = "github:Alxandr/nix-system";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-unstable.follows = "nixpkgs-unstable";
    };
  };

  outputs =
    inputs@{
      flake-parts,
      nix-system,
      nixpkgs-unstable,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      top@{
        config,
        withSystem,
        moduleWithSystem,
        ...
      }:
      {
        imports = [
          nix-system.flakeModules.flake-path
          nix-system.flakeModules.systems
          nix-system.flakeModules.disko
          nix-system.flakeModules.install
        ];
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];

        flake.path = "github:Alxandr/dbost-server";

        systemConfigurations.sharedModules = [
          nix-system.nixosModules.sops
          (
            { ... }:
            {
              config.nixpkgs.overlays = [
                nix-system.overlays.default
                (final: prev: {
                  inherit (config.flake.packages."${prev.system}") caddy;
                })
              ];
            }
          )
        ];

        systemConfigurations.systems.pangolin = {
          unstable = true;
          system = "aarch64-linux";
          hardware = ./system/hardware.nix;
          configuration = ./system/configuration.nix;
          users = {
            alxandr = ./users/alxandr;
          };
          drives = {
            imports = [ nix-system.diskoConfigurations.btrfs ];
            disko.devices.disk.root.device = "/dev/sda";
            disko.swap.root = {
              enable = true;
              size = "8G";
            };
          };
        };

        perSystem =
          {
            # pkgs,
            # lib,
            system,
            ...
          }:
          let
            pkgs = import nixpkgs-unstable {
              inherit system;
            };

          in
          rec {
            packages.caddy = pkgs.caddy.withPlugins {
              plugins = [ "github.com/mholt/caddy-l4@v0.0.0-20250530154005-4d3c80e89c5f" ];
              hash = "sha256-NLFl+ix36z6X1Anr1F6rdMPwSEysSVl84Ad71zprsbU=";
            };

            devShells.default = pkgs.mkShell {
              packages = with pkgs; [
                jq
                just
                sops
                ssh-to-age
                vim
                wireguard-tools
                yq-go
                netmaker

                packages.caddy
              ];
            };
          };
      }
    );
}
