{
    base = {
        system = [ ./modules/system/profiles/base ];
        home   = [ ./modules/home/profiles/base ];
    };

    desktop = {
        system = [ ./modules/system/profiles/desktop ];
        home   = [ ./modules/home/profiles/desktop ];
    };

    editor = {
        home = [ ./modules/home/profiles/editor ];
    };

    wireless = {
        system = [ ./modules/system/profiles/wireless.nix ];
    };

    gaming = {
        system = [ ./modules/system/profiles/gaming ];
        unfree = [
            "steam"
            "steam-original"
            "steam-unwrapped"
            "steam-run"
        ];
    };

    admin = {
        system = [ ./modules/system/profiles/admin ];
        unfree = [ "vault" ];
    };

    server = {
        system = [ ./modules/system/profiles/server/always-on.nix ];
    };

    k3s-agent = {
        system = [ ./modules/system/profiles/server/k3s-agent.nix ];
    };
}
