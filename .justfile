key := "/boot/luks.key"

@default:
    just --list

prepare: format
    cp "{{justfile_directory()}}/*.nix" /mnt/etc/nixos/configuration.nix

format:
    mkdir -p /boot
    openssl genrsa -out "{{key}}" 4096
    chmod -v 0400 "{{key}}"
    chown root:root "{{key}}"
    sudo nix run github:nix-community/disko -- --mode disko "{{justfile_directory()}}/disko-config.nix"
    cp "{{key}}" "/mnt/{{key}}"

