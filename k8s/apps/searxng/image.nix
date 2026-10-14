{ pkgs, lib, theme } : let
    searxng = pkgs.searxng;

    static = import ./static.nix { inherit pkgs lib theme searxng; };

    pythonPath = pkgs.python3.pkgs.makePythonPath (
        [ searxng ] ++ searxng.propagatedBuildInputs
    );

    server = pkgs.runCommand "searxng-server" {
        nativeBuildInputs = [ pkgs.makeWrapper ];
    } ''
        mkdir -p $out/bin
        makeWrapper ${pkgs.python3Packages.granian}/bin/granian $out/bin/searxng-server \
            --set PYTHONPATH ${lib.escapeShellArg pythonPath} \
            --add-flags searx.webapp:app
    '';

    passwd = pkgs.writeTextDir "etc/passwd" ''
        root:x:0:0:root:/:/sbin/nologin
        searxng:x:977:977:searxng:/srv:/sbin/nologin
    '';

    group = pkgs.writeTextDir "etc/group" ''
        root:x:0:
        searxng:x:977:
    '';

    nsswitch = pkgs.writeTextDir "etc/nsswitch.conf" ''
        hosts: files dns
    '';

    layout = pkgs.runCommand "searxng-layout" { } ''
        mkdir -p $out/srv
        ln -s ${static} $out/srv/static
    '';
in pkgs.dockerTools.buildLayeredImage {
    name = "searxng";
    tag = "nix";

    contents = [ server pkgs.cacert passwd group nsswitch layout ];

    extraCommands = ''
        mkdir -p tmp var/cache/searxng
        chmod 1777 tmp
        chmod 0777 var/cache/searxng
    '';

    config = {
        Entrypoint = [ "${server}/bin/searxng-server" ];
        User = "977:977";
        WorkingDir = "/srv";

        Env = [
            "SEARXNG_SETTINGS_PATH=/etc/searxng/settings.yml"
            "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            "GRANIAN_INTERFACE=wsgi"
            "GRANIAN_HOST=::"
            "GRANIAN_PORT=8080"
            "GRANIAN_WEBSOCKETS=false"
        ];

        ExposedPorts = { "8080/tcp" = { }; };
    };
}
