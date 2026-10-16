# =============================================================================
#  lib/40-plugins.zsh — install, add, remove, enable/disable, lazy, defer, browse
# =============================================================================


# =============================================================================
# plug install
# =============================================================================

plug_install() {
    emulate -L zsh

    if (( ! $# )); then
        _plug_err "Usage: plug install <user/repo[@branch] | omz:name> ..."
        _plug_info "Examples:  plug install zsh-users/zsh-autosuggestions"
        _plug_info "           plug install user/repo@dev        (pin to a branch)"
        _plug_info "           plug install omz git docker"
        return 1
    fi

    _plug_need git || return 1
    _plug_init_dirs
    _plug_load_all

    local arg p dir spec branch
    local -i rc=0 changed=0 branch_changed=0

    for arg in "$@"; do
        spec=$arg
        branch=
        if [[ $spec != local:* && $spec == *@* ]]; then
            branch=${spec##*@}
            spec=${spec%@*}
        fi

        _plug_norm "$spec"; p=$REPLY

        if [[ $p == local:* ]]; then
            _plug_err "$arg is a local path. Use:  plug add $spec"
            rc=1
            continue
        fi

        if ! _plug_valid "$p"; then
            _plug_err "Invalid plugin name: $arg   (expected user/repo[@branch] or omz:name)"
            rc=1
            continue
        fi

        if [[ -n $branch ]]; then
            if [[ $p == omz:* ]]; then
                _plug_warn "Cannot pin an Oh My Zsh plugin to a branch; ignoring @$branch"
            elif [[ $branch != [A-Za-z0-9]* || $branch == *[^A-Za-z0-9._/-]* ]]; then
                _plug_err "Invalid branch name: $branch"
                rc=1
                continue
            fi
        fi

        if [[ $p == omz:* ]]; then
            _plug_omz_ensure || { rc=1; continue }
            _plug_dir "$p"; dir=$REPLY
            if [[ ! -d $dir ]]; then
                _plug_err "Oh My Zsh has no plugin named '${p#omz:}'"
                rc=1
                continue
            fi
        else
            _plug_dir "$p"; dir=$REPLY
            # Re-clone when the pinned branch changes.
            if [[ -n $branch && -d $dir/.git && ${PLUG_BRANCH[$p]} != $branch ]]; then
                command rm -rf -- "$dir"
            fi
            _plug_clone "$p" || { rc=1; continue; }
        fi

        if [[ -n $branch && ${PLUG_BRANCH[$p]} != $branch ]]; then
            PLUG_BRANCH[$p]=$branch
            branch_changed=1
        fi

        if _plug_installed "$p"; then
            if (( branch_changed )); then
                _plug_ok "Pinned $(_plug_c "1;$PLUG_C_TEXT" "$p") to $(_plug_c "1;$PLUG_C_INFO" "$branch")"
                changed=1
            else
                _plug_info "$p is already installed"
            fi
        else
            PLUG_PLUGINS+=( "$p" )
            changed=1
            _plug_ok "Installed $(_plug_c "1;$PLUG_C_TEXT" "$p")${branch:+ $(_plug_dim "($branch)")}"
        fi
    done

    (( branch_changed )) && _plug_save_branches

    if (( changed )); then
        _plug_save_registry
        _plug_build_cache
        _plug_info "Restart your shell to load new plugins:  $(_plug_c "1;$PLUG_C_TEXT" 'exec zsh')"
    fi

    return $rc
}


# =============================================================================
# plug add   (your own zsh files and directories)
# =============================================================================

plug_add() {
    emulate -L zsh

    if (( ! $# )); then
        _plug_err "Usage: plug add <file.zsh | directory> ..."
        _plug_info "A file is sourced. A directory is added to fpath (completions)"
        _plug_info "and every *.zsh inside it is sourced (or its init.zsh / *.plugin.zsh)."
        return 1
    fi

    _plug_load_registry

    local a target p
    local -i rc=0 changed=0

    for a in "$@"; do
        target=${a/#\~/$HOME}
        target=${target:A}

        if [[ ! -e $target ]]; then
            _plug_err "No such file or directory: $a"
            rc=1
            continue
        fi

        if [[ -f $target && ${target:t} != _* ]] &&
           ! command zsh -n "$target" >/dev/null 2>&1; then
            _plug_err "Syntax error in $a (run: zsh -n $a)"
            rc=1
            continue
        fi

        p="local:$target"
        _plug_display "$p"

        if _plug_installed "$p"; then
            _plug_info "$REPLY is already added"
            continue
        fi

        PLUG_PLUGINS+=( "$p" )
        changed=1

        if [[ -d $target ]]; then
            _plug_ok "$PLUG_ICON_FOLDER  Added directory $(_plug_c "1;$PLUG_C_TEXT" "$REPLY")"
        elif [[ ${target:t} == _* ]]; then
            _plug_ok "$PLUG_ICON_COMP  Added completion $(_plug_c "1;$PLUG_C_TEXT" "$REPLY")"
        else
            _plug_ok "$PLUG_ICON_FILE  Added file $(_plug_c "1;$PLUG_C_TEXT" "$REPLY")"
        fi
    done

    if (( changed )); then
        _plug_save_registry
        _plug_build_cache
        _plug_info "Restart your shell to load it:  $(_plug_c "1;$PLUG_C_TEXT" 'exec zsh')"
    fi

    return $rc
}


# =============================================================================
# plug remove
# =============================================================================

plug_remove() {
    emulate -L zsh

    local -i yes=0 rc=0
    local -a names=()
    local a p dir

    for a in "$@"; do
        case $a in
            -y|--yes) yes=1 ;;
            *)        names+=( "$a" ) ;;
        esac
    done

    if (( ! $#names )); then
        _plug_err "Usage: plug remove [-y] <user/repo | omz:name | path> ..."
        return 1
    fi

    _plug_load_all
    _plug_load_lock

    local -a victims=()
    for a in "${names[@]}"; do
        _plug_norm "$a"; p=$REPLY
        if _plug_installed "$p"; then
            victims+=( "$p" )
        else
            _plug_err "$a is not installed"
            rc=1
        fi
    done

    (( $#victims )) || return 1

    if (( ! yes )) && ! _plug_confirm "Remove ${(j:, :)victims}?"; then
        _plug_info "Cancelled"
        return $rc
    fi

    for p in "${victims[@]}"; do
        # Only git clones are deleted. OMZ plugins live in the shared checkout
        # and your own files are never touched: they are just unregistered.
        _plug_kind "$p"
        if [[ $REPLY == git ]]; then
            _plug_dir "$p"; dir=$REPLY
            command rm -rf -- "$dir"
        fi
        _plug_forget "$p"
        _plug_display "$p"
        _plug_ok "Removed $REPLY"
    done

    _plug_save_registry
    _plug_save_disabled
    _plug_save_lazy
    _plug_save_defer
    _plug_save_branches
    _plug_save_lock
    _plug_build_cache
    return $rc
}


# =============================================================================
# plug enable / disable
# =============================================================================

_plug_toggle() {
    emulate -L zsh
    local mode=$1; shift
    local a p
    local -i rc=0 changed=0

    if (( ! $# )); then
        _plug_err "Usage: plug $mode <plugin> ..."
        return 1
    fi

    _plug_load_all

    for a in "$@"; do
        _plug_norm "$a"; p=$REPLY
        if ! _plug_installed "$p"; then
            _plug_err "$a is not installed"
            rc=1
            continue
        fi

        _plug_display "$p"
        if [[ $mode == enable ]]; then
            if [[ -z ${PLUG_DISABLED[$p]} ]]; then
                _plug_info "$REPLY is already enabled"
                continue
            fi
            unset "PLUG_DISABLED[$p]"
            _plug_ok "Enabled $REPLY"
        else
            if [[ -n ${PLUG_DISABLED[$p]} ]]; then
                _plug_info "$REPLY is already disabled"
                continue
            fi
            PLUG_DISABLED[$p]=1
            _plug_ok "Disabled $REPLY"
        fi
        changed=1
    done

    if (( changed )); then
        _plug_save_disabled
        _plug_build_cache
        _plug_info "Restart your shell to apply:  $(_plug_c "1;$PLUG_C_TEXT" 'exec zsh')"
    fi
    return $rc
}

plug_enable()  { _plug_toggle enable  "$@" }
plug_disable() { _plug_toggle disable "$@" }


# =============================================================================
# plug lazy / unlazy
# =============================================================================

plug_lazy() {
    emulate -L zsh

    if (( $# < 2 )); then
        _plug_err "Usage: plug lazy <user/repo | omz:name> <command> [command...]"
        _plug_info "A trigger command is required, for example:  plug lazy Aloxaf/fzf-tab fzf"
        return 1
    fi

    local p c re='^[A-Za-z0-9_.+-]+$'
    _plug_norm "$1"; p=$REPLY
    shift

    _plug_load_all

    if ! _plug_installed "$p"; then
        _plug_err "$p is not installed"
        return 1
    fi

    if [[ $p == local:* ]]; then
        _plug_err "Lazy loading is for git and Oh My Zsh plugins"
        return 1
    fi

    if [[ -n ${PLUG_DEFER[$p]} ]]; then
        _plug_err "$p is deferred; run  plug undefer $p  first"
        return 1
    fi

    for c in "$@"; do
        if ! [[ $c =~ $re ]]; then
            _plug_err "Invalid command name: $c"
            return 1
        fi
    done

    PLUG_LAZY[$p]="$*"
    _plug_save_lazy
    _plug_build_cache

    _plug_ok "$PLUG_ICON_LAZY  $p will load on first use of: $(_plug_c "1;$PLUG_C_TEXT" "$*")"
    _plug_info "Restart your shell to apply:  $(_plug_c "1;$PLUG_C_TEXT" 'exec zsh')"
}

plug_unlazy() {
    emulate -L zsh
    local a p
    local -i rc=0 changed=0

    if (( ! $# )); then
        _plug_err "Usage: plug unlazy <plugin> ..."
        return 1
    fi

    _plug_load_all

    for a in "$@"; do
        _plug_norm "$a"; p=$REPLY
        if [[ -z ${PLUG_LAZY[$p]} ]]; then
            _plug_err "$p is not lazy"
            rc=1
            continue
        fi
        unset "PLUG_LAZY[$p]"
        _plug_ok "$p now loads at startup"
        changed=1
    done

    if (( changed )); then
        _plug_save_lazy
        _plug_build_cache
        _plug_info "Restart your shell to apply:  $(_plug_c "1;$PLUG_C_TEXT" 'exec zsh')"
    fi
    return $rc
}


# =============================================================================
# plug defer / undefer   (turbo loading, like zinit's wait"")
# =============================================================================

plug_defer() {
    emulate -L zsh

    if (( ! $# )); then
        _plug_err "Usage: plug defer <user/repo | omz:name> [milliseconds]"
        _plug_info "The plugin loads shortly after your first prompt. Default: 1000 ms"
        _plug_info "Example:  plug defer zsh-users/zsh-autosuggestions 500"
        return 1
    fi

    local a p ms=${2:-1000}
    _plug_norm "$1"; p=$REPLY

    if [[ $ms != <-> ]]; then
        _plug_err "Delay must be a whole number of milliseconds, got: $ms"
        return 1
    fi

    _plug_load_all

    if ! _plug_installed "$p"; then
        _plug_err "$p is not installed"
        return 1
    fi
    if [[ $p == local:* ]]; then
        _plug_err "Deferred loading is for git and Oh My Zsh plugins"
        return 1
    fi
    if [[ -n ${PLUG_LAZY[$p]} ]]; then
        _plug_err "$p is lazy; run  plug unlazy $p  first"
        return 1
    fi

    PLUG_DEFER[$p]=$ms
    _plug_save_defer
    _plug_build_cache

    _plug_ok "$PLUG_ICON_DEFER  $p will load ~${ms}ms after your first prompt"
    _plug_info "Restart your shell to apply:  $(_plug_c "1;$PLUG_C_TEXT" 'exec zsh')"
}

plug_undefer() {
    emulate -L zsh
    local a p
    local -i rc=0 changed=0

    if (( ! $# )); then
        _plug_err "Usage: plug undefer <plugin> ..."
        return 1
    fi

    _plug_load_all

    for a in "$@"; do
        _plug_norm "$a"; p=$REPLY
        if [[ -z ${PLUG_DEFER[$p]} ]]; then
            _plug_err "$p is not deferred"
            rc=1
            continue
        fi
        unset "PLUG_DEFER[$p]"
        _plug_ok "$p now loads at startup"
        changed=1
    done

    if (( changed )); then
        _plug_save_defer
        _plug_build_cache
        _plug_info "Restart your shell to apply:  $(_plug_c "1;$PLUG_C_TEXT" 'exec zsh')"
    fi
    return $rc
}


# =============================================================================
# plug source   (load a plugin into the CURRENT shell, no restart)
# =============================================================================

plug_source() {
    emulate -L zsh
    (( $# )) || { _plug_err "Usage: plug source <plugin> ..."; return 1 }

    _plug_load_all
    local a p dir src f
    local -i rc=0 n=0

    for a in "$@"; do
        _plug_norm "$a"; p=$REPLY
        if ! _plug_installed "$p"; then
            _plug_err "$a is not installed"
            rc=1
            continue
        fi

        _plug_dir "$p"; dir=$REPLY
        if [[ $p == local:* ]]; then
            if [[ -d $dir ]]; then
                _plug_find_source "$dir" "${dir:t}"; src=$REPLY
                if [[ -n $src ]]; then
                    source "$src"
                else
                    for f in $dir/*.zsh(N-.); do
                        [[ ${f:t} == _* ]] || source "$f"
                    done
                fi
            elif [[ -f $dir ]]; then
                source "$dir"
            else
                _plug_err "$a no longer exists"
                rc=1
                continue
            fi
            _plug_display "$p"
            _plug_ok "Sourced $REPLY"
            (( ++n ))
            continue
        fi

        unset "PLUG_LOADED[$p]"
        if _plug_load_one "$p"; then
            _plug_display "$p"
            _plug_ok "Sourced $REPLY in the current shell"
            (( ++n ))
        else
            rc=1
        fi
    done

    if (( n && PLUG_COMPINIT )); then
        _plug_info "New completions appear after a restart:  $(_plug_c "1;$PLUG_C_TEXT" 'exec zsh')"
    fi
    return $rc
}


# =============================================================================
# plug browse / omz browse   (gum)
# =============================================================================

# Browse a list with gum and install every selected entry.
_plug_browse_install() {
    local title=$1 prefix=$2; shift 2
    local selected item plugin
    selected=$(print -rl -- "$@" | command gum filter --no-limit \
        --header "$title" --placeholder "type to search") || return 0
    [[ -n $selected ]] || return 0

    while IFS= read -r item; do
        plugin=${item%%|*}
        [[ -n $prefix ]] && plugin="$prefix$plugin"
        [[ -n $plugin ]] && plug_install "$plugin"
    done <<< "$selected"
}

plug_browse() {
    emulate -L zsh
    _plug_browse_install "$PLUG_ICON_PLUGIN  Browse popular GitHub plugins" \
        "" \
        "${PLUG_BROWSE_ITEMS[@]}"
}

plug_omz_browse() {
    emulate -L zsh
    _plug_omz_ensure || return 1

    local dir
    local -a items=()
    for dir in "$PLUG_OMZ_DIR/plugins"/*(N/); do
        items+=( "${dir:t}|Oh My Zsh plugin" )
    done

    if (( ! $#items )); then
        _plug_err "No Oh My Zsh plugins found in $PLUG_OMZ_DIR"
        return 1
    fi

    _plug_browse_install "$PLUG_ICON_PLUGIN  Browse Oh My Zsh plugins" \
        "omz:" \
        "${items[@]}"
}
