{
  description = "NixOS configuration for my personal systems";

  # the nixConfig here only affects the flake itself, not the system configuration!
  nixConfig = {
    experimental-features = [
      "nix-command"
      "flakes"
      "recursive-nix"
      "pipe-operators"
    ];
    trusted-users = [ "alxandr" ];

    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://nixpkgs-wayland.cachix.org"
      "https://hyprland.cachix.org"
      "https://install.determinate.systems"
      "https://attic.alxandr.me/attic/alxandr"
    ];

    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
      "alxandr:Va/JTYBsY78zfZHABghDQqdnLu02aDVJaoo7j98jefg="
    ];
  };

  # This is the standard format for flake.nix. `inputs` are the dependencies of the flake,
  # Each item in `inputs` will be passed as a parameter to the `outputs` function after being pulled and built.
  inputs = {
    # Pin our primary nixpkgs repository. This is the main nixpkgs repository
    # we'll use for our configurations. Be very careful changing this because
    # it'll impact your entire system.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    nix-system = {
      url = "github:Alxandr/nix-system";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, nix-system, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        nix-system.flakeModules.flake-path
        nix-system.flakeModules.home-manager
        nix-system.flakeModules.disko
        nix-system.flakeModules.user-manager
        nix-system.flakeModules.systems
      ];

      config = {
        debug = true;

        flake.path = "github:Alxandr/dbost-server";
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];

        systemConfigurations.sharedModules = [ nix-system.nixosModules.sops ];
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
            pkgs,
            # lib,
            ...
          }:
          rec {
            devShells.default = pkgs.mkShell {
              packages = with pkgs; [
                jq
                just
                sops
                ssh-to-age
                vim
                wireguard-tools
                yq-go
              ];
            };
          };
      };
    };
}
