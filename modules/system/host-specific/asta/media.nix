{ ... }: {
  systemd.tmpfiles.rules = [
    "d /home/anastasia/media 0755 anastasia users -"
    "d /home/anastasia/media/movies 0755 anastasia users -"
    "d /home/anastasia/media/shows 0755 anastasia users -"
    "d /home/anastasia/media/music 0755 anastasia users -"
    "d /home/anastasia/jellyfin/config 0755 anastasia users -"
    "s /home/anastasia/navidrome 0755 anastasia users -"
  ];
}
