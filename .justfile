key := "/boot/luks.key"

@default:
    just --list

prepare: format
    cp "{{justfile_directory()}}/configuration.nix" /mnt/etc/nixos/configuration.nix
    cp "{{justfile_directory()}}/disko-config.nix" /mnt/etc/nixos/disko-config.nix
    cp "{{justfile_directory()}}/hardware-configuration.nix" /mnt/etc/nixos/hardware-configuration.nix

format:
    mkdir -p /boot
    openssl genrsa -out "{{key}}" 4096
    chmod -v 0400 "{{key}}"
    chown root:root "{{key}}"
    sudo nix run github:nix-community/disko -- --mode disko "{{justfile_directory()}}/disko-config.nix"
    cp "{{key}}" "/mnt/{{key}}"

