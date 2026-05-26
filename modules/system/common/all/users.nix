{ config, pkgs, ... } : {
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

    nix.settings.trusted-users = [
        "root"
        "anastasia"
    ];
}
