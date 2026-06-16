{ username, ... } : {
    virtualization.docker = {
        enable = true;
    };
    users.users.${username}.extraGroups = [
        "docker"
    ];
}
