{
    arcturus = {
        hostName = "Arcturus";
        roles = [ "desktop" "editor" "gaming" "admin" "wireless" ];
        unfree = [ "claude-code" "discord" ];
        deploy = false;
    };

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
        secrets = false;
    };

    albireo = {
        hostName = "Albireo";
        roles = [ "server" "k3s-agent" ];
    };
}
