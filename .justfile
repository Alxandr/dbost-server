key := "/luks.key"

@default:
    just --list

prepare: format generate-hw-config
    nixos-generate-config --no-filesystems --root /mnt
    cp "{{justfile_directory()}}/configuration.nix" /mnt/etc/nixos/configuration.nix
    cp "{{justfile_directory()}}/disko-config.nix" /mnt/etc/nixos/disko-config.nix

format:
    mkdir -p /boot
    openssl genrsa -out "{{key}}" 4096
    chmod -v 0400 "{{key}}"
    chown root:root "{{key}}"
    sudo nix run github:nix-community/disko -- --mode disko "{{justfile_directory()}}/disko-config.nix"
    cp "{{key}}" "/mnt/{{key}}"

