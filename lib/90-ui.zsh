# =============================================================================
#  lib/90-ui.zsh — the `plug` command: dispatcher, menu, help, version
# =============================================================================


# _plug_omz_expand <arg>...
#   Bare `omz` switches the rest of the bare names into `omz:name` form, e.g.
#       plug install user/repo omz git docker  ->  user/repo omz:git omz:docker
#   A trailing `omz` with nothing after it is kept as the keyword "all OMZ
#   plugins" (used by `plug update omz`).
_plug_omz_expand() {
    emulate -L zsh
    local -a out=()
    local a
    local -i mode=0 omz_seen=0 omz_used=0

    for a in "$@"; do
        if [[ $a == omz ]]; then
            (( omz_seen && ! omz_used )) && out+=( omz )
            mode=1; omz_seen=1; omz_used=0
            continue
        fi
        if [[ $a == -?* ]]; then
            out+=( "$a" )
            continue
        fi
        if (( mode )) && [[ $a != */* && $a != *:* && $a != /* && $a != '~'* && $a != .* ]]; then
            out+=( "omz:$a" ); omz_used=1
        else
            out+=( "$a" )
        fi
    done
    (( omz_seen && ! omz_used )) && out+=( omz )
    reply=( "${out[@]}" )
}


# =============================================================================
# The `plug` command
# =============================================================================

plug() {
    emulate -L zsh
    _plug_color_init
    _plug_force=0

    local cmd=${1:-menu}
    (( $# )) && shift

    _plug_omz_expand "$@"
    set -- "${reply[@]}"

    case $cmd in
        --version|-v|version)
            print -r -- "plug $PLUG_VERSION"
            ;;

        install|i)        _plug_need gum && plug_install "$@" ;;
        browse)           _plug_need gum && plug_browse ;;
        omz)
            _plug_need gum
            if (( $# )); then
                plug_install "omz:${^@}"
            else
                plug_omz_browse
            fi
            ;;

        add|a)            _plug_need gum && plug_add "$@" ;;
        remove|rm|uninstall)
                          _plug_need gum && plug_remove "$@" ;;
        enable|en)        _plug_need gum && plug_enable "$@" ;;
        disable|dis)      _plug_need gum && plug_disable "$@" ;;
        lazy)             _plug_need gum && plug_lazy "$@" ;;
        unlazy)           _plug_need gum && plug_unlazy "$@" ;;
        defer)            _plug_need gum && plug_defer "$@" ;;
        undefer)          _plug_need gum && plug_undefer "$@" ;;
        source)           _plug_need gum && plug_source "$@" ;;

        update|up|upgrade)
                          _plug_need gum && plug_update "$@" ;;
        outdated)         _plug_need gum && _plug_force=1 && plug_outdated ;;
        lock)             _plug_need gum && plug_lock ;;
        sync)             _plug_need gum && plug_sync ;;
        reinstall)        _plug_need gum && plug_reinstall "$@" ;;
        selfupdate|self-update)
                          _plug_need gum && plug_selfupdate ;;
        clean)            _plug_need gum && plug_clean "$@" ;;

        eval|ev)          _plug_need gum && plug_eval "$@" ;;
        completion|comp)  _plug_need gum && plug_completion "$@" ;;

        status|st)        _plug_need gum && _plug_force=1 && plug_status ;;
        info|about)       _plug_force=1; plug_info ;;
        list|ls)          plug_list ;;
        doctor|dr)        _plug_need gum && _plug_force=1 && plug_doctor ;;
        profile)          _plug_force=1; plug_profile ;;

        edit)             _plug_need gum && plug_edit "$@" ;;
        logs|log)         _plug_need gum && _plug_force=1 && plug_logs "$@" ;;
        cache)            _plug_need gum && _plug_force=1 && plug_cache "$@" ;;

        menu|m)           _plug_menu ;;
        reload|restart|exec)
                          _plug_c "1;$PLUG_C_ACCENT" "$PLUG_ICON_SYNC  Restarting the shell"
                          print; exec zsh ;;
        help|h|-h|--help) _plug_help ;;

        *)
            _plug_err "Unknown command: $cmd"
            _plug_info "Run  $(_plug_c "1;$PLUG_C_TEXT" 'plug help')  to see everything"
            return 1
            ;;
    esac
}


# =============================================================================
# Interactive menu
# =============================================================================

_plug_menu() {
    emulate -L zsh

    if ! _plug_tty; then
        _plug_help
        return 0
    fi

    _plug_need gum || return 1

    local choice
    while true; do
        print
        _plug_banner "interactive menu"

        choice=$(command gum choose \
            --header "Choose an action" --cursor.foreground 141 \
            "$PLUG_ICON_PLUGIN  Install a plugin" \
            "$PLUG_ICON_CLOUD  Browse popular plugins" \
            "$PLUG_ICON_PLUGIN  Browse Oh My Zsh plugins" \
            "$PLUG_ICON_FOLDER  Add your own file or directory" \
            "$PLUG_ICON_REMOVE  Remove a plugin" \
            "$PLUG_ICON_UPDATE  Update all plugins" \
            "$PLUG_ICON_CLOUD  Check for updates" \
            "$PLUG_ICON_HEALTH  Doctor (health check)" \
            "$PLUG_ICON_PROFILE  Profile startup" \
            "$PLUG_ICON_FILE  Show status" \
            "$PLUG_ICON_INFO  Help / commands" \
            "Quit") </dev/tty || return 0

        case $choice in
            *Install\ a\ plugin)     _plug_menu_install ;;
            *Browse\ popular*)       plug_browse ;;
            *Oh\ My\ Zsh)            plug_omz_browse ;;
            *Add\ your\ own*)        _plug_menu_add ;;
            *Remove\ a\ plugin)      _plug_menu_remove ;;
            *Update\ all*)           plug_update ;;
            *Check\ for\ updates*)   plug_outdated ;;
            *Doctor*)                plug_doctor ;;
            *Profile*)               plug_profile; break ;;
            *Show\ status*)          plug_status; break ;;
            *Help*)                  _plug_help; break ;;
            Quit|"")                 return 0 ;;
        esac
    done
}

_plug_menu_install() {
    local name
    name=$(command gum input --placeholder "user/repo  or  user/repo@branch" \
        --header "Install a plugin" </dev/tty) || return 0
    [[ -n $name ]] && plug_install "$name"
    _plug_menu_confirm_restart
}

_plug_menu_add() {
    local path
    path=$(command gum input --placeholder "~/path/to/file.zsh" \
        --header "Add your own file or directory" </dev/tty) || return 0
    [[ -n $path ]] && plug_add "$path"
    _plug_menu_confirm_restart
}

_plug_menu_remove() {
    _plug_load_registry
    (( $#PLUG_PLUGINS )) || { _plug_info "Nothing to remove"; return 0; }

    local -a picked
    picked=( ${(f)"$(command gum choose --no-limit --header 'Remove plugins' "${PLUG_PLUGINS[@]}" </dev/tty)"} )
    (( $#picked )) || return 0
    plug_remove -y "${picked[@]}"
}

_plug_menu_confirm_restart() {
    if command gum confirm "Restart the shell now to apply?" </dev/tty; then
        _plug_c "1;$PLUG_C_ACCENT" "$PLUG_ICON_SYNC  Restarting the shell"
        print; exec zsh
    fi
}


# =============================================================================
# Help
# =============================================================================

# _plug_hl <command> <description>   (aligns on the plain text, then colours)
_plug_hl() {
    local cmd=$1 desc=$2 n=$(( 30 - ${#1} ))
    (( n < 2 )) && n=2
    print -r -- "    $(_plug_c "$PLUG_C_TEXT" "$cmd")${(l:$n:: :)} $(_plug_dim "$desc")"
}

_plug_help() {
    emulate -L zsh
    _plug_banner

    print -r -- "  $(_plug_c "1;$PLUG_C_ACCENT" 'SETUP')"
    _plug_hl 'source plug.zsh'  '~/.zshrc, before your own compinit'
    print

    print -r -- "  $(_plug_c "1;$PLUG_C_ACCENT" 'PLUGINS')"
    _plug_hl 'plug install'  'user/repo  user/repo@branch  omz:name  [omz name...]'
    _plug_hl 'plug browse'   'pick from popular GitHub plugins'
    _plug_hl 'plug omz'      'pick from installed Oh My Zsh plugins'
    _plug_hl 'plug add'      'add your own .zsh file or directory'
    _plug_hl 'plug remove'   'remove a plugin  [-y]'
    _plug_hl 'plug source'   'load a plugin into this shell now'
    print

    print -r -- "  $(_plug_c "1;$PLUG_C_ACCENT" 'LOADING')"
    _plug_hl 'plug enable'   'turn a plugin on'
    _plug_hl 'plug disable'  'turn a plugin off'
    _plug_hl 'plug lazy'     'repo cmd...  load on first use of cmd'
    _plug_hl 'plug unlazy'   'load at startup again'
    _plug_hl 'plug defer'    'repo [ms]  turbo: load after first prompt'
    _plug_hl 'plug undefer'  'load at startup again'
    print

    print -r -- "  $(_plug_c "1;$PLUG_C_ACCENT" 'VERSIONS')"
    _plug_hl 'plug update'    'update all, in parallel'
    _plug_hl 'plug outdated'  'check the remote without changing anything'
    _plug_hl 'plug lock'      'record exact commits'
    _plug_hl 'plug sync'      'restore recorded commits'
    _plug_hl 'plug reinstall' 'delete and re-clone everything  [-y]'
    _plug_hl 'plug selfupdate' 'update plug.zsh itself'
    print

    print -r -- "  $(_plug_c "1;$PLUG_C_ACCENT" 'EXTRA')"
    _plug_hl 'plug eval'        'add|remove|refresh|list  cache zoxide/starship/...'
    _plug_hl 'plug completion'  'add|gen|remove|list  manage completions'
    print

    print -r -- "  $(_plug_c "1;$PLUG_C_ACCENT" 'INSPECT')"
    _plug_hl 'plug status'   'dashboard'
    _plug_hl 'plug list'     'names and states  (script friendly)'
    _plug_hl 'plug doctor'   'deep health check'
    _plug_hl 'plug profile'  'measure startup cost'
    _plug_hl 'plug info'     'paths and settings'
    _plug_hl 'plug logs'     '[clear]'
    _plug_hl 'plug cache'    'rebuild|clear|show'
    _plug_hl 'plug edit'     'plugins|lazy|disabled|deferred|branches|evals'
    _plug_hl 'plug menu'     'interactive menu'
    _plug_hl 'plug reload'   'restart the shell'
    print

    print -r -- "  $(_plug_dim "OMZ shorthand:  plug install user/repo omz git docker  =  user/repo omz:git omz:docker")"
    print
}
