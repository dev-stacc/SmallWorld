{ username, ... }: {
  boot.kernelModules = [ "tun" ];

  systemd.tmpfiles.rules = [
    "d /home/${username}/media 0755 ${username} users -"
    "d /home/${username}/media/movies 0755 ${username} users -"
    "d /home/${username}/media/shows 0755 ${username} users -"
    "d /home/${username}/media/music 0755 ${username} users -"
    "d /home/${username}/media/downloads 0755 ${username} users -"
    "d /home/${username}/media/downloads/complete 0755 ${username} users -"
    "d /home/${username}/media/downloads/incomplete 0755 ${username} users -"
    "d /home/${username}/jellyfin/config 0755 ${username} users -"
    "s /home/${username}/navidrome 0755 ${username} users -"
  ];
}
