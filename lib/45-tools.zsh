# =============================================================================
#  lib/45-tools.zsh — cached tool inits (eval) and managed completions
# =============================================================================


# =============================================================================
# plug eval   (cache the output of tool init commands: zoxide, starship, ...)
# =============================================================================

# _plug_eval_generate <name>   runs the stored command, caches its output.
_plug_eval_generate() {
    emulate -L zsh
    local name=$1 cmd out file tmp
    cmd=${PLUG_EVAL_CMDS[$name]}
    file="$PLUG_EVAL_DIR/$name.zsh"
    tmp="$file.tmp.$$"

    [[ -n $cmd ]] || return 1
    _plug_init_dirs

    out=$(eval "$cmd" </dev/null 2>>"$PLUG_LOG_FILE") || {
        _plug_log ERROR "eval failed: $name  ($cmd)"
        return 1
    }

    if [[ -z $out ]]; then
        _plug_log ERROR "eval produced no output: $name  ($cmd)"
        return 1
    fi

    { print -r -- "# plug eval: $name  <-  $cmd"; print -r -- "$out" } > "$tmp"

    if ! command zsh -n "$tmp" >/dev/null 2>&1; then
        _plug_log ERROR "eval output has a syntax error: $name  ($cmd)"
        command rm -f "$tmp"
        return 1
    fi

    command mv -f "$tmp" "$file"
}

