{ username, ... } : {
    programs.git = {
        enable = true;
        settings = {
            user = {
                name = "Anastasia";
                email = "89532616+dev-stacc@users.noreply.github.com";
            };
            credential.helper = "store --file /home/${username}/.git-credentials";
        };
    };
}
