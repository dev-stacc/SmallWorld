_oss() {
    local cur prev words cword
    _init_completion || return

    local subs="agent chat models running runs show"
    local common="-M --model -m -e --temp --seed --wait --no-wait -h --help"
    local models="@models@"

    case $prev in
        -M | --model)
            mapfile -t COMPREPLY < <(compgen -W "$models" -- "$cur")
            return
            ;;
        -e | --effort)
            mapfile -t COMPREPLY < <(compgen -W "low medium high" -- "$cur")
            return
            ;;
        -m | --max-tokens | --temp | --seed | --minutes | --max-turns | --max-wall)
            return
            ;;
    esac

    case ${words[1]} in
        agent)
            mapfile -t COMPREPLY < <(compgen -W "$common --authorize --minutes --text --effort --max-turns --max-tokens --max-tokens-total --max-wall" -- "$cur")
            return
            ;;
        chat)
            mapfile -t COMPREPLY < <(compgen -W "$common --effort --max-tokens --resume --think --no-think" -- "$cur")
            return
            ;;
        show)
            return
            ;;
    esac

    if [ "$cword" -eq 1 ]; then
        mapfile -t COMPREPLY < <(compgen -W "$subs $common --json --stream --no-stream --think --no-think --strict" -- "$cur")
        return
    fi

    mapfile -t COMPREPLY < <(compgen -W "$common --json --stream --no-stream --think --no-think --strict" -- "$cur")
}

complete -F _oss oss
