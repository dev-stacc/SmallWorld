{ pkgs, ... } : {
    imports = [
        ./storage.nix
        ./nfs-server.nix
        ./media-sync.nix
        ./backup.nix
        ./k3s-service.nix
        ./graphics.nix
    ];

    # FIXME: X9SCA is almost certainly BIOS-only, but confirm /sys/firmware/efi
    # was absent, and take the device from lsblk
    boot.loader.grub = {
        enable = true;
        device = "/dev/sda";
    };

    boot = {
        # zfs lags mainline and this flake tracks nixos-unstable
        kernelPackages = pkgs.linuxPackages_6_18;

        kernelParams = [
            "console=ttyS0,115200n8"
            "console=tty0"
        ];
    };

    networking.hostId = "2d44c1fc";

    swapDevices = [{
        device = "/swapfile";
        size = 8192;  # FIXME: size against `free -g`
    }];
}
