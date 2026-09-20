{ ... } : {
    programs.bash = {
        enable = true;
        historyControl = [
            "ignorespace"
            "ignoredups"
        ];
    };
}
