# =============================================================================
#  lib/60-inspect.zsh — list, status, info, profile, logs, cache, edit, doctor
# =============================================================================


# _plug_state <name>  ->  REPLY  (disabled | lazy | deferred | missing | enabled)
_plug_state() {
    local dir
    _plug_dir "$1"; dir=$REPLY
    if [[ -n ${PLUG_DISABLED[$1]} ]]; then
        REPLY=disabled
    elif [[ $1 == local:* ]]; then
        if [[ -e $dir ]]; then REPLY=enabled; else REPLY=missing; fi
    elif [[ ! -d $dir ]]; then
        REPLY=missing
    elif [[ -n ${PLUG_LAZY[$1]} ]]; then
        REPLY=lazy
    elif [[ -n ${PLUG_DEFER[$1]} ]]; then
        REPLY=deferred
    else
        REPLY=enabled
    fi
}

# _plug_state_icon <state>  ->  REPLY (coloured icon)
_plug_state_icon() {
    case $1 in
        enabled)  REPLY=$(_plug_c "1;$PLUG_C_OK"   "$PLUG_ICON_OK") ;;
        disabled) REPLY=$(_plug_c "$PLUG_C_DIM"    "$PLUG_ICON_DISABLED") ;;
        lazy)     REPLY=$(_plug_c "1;$PLUG_C_INFO" "$PLUG_ICON_LAZY") ;;
        deferred) REPLY=$(_plug_c "1;$PLUG_C_INFO" "$PLUG_ICON_DEFER") ;;
        *)        REPLY=$(_plug_c "1;$PLUG_C_ERR"  "$PLUG_ICON_FAIL") ;;
    esac
}

# _plug_state_word <state>  ->  REPLY (coloured, padded to 9)
_plug_state_word() {
    local w=${(r:9:)1}
    case $1 in
        enabled)  REPLY=$(_plug_c "$PLUG_C_OK"   "$w") ;;
        disabled) REPLY=$(_plug_c "$PLUG_C_DIM"  "$w") ;;
        lazy)     REPLY=$(_plug_c "$PLUG_C_INFO" "$w") ;;
        deferred) REPLY=$(_plug_c "$PLUG_C_INFO" "$w") ;;
        *)        REPLY=$(_plug_c "$PLUG_C_ERR"  "$w") ;;
    esac
}

# Human-readable extra state for a plugin (branch pin, triggers, delay).
_plug_extra() {
    local p=$1 state=$2
    REPLY=
    if [[ $state == lazy ]]; then
        REPLY=" ${PLUG_LAZY[$p]}"
    elif [[ $state == deferred ]]; then
        REPLY=" ~${PLUG_DEFER[$p]}ms"
    fi
    [[ -n ${PLUG_BRANCH[$p]} ]] && REPLY="${REPLY} @${PLUG_BRANCH[$p]}"
}

