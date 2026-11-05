{ pkgs, lib, theme } : let
    themeCss = import ./theme.nix { inherit pkgs lib theme; };

    src = pkgs.fetchgit {
        url = "https://git.lolcat.ca/lolcat/4get.git";
        rev = "42d0252e2ff1d15a4adfee9fef0decee6aefcccb";
        hash = "sha256-y+lvM7sK2nHH5JZbWd0M7VA/OI/kp0vhzKyjGBz7J3M=";
    };
in pkgs.runCommand "fourget-root" { } ''
    cp -a ${src} $out
    chmod -R u+w $out

    rm -rf $out/static/themes
    mkdir -p $out/static/themes
    cp ${themeCss} $out/static/themes/biggerworld.css

    substituteInPlace $out/data/config.php \
        --replace-fail 'const SERVER_NAME = "4get";' \
                       'const SERVER_NAME = "local";' \
        --replace-fail 'const DEFAULT_THEME = "Dark";' \
                       'const DEFAULT_THEME = "biggerworld";'

    ${pkgs.perl}/bin/perl -0pi -e \
        's/\bconst INSTANCES = \[.*?\];/const INSTANCES = [];/s' \
        $out/data/config.php
    grep -q 'const INSTANCES = \[\];' $out/data/config.php
''
