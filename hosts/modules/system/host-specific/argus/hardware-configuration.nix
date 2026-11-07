{ config, lib, pkgs, modulesPath, ... } :
let
    firmware = "${pkgs.raspberrypifw}/share/raspberrypi/boot";

    configTxt = pkgs.writeText "config.txt" ''
        kernel=u-boot.bin
        arm_64bit=1
        enable_uart=1
        avoid_warnings=1
        gpu_mem=16
        dtoverlay=disable-bt

        [pi3]
        core_freq=250
    '';
in {
    imports = [
        (modulesPath + "/installer/sd-card/sd-image.nix")
    ];

    nixpkgs.hostPlatform = "aarch64-linux";

    boot = {
        loader = {
            grub.enable = false;
            generic-extlinux-compatible = {
                enable = true;
                configurationLimit = 3;
            };
        };

        initrd.availableKernelModules = [
            "mmc_block"
            "usbhid"
            "sdhci_iproc"
        ];

        kernelParams = [ "console=ttyAMA0,115200n8" "console=tty1" "cma=32M" ];
    };

    hardware = {
        enableAllHardware = lib.mkForce false;
        firmware = [ pkgs.raspberrypiWirelessFirmware ];
    };

    fileSystems."/".options = [ "noatime" "commit=600" ];

    sdImage = {
        compressImage = false;
        populateFirmwareCommands = ''
            cp ${firmware}/bootcode.bin $NIX_BUILD_TOP/firmware/
            cp ${firmware}/fixup*.dat $NIX_BUILD_TOP/firmware/
            cp ${firmware}/start*.elf $NIX_BUILD_TOP/firmware/
            cp ${firmware}/bcm2710-rpi-zero-2-w.dtb $NIX_BUILD_TOP/firmware/
            cp ${firmware}/bcm2710-rpi-zero-2.dtb $NIX_BUILD_TOP/firmware/
            cp ${pkgs.ubootRaspberryPiAarch64}/u-boot.bin $NIX_BUILD_TOP/firmware/u-boot.bin
            cp ${configTxt} $NIX_BUILD_TOP/firmware/config.txt
        '';
        populateRootCommands = ''
            mkdir -p ./files/boot
            ${config.boot.loader.generic-extlinux-compatible.populateCmd} \
                -c ${config.system.build.toplevel} -d ./files/boot
        '';
    };
}
