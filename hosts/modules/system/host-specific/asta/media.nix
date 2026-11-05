{ username, ... }: {
  boot.kernelModules = [ "tun" ];
  boot.supportedFilesystems = [ "btrfs" ];

  fileSystems."/home/${username}/media" = {
    device = "/dev/disk/by-uuid/02e853be-d53c-4a43-b419-718097c0417b";
    fsType = "btrfs";
    options = [ "subvol=@media" "noatime" "space_cache=v2" ];
  };

  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ "/home/${username}/media" ];
    interval = "Sun *-*-* 09:00:00";
  };

  systemd.tmpfiles.rules = [
    "d /home/${username}/jellyfin/config 0755 ${username} users -"
    "s /home/${username}/navidrome 0755 ${username} users -"
  ];
}
