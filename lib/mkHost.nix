# Builds a host from its registry entry. nixosConfigurations and colmena are
# both derived from mkModules, so the two outputs cannot drift apart.
{ inputs, lib, username, tailnet, theme, hosts }:
let
    roles = import ./roles.nix;

    specialArgs = { inherit inputs username tailnet theme; };

    # A host-specific home module is optional - several hosts have nothing of
    # their own to add. The system one is required, so a renamed or mistyped
    # host directory fails loudly instead of silently contributing nothing.
    optionalModule = path: lib.optional (builtins.pathExists path) path;

    # Guard the other direction: a directory under host-specific/ or hosts/
    # that no registry entry claims is dead weight nothing will ever import.
    known = builtins.attrNames hosts;
    dirsIn = path:
        builtins.attrNames (
            lib.filterAttrs (_: type: type == "directory") (builtins.readDir path)
        );
    orphans = lib.unique (
        lib.subtractLists known (dirsIn ../hosts)
        ++ lib.subtractLists known (dirsIn ../modules/system/host-specific)
        ++ lib.subtractLists known (dirsIn ../modules/home/host-specific)
    );

    mkModules = name: host:
        let
            active   = map (r: roles.${r}) ([ "base" ] ++ host.roles);
            sysMods  = lib.concatMap (r: r.system or [ ]) active;
            homeMods = lib.concatMap (r: r.home   or [ ]) active;

            # Unfree allowances are per-role, plus anything the host itself
            # installs. Built here from static registry data rather than as a
            # NixOS option, so the predicate never has to read `config` -
            # that would close a cycle through pkgs.
            unfree = lib.unique (
                lib.concatMap (r: r.unfree or [ ]) active ++ (host.unfree or [ ])
            );
        in
            sysMods
            ++ [
                ../hosts/${name}/hardware-configuration.nix
                ../modules/system/host-specific/${name}
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
                            ++ optionalModule ../modules/home/host-specific/${name};

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

    # colmena takes a module list, not a built system
    mkNode = name: host: { ... } : {
        imports = mkModules name host;

        deployment = {
            targetHost = name;
            targetUser = username;
        };
    };
}
