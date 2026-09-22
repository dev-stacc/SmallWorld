{ username, ... }: {
  systemd.tmpfiles.rules = [
    "d /home/${username}/media 0755 ${username} users -"
    "d /home/${username}/media/movies 0755 ${username} users -"
    "d /home/${username}/media/shows 0755 ${username} users -"
    "d /home/${username}/media/music 0755 ${username} users -"
  ];
}
