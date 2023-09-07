key := "/boot/luks.key"

@default:
    just --list

format:
    mkdir -p /boot
    openssl genrsa -out "{{key}}" 4096
    chmod -v 0400 "{{key}}"
    chown root:root "{{key}}"
    sudo nix run github:nix-community/disko -- --mode disko /root/dbost-server/disko-config.nix
    cp "{{key}}" "/mnt/{{key}}"

