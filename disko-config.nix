let
  # ESP partition (EFI boot)
	esp_partition = {
		label = "EFI";
		name = "ESP";
		size = "512M";
		type = "EF00";
		content = {
			type = "filesystem";
			format = "vfat";
			mountpoint = "/boot";
			mountOptions = [
				"defaults"
			];
		};
	};

	# BTRFS content (subvolume layout)
	btrfs_content = {
		type = "btrfs";
		extraArgs = [ "-f" ]; # Override existing partition
		subvolumes = {
			# Subvolume name is different from mountpoint
			"/@root" = {
				mountpoint = "/";
			};
			"/@home" = {
				mountpoint = "/home";
				mountOptions = [ "compress=zstd" ];
			};
			"/@nix" = {
				mountpoint = "/nix";
				mountOptions = [ "compress=zstd" "noatime" ];
			};
			"@swap" = {
				mountpoint = "/.swapvol";
			};
		};

		postCreateHook = ''
			mount -t btrfs /dev/mapper/crypted -o subvol=@swap /mnt
			btrfs filesystem mkswapfile --size 8G /mnt/swapfile
			umount /mnt
		'';
	};

	# Luks encrypted partition
	luks_partition = {
		name = "luks";
		size = "100%";
		content = {
			type = "luks";
			name = "crypted";
			extraOpenArgs = [ "--allow-discards" ];
			# if you want to use the key for interactive login be sure there is no trailing newline
			# for example use `echo -n "password" > /tmp/secret.key`
			settings.keyFile = "/boot/luks.key";
			content = btrfs_content;
		};
	};
	
in
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            ESP = esp_partition;
            luks = luks_partition;
          };
        };
      };
    };
  };
}
