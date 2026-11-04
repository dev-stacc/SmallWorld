{ pkgs, theme } : let
    c = theme.base16;

    hex = value: "#${value}";

    background = hex c.base00;
    text = hex c.base05;
    primary = hex c.base02;
    secondary = hex c.base03;
    highlight = hex c.base04;
    special = hex c.base06;
    deep = hex c.base07;
    light = hex c.base08;

    palette = {
        Background = background;
        Foreground = text;
        LightBlue = secondary;
        AccentBlue = secondary;
        AccentCyan = secondary;
        AccentPurple = primary;
        AccentGreen = special;
        AccentYellow = highlight;
        AccentRed = primary;
        AccentRedDim = deep;
        AccentYellowDim = deep;
        DiffAdded = light;
        DiffRemoved = deep;
        Comment = deep;
        Gray = deep;
        GradientColors = [ primary highlight ];
    };

    custom = palette // {
        name = "biggerworld";
        type = "custom";

        text = {
            primary = text;
            secondary = primary;
            link = secondary;
            accent = highlight;
            code = secondary;
        };

        background = {
            primary = background;
            diff = { added = light; removed = deep; };
        };

        border = { default = deep; focused = primary; };

        ui = { comment = deep; symbol = primary; gradient = [ primary highlight ]; };

        status = {
            error = secondary;
            success = special;
            warning = highlight;
            errorDim = deep;
            warningDim = deep;
        };
    };

    readOnly = [
        "Read"
        "ExitPlanMode"
        "Bash(kubectl get *)"
        "Bash(kubectl describe *)"
        "Bash(kubectl logs *)"
        "Bash(kubectl top *)"
        "Bash(kubectl events *)"
        "Bash(kubectl explain *)"
        "Bash(kubectl api-resources *)"
        "Bash(kubectl cluster-info)"
        "Bash(kubectl version *)"
        "Bash(flux get *)"
        "Bash(flux check *)"
        "Bash(flux logs *)"
        "Bash(flux tree *)"
        "Bash(flux stats *)"
        "Bash(flux events *)"
        "Bash(journalctl *)"
        "Bash(systemctl status *)"
        "Bash(systemctl cat *)"
        "Bash(systemctl show *)"
        "Bash(systemctl list-units *)"
        "Bash(systemctl list-timers *)"
        "Bash(systemctl is-active *)"
        "Bash(systemctl is-enabled *)"
        "Bash(git status *)"
        "Bash(git log *)"
        "Bash(git diff *)"
        "Bash(git show *)"
        "Bash(git blame *)"
        "Bash(git branch *)"
        "Bash(ls *)"
        "Bash(cat *)"
        "Bash(head *)"
        "Bash(tail *)"
        "Bash(wc *)"
        "Bash(stat *)"
        "Bash(file *)"
        "Bash(du *)"
        "Bash(df *)"
        "Bash(rg *)"
        "Bash(grep *)"
        "Bash(jq *)"
        "Bash(yq *)"
        "Bash(sort *)"
        "Bash(uniq *)"
        "Bash(cut *)"
        "Bash(diff *)"
        "Bash(realpath *)"
        "Bash(readlink *)"
        "Bash(uname *)"
        "Bash(uptime)"
        "Bash(free *)"
        "Bash(ip a)"
        "Bash(ip r)"
        "Bash(ss *)"
        "Bash(dig *)"
        "Bash(host *)"
        "Bash(ping *)"
        "Bash(tailscale status *)"
        "Bash(tailscale ping *)"
        "Bash(tailscale netcheck)"
        "Bash(nix eval *)"
        "Bash(nix log *)"
        "Bash(nix path-info *)"
        "Bash(nix flake metadata *)"
        "Bash(nix flake show *)"
        "Bash(nix-instantiate --parse *)"
    ];

    confirm = [
        "Bash(kubectl get secret*)"
        "Bash(kubectl get secrets*)"
        "Bash(kubectl describe secret*)"
        "Bash(kubectl exec *)"
        "Bash(curl *)"
        "Bash(wget *)"
    ];

    never = [
        "Read(//run/secrets/**)"
        "Read(//run/secrets.d/**)"
        "Read(~/.ssh/**)"
        "Read(~/.gnupg/**)"
        "Read(~/.config/sops/**)"
        "Read(/secrets/**)"
        "Edit(//run/secrets/**)"
        "Edit(/secrets/**)"
        "Bash(sudo *)"
        "Bash(doas *)"
        "Bash(run0 *)"
        "Bash(sops *)"
        "Bash(age *)"
        "Bash(age-keygen *)"
        "Bash(env)"
        "Bash(printenv *)"
        "Bash(rm *)"
        "Bash(dd *)"
        "Bash(mkfs *)"
        "Bash(shutdown *)"
        "Bash(reboot *)"
        "Bash(poweroff *)"
        "Bash(git push *)"
        "Bash(nixos-rebuild *)"
        "Bash(colmena *)"
        "Bash(kubectl delete *)"
        "Bash(flux uninstall *)"
        "Bash(oss *)"
        "Bash(coder *)"
    ];
in pkgs.writeText "qwen-system-defaults.json" (builtins.toJSON {
    "$version" = 4;

    ui = {
        theme = "biggerworld";
        customThemes.biggerworld = custom;
    };

    general = {
        vimMode = true;
        gitCoAuthor = false;
        checkpointing.enabled = true;
    };

    tools = {
        toolSearch.enabled = false;

        exclude = [
            "agent"
            "monitor"
            "skill"
            "todo_write"
            "save_memory"
            "notebook_edit"
            "web_fetch"
            "send_message"
            "enter_worktree"
            "exit_worktree"
            "lsp"
        ];
    };

    memory = {
        enableManagedAutoMemory = false;
        enableManagedAutoDream = false;
        enableAutoSkill = false;
    };

    privacy.usageStatisticsEnabled = false;

    telemetry.enabled = false;

    security.auth.selectedType = "openai";

    model = {
        name = "qwen3-coder";
        generationConfig.contextWindowSize = 32768;
        chatCompression.contextPercentageThreshold = 0.45;
    };

    permissions = {
        allow = readOnly;
        ask = confirm;
        deny = never;
    };
})