plug_list() {
    emulate -L zsh
    _plug_load_all

    if (( ! $#PLUG_PLUGINS )); then
        _plug_info "No plugins installed"
        return 0
    fi

    local p state disp extra
    for p in "${PLUG_PLUGINS[@]}"; do
        _plug_state "$p"; state=$REPLY
        _plug_display "$p"; disp=$REPLY
        _plug_extra "$p" "$state"; extra=$REPLY

        if (( _plug_color )); then
            _plug_state_icon "$state"
            print -r -- "  $REPLY  $disp$extra"
        else
            print -r -- "$disp"$'\t'"$state$extra"
        fi
    done
}

plug_status() {
    emulate -L zsh
    _plug_need git || return 1
    _plug_load_all
    _plug_load_lock

    local p n state dir full short omz_full lk lockstate key kind disp icon word
    local -i w=12 drift=0 n_enabled=0 n_disabled=0 n_lazy=0 n_deferred=0 n_missing=0 n_local=0

    if (( ! $#PLUG_PLUGINS && ! $#PLUG_EVAL_NAMES )); then
        _plug_banner
        _plug_info "Nothing here yet. Try:  $(_plug_c "1;$PLUG_C_TEXT" 'plug install zsh-users/zsh-autosuggestions')"
        return 0
    fi

    for p in "${PLUG_PLUGINS[@]}"; do
        _plug_display "$p"
        (( ${#REPLY} > w )) && w=${#REPLY}
    done
    for n in "${PLUG_EVAL_NAMES[@]}"; do
        (( ${#n} > w )) && w=${#n}
    done
    (( w += 2 ))

    _plug_banner
    print -r -- "     $(_plug_dim "${(r:$w:)NAME} ${(r:6:)TYPE} ${(r:9:)STATE} ${(r:8:)COMMIT} LOCK")"
    _plug_rule $(( w + 36 ))

    for p in "${PLUG_PLUGINS[@]}"; do
        _plug_state "$p"; state=$REPLY
        _plug_kind "$p"; kind=$REPLY
        _plug_display "$p"; disp=$REPLY
        _plug_dir "$p"; dir=$REPLY
        _plug_lock_key "$p"; key=$REPLY

        _plug_state_icon "$state"; icon=$REPLY
        _plug_state_word "$state"; word=$REPLY

        case $state in
            enabled)  (( ++n_enabled )) ;;
            disabled) (( ++n_disabled )) ;;
            lazy)     (( ++n_lazy )) ;;
            deferred) (( ++n_deferred )) ;;
            *)        (( ++n_missing )) ;;
        esac

        if [[ $kind == local ]]; then
            (( ++n_local ))
            print -r -- "  $icon  ${(r:$w:)disp} $(_plug_dim "${(r:6:)kind}") $word $(_plug_dim "${(r:8:)-} n/a")"
            continue
        fi

        full=
        if [[ $state != missing ]]; then
            if [[ $kind == omz ]]; then
                [[ -n $omz_full ]] || { _plug_commit_of "$PLUG_OMZ_DIR"; omz_full=$REPLY }
                full=$omz_full
            else
                _plug_commit_of "$dir"; full=$REPLY
            fi
        fi

        lk=${PLUG_LOCK_COMMIT[$key]}
        if [[ -z $lk ]]; then
            lockstate=$(_plug_dim 'unlocked')
        elif [[ $lk == $full ]]; then
            lockstate=$(_plug_c "$PLUG_C_OK" 'locked')
        else
            lockstate=$(_plug_c "$PLUG_C_WARN" 'drifted')
            (( ++drift ))
        fi

        short=${full[1,7]}
        [[ -n $short ]] || short=-
        print -r -- "  $icon  ${(r:$w:)disp} $(_plug_dim "${(r:6:)kind}") $word $(_plug_dim "${(r:8:)short}") $lockstate"
    done

    for n in "${PLUG_EVAL_NAMES[@]}"; do
        if [[ -r $PLUG_EVAL_DIR/$n.zsh ]]; then
            state=enabled
        else
            state=missing
        fi
        _plug_state_icon "$state"; icon=$REPLY
        _plug_state_word "$state"; word=$REPLY
        print -r -- "  $icon  ${(r:$w:)n} $(_plug_dim "${(r:6:)eval}") $word $(_plug_dim "${(r:8:)-} cached")"
    done

    local cache_state lock_summary
    if _plug_cache_ok; then
        cache_state="fresh"
    else
        cache_state="stale (rebuilds on next shell)"
    fi

    if (( ! $#PLUG_LOCK_COMMIT )); then lock_summary="no lockfile"
    elif (( drift )); then lock_summary="$drift drifted"
    else lock_summary="in sync"; fi

    local -a comps=( $PLUG_COMP_DIR/_*(N) )
    comps=( ${comps:#$PLUG_COMP_DIR/_plug} )

    _plug_box 141 \
        "$PLUG_ICON_PLUGIN  ${#PLUG_PLUGINS} plugins    $(_plug_c "$PLUG_C_OK" "$n_enabled on")    $(_plug_dim "$n_disabled off")    $(_plug_c "$PLUG_C_INFO" "$n_lazy lazy")    $(_plug_c "$PLUG_C_INFO" "$n_deferred deferred")    $(_plug_c "$PLUG_C_ERR" "$n_missing missing")" \
        "$PLUG_ICON_FILE  $n_local local    $PLUG_ICON_EVAL  ${#PLUG_EVAL_NAMES} evals    $PLUG_ICON_COMP  ${#comps} completions" \
        "$PLUG_ICON_CACHE  cache $cache_state    $PLUG_ICON_LOCK  lock $lock_summary"

    (( drift )) && _plug_info "$(_plug_c "1;$PLUG_C_TEXT" 'plug lock') accepts current versions,  $(_plug_c "1;$PLUG_C_TEXT" 'plug sync') restores locked ones"
    (( n_missing )) && _plug_info "Restore missing plugins with  $(_plug_c "1;$PLUG_C_TEXT" 'plug sync')  or  $(_plug_c "1;$PLUG_C_TEXT" 'plug reinstall')"
    return 0
}

_plug_kv() { print -r -- "  $(_plug_c "$PLUG_C_ACCENT" "$1")  $(_plug_dim "${(r:10:)2}") $3" }

plug_info() {
    emulate -L zsh
    _plug_load_all
    _plug_banner
    _plug_kv "$PLUG_ICON_FOLDER" "data"     "$PLUG_DIR"
    _plug_kv "$PLUG_ICON_CACHE"  "cache"    "$PLUG_CACHE_FILE"
    _plug_kv "$PLUG_ICON_LOCK"   "lock"     "$PLUG_LOCK_FILE"
    _plug_kv "$PLUG_ICON_LOG"    "log"      "$PLUG_LOG_FILE"
    _plug_kv "$PLUG_ICON_COMP"   "comps"    "$PLUG_COMP_DIR"
    _plug_kv "$PLUG_ICON_EVAL"   "evals"    "$PLUG_EVAL_DIR"
    _plug_kv "$PLUG_ICON_BRANCH" "branches" "$PLUG_BRANCH_FILE"
    _plug_kv "$PLUG_ICON_LAZY"   "lazy"     "$PLUG_LAZY_FILE"
    _plug_kv "$PLUG_ICON_DEFER"  "deferred" "$PLUG_DEFER_FILE"
    _plug_kv "$PLUG_ICON_PLUGIN" "omz"      "$PLUG_OMZ_DIR"
    _plug_kv "$PLUG_ICON_UPDATE" "jobs"     "$PLUG_JOBS"
    _plug_kv "$PLUG_ICON_PLUGIN" "plugins"  "${#PLUG_PLUGINS}"
    print
}


# =============================================================================
# plug profile / logs / cache / edit
# =============================================================================

# Profiles a real shell startup, so numbers match what you actually pay.
plug_profile() {
    emulate -L zsh
    print
    _plug_info "$PLUG_ICON_PROFILE  Starting a fresh shell to measure startup"
    PLUG_PROFILE=1 command zsh -i -c "source ${(q)PLUG_SELF}; _plug_prof_report"
}

plug_logs() {
    emulate -L zsh

    if [[ $1 == clear ]]; then
        : > "$PLUG_LOG_FILE"
        command rm -f "$PLUG_LOG_FILE.old"
        _plug_ok "Log cleared"
        return 0
    fi

    if [[ ! -s $PLUG_LOG_FILE ]]; then
        _plug_info "The log is empty"
        return 0
    fi

    if [[ -t 0 && -t 1 ]]; then
        command gum pager < "$PLUG_LOG_FILE"
    else
        command tail -n 100 "$PLUG_LOG_FILE"
    fi
}

plug_cache() {
    emulate -L zsh
    case ${1:-} in
        rebuild|build)
            _plug_build_cache && _plug_ok "$PLUG_ICON_CACHE  Startup cache rebuilt"
            ;;
        clear)
            command rm -f "$PLUG_CACHE_FILE"
            _plug_ok "Startup cache removed (rebuilt on next shell)"
            ;;
        show)
            [[ -r $PLUG_CACHE_FILE ]] && command cat "$PLUG_CACHE_FILE"
            ;;
        *)
            _plug_err "Usage: plug cache {rebuild|clear|show}"
            return 1
            ;;
    esac
}

plug_edit() {
    emulate -L zsh
    local file

    case ${1:-plugins} in
        plugins)  file=$PLUG_PLUGIN_FILE ;;
        lazy)     file=$PLUG_LAZY_FILE ;;
        disabled) file=$PLUG_DISABLED_FILE ;;
        deferred) file=$PLUG_DEFER_FILE ;;
        branches) file=$PLUG_BRANCH_FILE ;;
        evals)    file=$PLUG_EVAL_FILE ;;
        *)
            _plug_err "Usage: plug edit [plugins|lazy|disabled|deferred|branches|evals]"
            return 1
            ;;
    esac

    _plug_init_dirs
    [[ -e $file ]] || : > "$file"
    command ${=${EDITOR:-vi}} "$file"
    _plug_build_cache
    _plug_ok "$PLUG_ICON_EDIT  Saved, cache rebuilt"
}


