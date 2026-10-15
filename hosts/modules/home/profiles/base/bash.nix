{ pkgs, lib, theme, ... } : let
    hexDigits = {
        "0" = 0; "1" = 1; "2" = 2; "3" = 3; "4" = 4; "5" = 5; "6" = 6; "7" = 7;
        "8" = 8; "9" = 9; "a" = 10; "b" = 11; "c" = 12; "d" = 13; "e" = 14; "f" = 15;
    };

    toDec = s: lib.foldl' (acc: ch: acc * 16 + hexDigits.${ch}) 0
        (lib.stringToCharacters (lib.toLower s));

    rgb = v: let p = i: toString (toDec (builtins.substring i 2 v)); in
        "${p 0};${p 2};${p 4}";

    fg = v: "\\[\\e[38;2;${rgb v}m\\]";
    off = "\\[\\e[0m\\]";

    c = theme.base16;

    blue = c.base03;
    red = c.base02;
    yellow = c.base04;
in {
    programs.bash = {
        enable = true;

        historyControl = [
            "ignorespace"
            "ignoredups"
        ];

        initExtra = ''
            source ${pkgs.git}/share/bash-completion/completions/git-prompt.sh

            export GIT_PS1_SHOWDIRTYSTATE=1
            export GIT_PS1_SHOWSTASHSTATE=1
            export GIT_PS1_SHOWUNTRACKEDFILES=1
            export GIT_PS1_SHOWUPSTREAM=auto

            __dir_depth() {
                local rel slashes

                if [ "$PWD" = "$HOME" ] || [ "$PWD" = "/" ]; then
                    __depth=0
                    return
                fi

                if [[ $PWD == "$HOME"/* ]]; then
                    rel=''${PWD#"$HOME"/}
                else
                    rel=''${PWD#/}
                fi

                slashes=''${rel//[!\/]/}
                __depth=$(( ''${#slashes} + 1 ))
            }

            __git_state_words() {
                local st=$1 tree="" words=""

                [[ $st == *'*'* ]] && tree+=" dirty"
                [[ $st == *'+'* ]] && tree+=" staged"
                [[ $st == *'%'* ]] && tree+=" untracked"
                [ -z "$tree" ] && tree=" clean"

                words="$tree"
                [[ $st == *'$'* ]] && words+=" stash"

                if [[ $st == *'<>'* ]]; then
                    words+=" diverged"
                elif [[ $st == *'<'* ]]; then
                    words+=" behind"
                elif [[ $st == *'>'* ]]; then
                    words+=" ahead"
                elif [[ $st == *'='* ]]; then
                    words+=" synced"
                else
                    words+=" local"
                fi

                printf '%s' "''${words# }"
            }

            __prompt() {
                local gitinfo branch state words repo
                local host dir dirseg plain disp cols roomy tight snug

                cols=''${COLUMNS:-80}
                host=''${HOSTNAME%%.*}

                __dir_depth
                if [ "$PWD" = "$HOME" ]; then
                    dir="~"
                else
                    dir=''${PWD##*/}
                fi
                dirseg="[$__depth]/$dir"

                gitinfo=$(__git_ps1 "%s")
                plain=""

                if [ -n "$gitinfo" ]; then
                    branch=''${gitinfo%% *}
                    state=''${gitinfo#"$branch"}
                    words=$(__git_state_words "''${state# }")

                    repo=$(git rev-parse --show-toplevel 2>/dev/null)
                    repo=''${repo##*/}
                    if [ "$repo" = "''${PWD##*/}" ]; then
                        repo=""
                    else
                        repo="$repo|"
                    fi

                    plain="$repo$branch[$words]"
                    disp="${fg red}$repo$branch[${fg yellow}$words${fg red}]${off}"
                fi

                if [ -z "$plain" ]; then
                    PS1="${fg blue}$host ❯ $dirseg${off}\n${fg red}❯${off} "
                    return
                fi

                (( roomy = ''${#host} + 3 + ''${#dirseg} + 3 + ''${#plain} ))
                (( tight = ''${#host} + 2 + ''${#dirseg} + 2 + ''${#plain} ))
                (( snug  = ''${#host} + 1 + ''${#dirseg} + 1 + ''${#plain} ))

                if (( roomy <= cols )); then
                    PS1="${fg blue}$host ❯ $dirseg${off} ${fg red}❮ $disp\n${fg red}❯${off} "
                elif (( tight <= cols )); then
                    PS1="${fg blue}$host❯ $dirseg${off} ${fg red}❮$disp\n${fg red}❯${off} "
                elif (( snug <= cols )); then
                    PS1="${fg blue}$host❯$dirseg${off}${fg red}❮$disp\n${fg red}❯${off} "
                else
                    PS1="${fg blue}$host ❯ $dirseg${off}\n$disp ${fg red}❯${off} "
                fi
            }

            PROMPT_COMMAND=__prompt
        '';
    };
}
