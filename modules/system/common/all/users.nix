{ config, pkgs, username, ... } : {
    users.users.${username} = {
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
            "corectrl"
        ];
    };

    security.sudo.extraRules = [{
        users = [ username ];
        commands = [{
            command = "ALL";
            options = [ "NOPASSWD" ];
        }];
    }];

    nix.settings.trusted-users = [
        "root"
        username
    ];
}
