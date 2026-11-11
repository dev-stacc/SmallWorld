{ username, ... }: {
  boot.kernelModules = [ "tun" ];
  boot.supportedFilesystems = [ "btrfs" ];

  fileSystems."/home/${username}/media" = {
    device = "/dev/disk/by-uuid/02e853be-d53c-4a43-b419-718097c0417b";
    fsType = "btrfs";
    options = [ "subvol=@media" "noatime" "space_cache=v2" "nofail" "x-systemd.device-timeout=10s" ];
  };

  fileSystems."/home/${username}/transcode" = {
    device = "/dev/disk/by-uuid/02e853be-d53c-4a43-b419-718097c0417b";
    fsType = "btrfs";
    options = [ "subvol=@transcode" "noatime" "space_cache=v2" "nofail" "x-systemd.device-timeout=10s" ];
  };

  fileSystems."/home/${username}/jellyfin-config" = {
    device = "/dev/disk/by-uuid/02e853be-d53c-4a43-b419-718097c0417b";
    fsType = "btrfs";
    options = [ "subvol=@jellyfin-config" "noatime" "space_cache=v2" "nofail" "x-systemd.device-timeout=10s" ];
  };

  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ "/home/${username}/media" ];
    interval = "Sun *-*-* 09:00:00";
  };
}
