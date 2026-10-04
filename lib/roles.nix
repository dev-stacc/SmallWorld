# What each role contributes, split by where it has to land:
#   system - NixOS modules
#   home   - home-manager modules for the primary user
#   unfree - unfree package names this role is permitted to build
#
# `base` is implicit on every host (see mkHost.nix); everything else is opt-in
# from the registry in hosts/default.nix.
{
    base = {
        system = [ ../modules/system/profiles/base ];
        home   = [ ../modules/home/profiles/base ];
    };

    # graphical session: bluetooth, sound, the nur overlay librewolf needs,
    # plus the themed desktop userland
    desktop = {
        system = [ ../modules/system/profiles/desktop ];
        home   = [ ../modules/home/profiles/desktop ];
    };

    # nixvim with the full LSP stack. Headless hosts deliberately skip this and
    # use the plain `vim` from modules/system/profiles/base/packages.nix.
    editor = {
        home = [ ../modules/home/profiles/editor ];
    };

    # the two portable hosts; everything else is ethernet-tethered
    wireless = {
        system = [ ../modules/system/profiles/wireless.nix ];
    };

    gaming = {
        system = [ ../modules/system/profiles/gaming ];
        unfree = [
            "steam"
            "steam-original"
            "steam-unwrapped"
            "steam-run"
        ];
    };

    # cluster/deploy tooling: colmena, kubectl, helm, flux, vault
    admin = {
        system = [ ../modules/system/profiles/admin ];
        unfree = [ "vault" ];
    };

    # headless: never sleep, ignore the lid
    server = {
        system = [ ../modules/system/profiles/server/always-on.nix ];
    };

    k3s-agent = {
        system = [ ../modules/system/profiles/server/k3s-agent.nix ];
    };
}