# =============================================================================
# plug doctor
# =============================================================================

_plug_d_ok()   { _plug_ok "$@" }
_plug_d_bad()  { (( ++_plug_d_err ));  _plug_say "$PLUG_C_ERR"  "$PLUG_ICON_FAIL" "$@" }
_plug_d_warn() { (( ++_plug_d_warn )); _plug_say "$PLUG_C_WARN" "$PLUG_ICON_WARN" "$@" }
_plug_d_note() { _plug_say "$PLUG_C_DIM"  "$PLUG_ICON_INFO" "$@" }

plug_doctor() {
    emulate -L zsh
    setopt extended_glob

    _plug_d_err=0
    _plug_d_warn=0

    _plug_load_all
    _plug_load_lock

    local p kind dir name src gv line f c commit lk key disp branch
    local -a raw w lf
    local -A seen triggers
    local -i has_omz=0 badfiles

    _plug_banner "deep health check"

    # ---- Runtime ------------------------------------------------------------
    _plug_section "$PLUG_ICON_HEALTH" "Runtime"

    if [[ -n $ZSH_VERSION ]]; then _plug_d_ok "zsh  $ZSH_VERSION"
    else _plug_d_bad "not running under zsh"; fi

    if (( $+commands[git] )); then
        gv=${${(s: :)$(command git --version)}[3]}
        _plug_d_ok "git  $gv"
    else
        _plug_d_bad "git not found"
    fi

    if (( $+commands[gum] )); then _plug_d_ok "gum  $(command gum --version 2>/dev/null | head -n 1)"
    else _plug_d_bad "gum not found (required by the plug command)"; fi

    local -a libs=( $PLUG_ROOT/lib/*.zsh(N) )
    if (( $#libs )); then _plug_d_ok "plug.zsh v$PLUG_VERSION  ($#libs modules)"
    else _plug_d_bad "lib/ modules not found next to plug.zsh"; fi

    # ---- Storage ------------------------------------------------------------
    _plug_section "$PLUG_ICON_FOLDER" "Storage"

    if [[ -d $PLUG_DIR && -w $PLUG_DIR ]]; then _plug_d_ok "data dir writable: ${PLUG_DIR/#$HOME/~}"
    else _plug_d_bad "data dir missing or not writable: $PLUG_DIR"; fi

    if [[ -d $PLUG_PLUGIN_DIR ]]; then _plug_d_ok "plugins dir present"
    else _plug_d_bad "plugins dir missing: $PLUG_PLUGIN_DIR"; fi

    # ---- Registry -----------------------------------------------------------
    _plug_section "$PLUG_ICON_PLUGIN" "Registry"

    _plug_read "$PLUG_PLUGIN_FILE"
    raw=( "${reply[@]}" )

    for p in "${raw[@]}"; do
        [[ $p == omz:* ]] && has_omz=1
        [[ -n ${seen[$p]} ]] && _plug_d_bad "$p  duplicate entry"
        seen[$p]=1
        _plug_valid "$p" || _plug_d_bad "$p  invalid name"
    done
    _plug_d_ok "${#raw} registry entries"

    # ---- Plugins ------------------------------------------------------------
    _plug_section "$PLUG_ICON_GIT" "Plugins"

    for p in "${PLUG_PLUGINS[@]}"; do
        _plug_kind "$p"; kind=$REPLY
        _plug_dir "$p"; dir=$REPLY
        _plug_display "$p"; disp=$REPLY

        # your own files
        if [[ $kind == local ]]; then
            if [[ ! -e $dir ]]; then
                _plug_d_bad "$disp  path is missing"
                continue
            fi
            if [[ -d $dir ]]; then lf=( $dir/*.zsh(N-.) ); else lf=( "$dir" ); fi
            badfiles=0
            for f in "${lf[@]}"; do
                [[ ${f:t} == _* ]] && continue
                command zsh -n "$f" >/dev/null 2>&1 || { (( ++badfiles )); _plug_d_bad "$disp  syntax error in ${f:t}" }
            done
            (( badfiles )) || _plug_d_ok "$disp  $(_plug_dim "local, ${#lf} file(s)")"
            continue
        fi

        _plug_git_dir "$p"

        if [[ ! -d $dir ]]; then
            _plug_d_bad "$p  directory missing  (plug sync / plug reinstall)"
            continue
        fi
        if [[ ! -e $REPLY/.git ]]; then
            _plug_d_bad "$p  not a git checkout"
            continue
        fi

        _plug_commit_of "$REPLY"
        if [[ -z $REPLY ]]; then
            _plug_d_bad "$p  unreadable git repository"
            continue
        fi

        branch=${PLUG_BRANCH[$p]}
        if [[ -n $branch ]]; then
            local cur=${${(f)"$(command git -C "$dir" symbolic-ref --short -q HEAD 2>/dev/null)"}}
            [[ $cur == $branch ]] || _plug_d_warn "$p  pinned to $branch but on ${cur:-detached}"
        fi

        _plug_plugin_name "$p"; name=$REPLY
        _plug_find_source "$dir" "$name"; src=$REPLY

        if [[ -z $src ]]; then
            w=( $dir/_*(N[1]) $dir/src/_*(N[1]) )
            if (( $#w )); then
                _plug_d_ok "$p  $(_plug_dim 'completions only')"
            else
                _plug_d_warn "$p  no source file found"
            fi
            continue
        fi

        if ! command zsh -n "$src" >/dev/null 2>&1; then
            _plug_d_bad "$p  syntax error in ${src:t}"
            _plug_log ERROR "syntax error: $p ($src)"
        elif [[ -n ${PLUG_DISABLED[$p]} ]]; then
            _plug_d_ok "$p  $(_plug_dim 'disabled')"
        elif [[ -n ${PLUG_LAZY[$p]} ]]; then
            _plug_d_ok "$p  $(_plug_dim "lazy: ${PLUG_LAZY[$p]}")"
        elif [[ -n ${PLUG_DEFER[$p]} ]]; then
            _plug_d_ok "$p  $(_plug_dim "deferred: ${PLUG_DEFER[$p]}ms")"
        else
            _plug_d_ok "$p  $(_plug_dim ${src:t})"
        fi
    done

    # ---- Oh My Zsh ----------------------------------------------------------
    if (( has_omz )); then
        _plug_section "$PLUG_ICON_PLUGIN" "Oh My Zsh"

        if (( $+commands[git] )); then
            autoload -Uz is-at-least
            if is-at-least 2.25 "$gv"; then _plug_d_ok "git supports sparse checkout"
            else _plug_d_bad "git $gv is too old for sparse checkout (2.25+ needed)"; fi
        fi

        for f in lib plugins; do
            if [[ -d $PLUG_OMZ_DIR/$f ]]; then _plug_d_ok "$f/ present"
            else _plug_d_bad "$f/ missing from the checkout"; fi
        done

        for f in ${=PLUG_OMZ_LIB}; do
            if [[ -f $PLUG_OMZ_DIR/lib/$f.zsh ]]; then _plug_d_ok "lib/$f.zsh"
            else _plug_d_warn "lib/$f.zsh not found (check PLUG_OMZ_LIB)"; fi
        done
    fi

    # ---- Cached tool inits --------------------------------------------------
    if (( $#PLUG_EVAL_NAMES )); then
        _plug_section "$PLUG_ICON_EVAL" "Cached tool inits"

        for c in "${PLUG_EVAL_NAMES[@]}"; do
            f=$PLUG_EVAL_DIR/$c.zsh
            if [[ ! -r $f ]]; then
                _plug_d_bad "$c  output missing  (plug eval refresh $c)"
            elif ! command zsh -n "$f" >/dev/null 2>&1; then
                _plug_d_bad "$c  cached output has a syntax error  (plug eval refresh $c)"
            else
                _plug_d_ok "$c  $(_plug_dim "${PLUG_EVAL_CMDS[$c]}")"
            fi
        done
    fi

    # ---- Disabled, lazy and deferred ----------------------------------------
    _plug_section "$PLUG_ICON_LAZY" "Disabled, lazy and deferred entries"

    local -i before=$(( _plug_d_err + _plug_d_warn ))

    for p in ${(k)PLUG_DISABLED}; do
        _plug_installed "$p" || _plug_d_warn "$p  disabled but not installed  (plug clean)"
    done

    for p in ${(k)PLUG_LAZY}; do
        if ! _plug_installed "$p"; then
            _plug_d_warn "$p  lazy entry but not installed  (plug clean)"
            continue
        fi
        for c in ${=PLUG_LAZY[$p]}; do
            if [[ -n ${triggers[$c]} && ${triggers[$c]} != $p ]]; then
                _plug_d_bad "$c  is the trigger of both $p and ${triggers[$c]}"
            fi
            triggers[$c]=$p
            if (( $+functions[$c] )) && [[ ${functions[$c]} != *_plug_lazy_fire* ]]; then
                _plug_d_warn "$c  is already a shell function; the lazy stub replaces it"
            fi
        done
    done

    for p in ${(k)PLUG_DEFER}; do
        _plug_installed "$p" || {
            _plug_d_warn "$p  deferred entry but not installed  (plug clean)"
            continue
        }
        [[ ${PLUG_DEFER[$p]} == <-> ]] || _plug_d_bad "$p  deferred delay is not a number: ${PLUG_DEFER[$p]}"
        [[ -n ${PLUG_LAZY[$p]} ]] && _plug_d_bad "$p  is both lazy and deferred"
    done

    (( _plug_d_err + _plug_d_warn == before )) && _plug_d_ok "consistent"

    # ---- Lockfile -----------------------------------------------------------
    _plug_section "$PLUG_ICON_LOCK" "Lockfile"

    if (( ! $#PLUG_LOCK_COMMIT )); then
        _plug_d_note "no lockfile (optional; create one with: plug lock)"
    else
        _plug_d_ok "${#PLUG_LOCK_COMMIT} locked target(s)"
        for p in "${PLUG_PLUGINS[@]}"; do
            [[ $p == local:* ]] && continue
            _plug_lock_key "$p"; key=$REPLY
            lk=${PLUG_LOCK_COMMIT[$key]}
            if [[ -z $lk ]]; then
                _plug_d_warn "$p  not in lockfile"
                continue
            fi
            _plug_git_dir "$p"
            _plug_commit_of "$REPLY"; commit=$REPLY
            [[ -z $commit ]] && continue
            [[ $commit == $lk ]] || _plug_d_warn "$p  differs from lock (${commit[1,7]} vs ${lk[1,7]})"
        done
    fi

    # ---- Cache --------------------------------------------------------------
    _plug_section "$PLUG_ICON_CACHE" "Startup cache"

    if [[ ! -s $PLUG_CACHE_FILE ]]; then
        _plug_d_warn "cache does not exist (plug cache rebuild)"
    else
        if _plug_cache_ok; then _plug_d_ok "cache is fresh"
        else _plug_d_warn "cache is stale (plug cache rebuild)"; fi

        while IFS= read -r line; do
            [[ $line == '[[ -r '* ]] || continue
            w=( ${(z)line} )
            f=${(Q)w[3]}
            [[ -f $f ]] || _plug_d_bad "cached file is missing: $f"
        done < "$PLUG_CACHE_FILE"
    fi

    # ---- Orphans ------------------------------------------------------------
    local -a orphans=()
    local -A keep=()
    for p in "${PLUG_PLUGINS[@]}"; do
        [[ $p == local:* || $p == omz:* ]] || keep[${p//\//__}]=1
    done
    for dir in $PLUG_PLUGIN_DIR/*(N/); do
        [[ -n ${keep[${dir:t}]} ]] || orphans+=( "${dir:t}" )
    done
    (( $#orphans )) && _plug_d_warn "unregistered directories: ${(j:, :)orphans}  (plug clean)"

    # ---- Log ----------------------------------------------------------------
    _plug_section "$PLUG_ICON_LOG" "Log"

    if [[ -s $PLUG_LOG_FILE ]]; then
        local -a big=( $PLUG_LOG_FILE(N.L+$PLUG_MAX_LOG_SIZE) )
        if (( $#big )); then _plug_d_warn "log exceeds ${PLUG_MAX_LOG_SIZE} bytes (rotates on next write)"
        else _plug_d_ok "log present  ($(command wc -l < "$PLUG_LOG_FILE" | tr -d ' ') lines)"; fi
    else
        _plug_d_ok "log is empty"
    fi

    # ---- Summary ------------------------------------------------------------
    if (( _plug_d_err == 0 && _plug_d_warn == 0 )); then
        _plug_box 114 "$PLUG_ICON_OK  plug is healthy"
        return 0
    fi

    if (( _plug_d_err == 0 )); then
        _plug_box 221 "$PLUG_ICON_WARN  ${_plug_d_warn} warning(s), no errors"
        return 0
    fi

    _plug_box 204 "$PLUG_ICON_FAIL  ${_plug_d_err} error(s)    $PLUG_ICON_WARN  ${_plug_d_warn} warning(s)"
    return 1
}
