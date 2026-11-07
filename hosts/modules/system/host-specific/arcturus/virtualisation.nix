{ username, ... } : {
    virtualisation.docker = {
        enable = true;
    };
    users.users.${username}.extraGroups = [
        "docker"
    ];

    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
