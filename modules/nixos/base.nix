{ config, pkgs, ... } : {
    nix.settings.experimental-features = ["nix-command" "flakes"];
    system.stateVersion = "25.11";
    time.timeZone = "America/New_York";

    environment.pathsToLink = [
        "/share/applications"
        "/share/xdg-desktop-portal"
    ];

    users.users.anastasia = {
        isNormalUser = true;
        openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDkKw83ZCeZFAm2c3nmknwC3TaC18QxUSitVmVlVUv6s anastasia@arcturus"
        ];
        extraGroups = [
            "wheel"
            "networkmanager"
            "video"
            "input"
            "audio"
            "cdrom"
        ];
    };

    security.sudo.extraRules = [{
        users = [ "anastasia" ];
        commands = [{
            command = "ALL";
            options = [ "NOPASSWD" ];
        }];
    }];

    programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
    };

    nix.settings.trusted-users = [
        "root"
        "anastasia"
    ];
}
