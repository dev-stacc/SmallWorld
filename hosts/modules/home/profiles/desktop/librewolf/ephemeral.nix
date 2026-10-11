{ pkgs, lib, config, ... } : let
    profile = "${config.home.homeDirectory}/.librewolf/default";
    cache = "${config.home.homeDirectory}/.cache/librewolf/default";

    preserved = [ ".keep" "user.js" "chrome" "extensions" "search.json.mozlz4" ];

    preserveArgs = lib.concatMapStringsSep " " (n: "! -name ${lib.escapeShellArg n}") preserved;

    launcher = pkgs.writeShellApplication {
        name = "librewolf-ephemeral";

        runtimeInputs = with pkgs; [ coreutils findutils procps util-linux ];

        text = ''
            profile=${lib.escapeShellArg profile}
            cache=${lib.escapeShellArg cache}
            guard="''${XDG_RUNTIME_DIR:-/tmp}/librewolf-ephemeral.lock"

            running() {
                local target pid
                if target=$(readlink "$profile/lock" 2>/dev/null); then
                    pid=''${target##*+}
                    if [ -n "$pid" ] && [ -d "/proc/$pid" ]; then
                        return 0
                    fi
                fi
                pgrep -u "$(id -u)" -f 'lib/librewolf/librewolf|bin/librewolf( |$)' > /dev/null
            }

            wipe() {
                if [ -d "$profile" ]; then
                    find "$profile" -mindepth 1 -maxdepth 1 ${preserveArgs} -exec rm -rf -- {} +
                fi
                rm -rf -- "$cache/cache2" "$cache/thumbnails"
                rm -f -- "$cache"/activity-stream.*
            }

            wipe_when_idle() {
                flock 9
                if ! running; then
                    wipe
                fi
                flock -u 9
            }

            exec 9> "$guard"

            wipe_when_idle

            ${config.programs.librewolf.finalPackage}/bin/librewolf "$@" || true

            while running; do
                sleep 2
            done

            wipe_when_idle
        '';
    };
in {
    home.packages = [ launcher ];

    home.sessionVariables.BROWSER = "librewolf-ephemeral";

    xdg.desktopEntries.librewolf = {
        name = "LibreWolf";
        genericName = "Web Browser";
        exec = "${launcher}/bin/librewolf-ephemeral --name librewolf %U";
        icon = "librewolf";
        terminal = false;
        startupNotify = true;
        categories = [ "Network" "WebBrowser" ];
        mimeType = [
            "text/html"
            "text/xml"
            "application/xhtml+xml"
            "application/vnd.mozilla.xul+xml"
            "x-scheme-handler/http"
            "x-scheme-handler/https"
        ];
        settings = {
            StartupWMClass = "librewolf";
        };
        actions = {
            new-window = {
                name = "New Window";
                exec = "${launcher}/bin/librewolf-ephemeral --new-window %U";
            };
            new-private-window = {
                name = "New Private Window";
                exec = "${launcher}/bin/librewolf-ephemeral --private-window %U";
            };
        };
    };
}
