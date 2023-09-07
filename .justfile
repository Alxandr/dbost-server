@default:
    just --list

format:
    mkdir -p /boot
    DEST="/boot/luks.key"
    openssl genrsa -out $DEST 4096
    chmod -v 0400 $DEST
    chown root:root $DEST
    sudo nix run github:nix-community/disko -- --mode disko /root/dbost-server/disko-config.nix
    cp /boot/luks.key /mnt/boot/luks.key

