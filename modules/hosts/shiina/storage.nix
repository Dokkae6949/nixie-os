{ inputs, ... }:

{
  flake.modules.nixos.shiina = { lib, pkgs, ... }: {
    imports = [ inputs.disko.nixosModules.disko ];

    boot.initrd.systemd.enable = true;
    boot.initrd.systemd.services.rollback-root = {
      description = "Rotate and recreate the ephemeral Btrfs root subvolume";
      requiredBy = [ "sysroot.mount" ];
      after = [
        "initrd-root-device.target"
        "systemd-hibernate-resume.service"
      ];
      before = [ "sysroot.mount" ];
      unitConfig.DefaultDependencies = false;
      path = with pkgs; [
        btrfs-progs
        coreutils
        findutils
        util-linux
      ];
      serviceConfig.Type = "oneshot";

      script = ''
        set -euo pipefail

        readonly device=/dev/disk/by-label/nixos
        readonly mount_point=/btrfs_tmp
        mounted=0

        cleanup() {
          if (( mounted == 1 )); then
            umount "$mount_point"
          fi
        }
        trap cleanup EXIT

        mkdir -p "$mount_point"
        mount -t btrfs -o subvolid=5 "$device" "$mount_point"
        mounted=1
        mkdir -p "$mount_point/roots.old"

        find "$mount_point/roots.old" \
          -mindepth 1 \
          -maxdepth 1 \
          -type d \
          -mmin +10080 \
          -print0 |
          while IFS= read -r -d "" old_root; do
            if btrfs subvolume show "$old_root" >/dev/null 2>&1; then
              btrfs subvolume delete --recursive "$old_root"
            else
              echo "Not deleting non-subvolume path: $old_root" >&2
            fi
          done

        if [[ -e "$mount_point/root" ]]; then
          if ! btrfs subvolume show "$mount_point/root" >/dev/null 2>&1; then
            echo "$mount_point/root exists but is not a Btrfs subvolume" >&2
            exit 1
          fi

          timestamp="$(date -u '+%Y-%m-%d_%H-%M-%S')"
          destination="$mount_point/roots.old/$timestamp"
          suffix=0

          while [[ -e "$destination" ]]; do
            suffix=$((suffix + 1))
            destination="$mount_point/roots.old/$timestamp-$suffix"
          done

          mv -- "$mount_point/root" "$destination"
          touch -- "$destination"
        fi

        btrfs subvolume create "$mount_point/root"
      '';
    };

    disko.devices.disk.main = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          esp = {
            priority = 1;
            name = "ESP";
            start = "1M";
            end = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };

          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-L" "nixos" "-f" ];
              subvolumes = {
                "/root" = {
                  mountpoint = "/";
                  mountOptions = [ "subvol=root" "compress=zstd" "noatime" ];
                };
                "/home" = {
                  mountpoint = "/home";
                  mountOptions = [ "subvol=home" "compress=zstd" "noatime" ];
                };
                "/nix" = {
                  mountpoint = "/nix";
                  mountOptions = [ "subvol=nix" "compress=zstd" "noatime" ];
                };
                "/persist" = {
                  mountpoint = "/.persist";
                  mountOptions = [ "subvol=persist" "compress=zstd" "noatime" ];
                };
                "/swap" = {
                  mountpoint = "/.swap";
                  swap.swapfile.size = "20G";
                };
              };
            };
          };
        };
      };
    };

    fileSystems."/.persist".neededForBoot = lib.mkDefault true;
  };
}
