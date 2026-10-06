{ inputs, lib, username, tailnet, theme, hosts }:
let
    roles = import ./roles.nix;

    specialArgs = { inherit inputs username tailnet theme; };

    optionalModule = path: lib.optional (builtins.pathExists path) path;

    known = builtins.attrNames hosts;
    dirsIn = path:
        builtins.attrNames (
            lib.filterAttrs (_: type: type == "directory") (builtins.readDir path)
        );
    orphans = lib.unique (
        lib.subtractLists known (dirsIn ./modules/system/host-specific)
        ++ lib.subtractLists known (dirsIn ./modules/home/host-specific)
    );

    mkModules = name: host:
        let
            active   = map (r: roles.${r}) ([ "base" ] ++ host.roles);
            sysMods  = lib.concatMap (r: r.system or [ ]) active;
            homeMods = lib.concatMap (r: r.home   or [ ]) active;

            unfree = lib.unique (
                lib.concatMap (r: r.unfree or [ ]) active ++ (host.unfree or [ ])
            );
        in
            sysMods
            ++ [
                ./modules/system/host-specific/${name}/hardware-configuration.nix
                ./modules/system/host-specific/${name}
            ]
            ++ [
                { networking.hostName = host.hostName; }

                { biggerworld.secrets.enable = host.secrets or true; }

                {
                    nixpkgs.config.allowUnfreePredicate =
                        pkg: builtins.elem (lib.getName pkg) unfree;
                }

                {
                    assertions = [{
                        assertion = orphans == [ ];
                        message =
                            "host directories with no entry in hosts/default.nix: "
                            + lib.concatStringsSep ", " orphans;
                    }];
                }

                {
                    home-manager.users.${username} = {
                        imports = homeMods
                            ++ optionalModule ./modules/home/host-specific/${name};

                        home = {
                            username = username;
                            homeDirectory = "/home/${username}";
                            stateVersion = "25.11";
                            sessionVariables.SOPS_AGE_KEY_FILE =
                                "/home/${username}/.sops/keys.txt";
                        };
                    };
                }
            ];
in {
    inherit specialArgs;

    mkSystem = name: host: inputs.nixpkgs.lib.nixosSystem {
        inherit specialArgs;
        modules = mkModules name host;
    };

    mkNode = name: host: { ... } : {
        imports = mkModules name host;

        deployment = {
            targetHost = name;
            targetUser = username;
        };
    };
}
