{ config, pkgs, ... } : {
    nix.settings.experimental-features = ["nix-command" "flakes"];
    system.stateVersion = "25.11";
    time.timeZone = "America/New_York";
    hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [ intel-media-driver ];
    };

    boot = {
        loader.systemd-boot.enable = true;
        loader.efi.canTouchEfiVariables = true;
    };

    environment.pathsToLink = [
        "/share/applications"
        "/share/xdg-desktop-portal"
    ];

    users.users.anastasia = {
        isNormalUser = true;
        extraGroups = [
            "wheel"
            "networkmanager"
            "video"
            "input"
            "audio"
        ];
    };

    programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
    };
}
