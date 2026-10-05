# The host registry: the one place that says what each machine is for.
#   hostName - networking.hostName and the nixosConfigurations attribute name
#   roles    - see lib/roles.nix ("base" is always included)
#   unfree   - unfree packages this host installs itself, on top of its roles'
#   secrets  - false = holds no key that can decrypt secrets/secrets.yaml
#   deploy   - false keeps the host out of colmena (rebuilt locally instead)
{
    arcturus = {
        hostName = "Arcturus";
        roles = [ "desktop" "editor" "gaming" "admin" "wireless" ];
        unfree = [ "claude-code" "discord" ];
        deploy = false;
    };

    # easy to steal: deliberately holds no decryptable secrets, and is absent
    # from .sops.yaml. Joins the tailnet by hand rather than via a sops key.
    # intel compute stick: no lid switch, so Mod+L is the only trigger
    alula = {
        hostName = "Alula";
        roles = [ "desktop" "editor" "wireless" ];
        unfree = [ "claude-code" ];
        secrets = false;
    };

    antinoos = {
        hostName = "Antinoos";
        roles = [ "desktop" "editor" "gaming" ];
    };

    amateus = {
        hostName = "Amateus";
        roles = [ "server" ];
    };

    argus = {
        hostName = "Argus";
        roles = [ "server" ];
    };

    # runs the vault server itself, so it needs the allowance without the
    # full admin toolchain
    asta = {
        hostName = "Asta";
        roles = [ "server" ];
        unfree = [ "vault" ];
    };

    aperture = {
        hostName = "Aperture";
        roles = [ "server" "k3s-agent" ];
    };

    atlas = {
        hostName = "Atlas";
        roles = [ "server" "k3s-agent" ];
    };
}
