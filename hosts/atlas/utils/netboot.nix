let
  flake = builtins.getFlake "/home/anastasia/BW";
  nixpkgs = flake.inputs.nixpkgs;
  pkgsFor = nixpkgs.legacyPackages.x86_64-linux;

  sys = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      "${nixpkgs}/nixos/modules/installer/netboot/netboot-minimal.nix"
      (
        { config, pkgs, lib, ... }:
        {
          hardware.firmware = [
            (pkgs.runCommand "bnx2-firmware" { } ''
              mkdir -p $out/lib/firmware/bnx2
              cp -r ${pkgs.linux-firmware}/lib/firmware/bnx2/. $out/lib/firmware/bnx2/
            '')
          ];

          nix.settings.experimental-features = [ "nix-command" "flakes" ];

          services.openssh = {
            enable = true;
            settings.PermitRootLogin = "yes";
          };

          users.users.root.openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDkKw83ZCeZFAm2c3nmknwC3TaC18QxUSitVmVlVUv6s anastasia@arcturus"
          ];

          environment.systemPackages = with pkgs; [
            parted
            gptfdisk
            pciutils
            usbutils
            ethtool
          ];

          system.stateVersion = lib.mkDefault config.system.nixos.release;
        }
      )
    ];
  };
in
{
  inherit (sys.config.system.build) netbootRamdisk netbootIpxeScript kernel;
  ipxe = pkgsFor.ipxe;
}