plug_eval() {
    emulate -L zsh
    local sub=${1:-list}
    (( $# )) && shift

    local name cmd n
    local -i rc=0 found
    local re='^[A-Za-z0-9_.-]+$'

    _plug_load_evals

    case $sub in
        add)
            if (( $# < 2 )); then
                _plug_err "Usage: plug eval add <name> <command...>"
                _plug_info "Example: plug eval add zoxide zoxide init zsh"
                return 1
            fi
            name=$1; shift
            if ! [[ $name =~ $re ]]; then
                _plug_err "Invalid name: $name"
                return 1
            fi

            if (( $# == 1 )); then cmd=$1; else cmd=${(j: :)${(@q)argv}}; fi

            found=$(( ${PLUG_EVAL_NAMES[(Ie)$name]} ))
            PLUG_EVAL_CMDS[$name]=$cmd

            if ! _plug_eval_generate "$name"; then
                (( found )) || unset "PLUG_EVAL_CMDS[$name]"
                _plug_err "Could not run: $cmd  (see: plug logs)"
                return 1
            fi

            (( found )) || PLUG_EVAL_NAMES+=( "$name" )
            _plug_save_evals
            _plug_build_cache
            _plug_ok "$PLUG_ICON_EVAL  Cached $(_plug_c "1;$PLUG_C_TEXT" "$name")  $(_plug_dim "$cmd")"
            _plug_info "Restart your shell to load it:  $(_plug_c "1;$PLUG_C_TEXT" 'exec zsh')"
            ;;

        remove|rm)
            (( $# )) || { _plug_err "Usage: plug eval remove <name> ..."; return 1 }
            for name in "$@"; do
                if (( ! ${PLUG_EVAL_NAMES[(Ie)$name]} )); then
                    _plug_err "$name is not an eval"
                    rc=1
                    continue
                fi
                PLUG_EVAL_NAMES=( "${PLUG_EVAL_NAMES[@]:#${(b)name}}" )
                unset "PLUG_EVAL_CMDS[$name]"
                command rm -f "$PLUG_EVAL_DIR/$name.zsh"
                _plug_ok "Removed eval $name"
            done
            _plug_save_evals
            _plug_build_cache
            return $rc
            ;;

        refresh|update)
            local -a names=( "$@" )
            (( $#names )) || names=( "${PLUG_EVAL_NAMES[@]}" )
            if (( ! $#names )); then
                _plug_info "No evals registered"
                return 0
            fi
            for name in "${names[@]}"; do
                if [[ -z ${PLUG_EVAL_CMDS[$name]} ]]; then
                    _plug_err "$name is not an eval"
                    rc=1
                elif _plug_eval_generate "$name"; then
                    _plug_ok "$PLUG_ICON_EVAL  Refreshed $name"
                else
                    _plug_err "$name  failed  (see: plug logs)"
                    rc=1
                fi
            done
            return $rc
            ;;

        list|ls)
            if (( ! $#PLUG_EVAL_NAMES )); then
                _plug_info "No evals yet. Try:  plug eval add zoxide zoxide init zsh"
                return 0
            fi
            print
            for n in "${PLUG_EVAL_NAMES[@]}"; do
                if [[ -r $PLUG_EVAL_DIR/$n.zsh ]]; then
                    print -r -- "  $(_plug_c "$PLUG_C_OK" "$PLUG_ICON_EVAL")  ${(r:16:)n} $(_plug_dim "${PLUG_EVAL_CMDS[$n]}")"
                else
                    print -r -- "  $(_plug_c "$PLUG_C_ERR" "$PLUG_ICON_FAIL")  ${(r:16:)n} $(_plug_dim "output missing: plug eval refresh $n")"
                fi
            done
            print
            ;;

        *)
            _plug_err "Usage: plug eval {add <name> <command...> | remove <name> | refresh [name] | list}"
            return 1
            ;;
    esac
}


# =============================================================================
# plug completion   (your own completions)
# =============================================================================

plug_completion() {
    emulate -L zsh
    local sub=${1:-list}
    (( $# )) && shift

    local f name out
    local -i rc=0 changed=0

    _plug_init_dirs

    case $sub in
        add)
            if (( ! $# )); then
                _plug_err "Usage: plug completion add <file> ...   (directories: plug add <dir>)"
                return 1
            fi
            for f in "$@"; do
                f=${f/#\~/$HOME}
                if [[ ! -f $f ]]; then
                    _plug_err "Not a file: $f"
                    rc=1
                    continue
                fi
                name=${f:t}
                [[ $name == _* ]] || name="_$name"
                command cp -f "$f" "$PLUG_COMP_DIR/$name"
                _plug_ok "$PLUG_ICON_COMP  Installed completion $(_plug_c "1;$PLUG_C_TEXT" "$name")"
                changed=1
            done
            ;;

        gen)
            if (( $# < 2 )); then
                _plug_err "Usage: plug completion gen <name> <command...>"
                _plug_info "Example: plug completion gen kubectl kubectl completion zsh"
                return 1
            fi
            name=$1; shift
            [[ $name == _* ]] || name="_$name"

            out=$("$@" </dev/null 2>>"$PLUG_LOG_FILE") || {
                _plug_err "Command failed: $*  (see: plug logs)"
                return 1
            }
            if [[ -z $out ]]; then
                _plug_err "The command produced no output"
                return 1
            fi

            print -r -- "$out" > "$PLUG_COMP_DIR/$name"
            _plug_ok "$PLUG_ICON_COMP  Generated $(_plug_c "1;$PLUG_C_TEXT" "$name")"
            [[ $out == '#compdef'* ]] ||
                _plug_warn "No #compdef header; if it does not work, try:  plug eval add ${name#_} $*"
            changed=1
            ;;

        remove|rm)
            (( $# )) || { _plug_err "Usage: plug completion remove <name> ..."; return 1 }
            for name in "$@"; do
                [[ $name == _* ]] || name="_$name"
                if [[ -f $PLUG_COMP_DIR/$name && $name != _plug ]]; then
                    command rm -f "$PLUG_COMP_DIR/$name"
                    _plug_ok "Removed completion $name"
                    changed=1
                else
                    _plug_err "No such completion: $name"
                    rc=1
                fi
            done
            ;;

        list|ls)
            local -a files=( $PLUG_COMP_DIR/_*(N) )
            files=( ${files:#$PLUG_COMP_DIR/_plug} )
            if (( ! $#files )); then
                _plug_info "No custom completions yet. Try:  plug completion add ./_mytool"
                return 0
            fi
            print
            for f in "${files[@]}"; do
                print -r -- "  $(_plug_c "$PLUG_C_OK" "$PLUG_ICON_COMP")  ${f:t}"
            done
            print
            ;;

        *)
            _plug_err "Usage: plug completion {add <file> | gen <name> <command...> | remove <name> | list}"
            return 1
            ;;
    esac

    if (( changed )); then
        _plug_build_cache
        _plug_info "Restart your shell to use it:  $(_plug_c "1;$PLUG_C_TEXT" 'exec zsh')"
    fi
    return $rc
}
