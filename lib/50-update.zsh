# =============================================================================
#  lib/50-update.zsh — update, outdated, lock, sync, reinstall, clean, selfupdate
# =============================================================================


# =============================================================================
# plug update  (parallel)
# =============================================================================

# _plug_update_collect <tmp> <id> <name> <pid>
# Returns 0 = already up to date, 2 = updated, 1 = failed.
_plug_update_collect() {
    local tmp=$1 id=$2 name=$3 pid=$4
    local -i rc=1
    local -a w

    wait "$pid" 2>/dev/null
    [[ -r $tmp/$id.rc ]] && rc=$(<"$tmp/$id.rc")

    if (( rc == 0 )); then
        w=( ${=$(<"$tmp/$id.out")} )
        if [[ -n $w[1] && $w[1] == $w[2] ]]; then
            _plug_ok "${(r:34:)name} $(_plug_dim 'up to date')"
            return 0
        fi
        _plug_ok "${(r:34:)name} $(_plug_c "$PLUG_C_INFO" "$w[1]  $PLUG_ICON_ARROW  $w[2]")"
        return 2
    fi

    _plug_err "${(r:34:)name} update failed  (see: plug logs)"
    _plug_log ERROR "update failed: $name :: ${$(<"$tmp/$id.err")//$'\n'/ }"
    return 1
}

plug_update() {
    emulate -L zsh
    setopt local_options no_monitor no_notify

    _plug_need git || return 1
    _plug_load_all

    local a p t dir tmp branch
    local -a names=() q_pid=() q_name=() q_id=()
    local -i rc=0 i=0 changed=0 failed=0 current=0 r

    if (( $# )); then
        for a in "$@"; do
            _plug_norm "$a"; p=$REPLY
            if [[ $p == omz ]]; then
                local q
                for q in "${PLUG_PLUGINS[@]}"; do
                    [[ $q == omz:* ]] && names+=( "$q" )
                done
            elif [[ $p == local:* ]]; then
                _plug_err "$a is a local path, nothing to update"
                rc=1
            elif _plug_installed "$p"; then
                names+=( "$p" )
            else
                _plug_err "$a is not installed"
                rc=1
            fi
        done
    else
        names=( "${PLUG_PLUGINS[@]}" )
    fi

    _plug_targets "${names[@]}"
    local -a targets=( "${reply[@]}" )

    if (( ! $#targets )); then
        _plug_info "Nothing to update"
        return $rc
    fi

    tmp=$(command mktemp -d "${TMPDIR:-/tmp}/plug.XXXXXX") || {
        _plug_err "Could not create a temporary directory"
        return 1
    }
    trap 'command rm -rf -- "$tmp" 2>/dev/null' INT TERM

    _plug_info "$PLUG_ICON_UPDATE  Updating ${#targets} target(s), $PLUG_JOBS at a time"
    print

    for t in "${targets[@]}"; do
        (( ++i ))
        _plug_git_dir "$t"; dir=$REPLY
        branch=${PLUG_BRANCH[$t]}

        if [[ ! -e $dir/.git ]]; then
            _plug_err "${(r:34:)t} not cloned  (run: plug sync)"
            (( ++failed ))
            continue
        fi

        (
            command sh -c "$_plug_sh_update" sh "$dir" "$branch" \
                >"$tmp/$i.out" 2>"$tmp/$i.err"
            print -r -- $? >"$tmp/$i.rc"
        ) &

        q_pid+=( $! ); q_name+=( "$t" ); q_id+=( $i )

        while (( $#q_pid >= PLUG_JOBS )); do
            _plug_update_collect "$tmp" "$q_id[1]" "$q_name[1]" "$q_pid[1]"
            r=$?
            case $r in 0) (( ++current )) ;; 2) (( ++changed )) ;; *) (( ++failed )) ;; esac
            shift q_pid q_name q_id
        done
    done

    while (( $#q_pid )); do
        _plug_update_collect "$tmp" "$q_id[1]" "$q_name[1]" "$q_pid[1]"
        r=$?
        case $r in 0) (( ++current )) ;; 2) (( ++changed )) ;; *) (( ++failed )) ;; esac
        shift q_pid q_name q_id
    done

    command rm -rf -- "$tmp"
    trap - INT TERM

    (( changed )) && _plug_build_cache

    # A full update also refreshes cached tool inits (zoxide, starship, ...).
    if (( ! $# )); then
        _plug_load_evals
        if (( $#PLUG_EVAL_NAMES )); then
            print
            plug_eval refresh || rc=1
        fi
    fi

    if (( failed == 0 )); then
        _plug_box 114 "$PLUG_ICON_OK  $changed updated    $current up to date"
    else
        _plug_box 221 "$PLUG_ICON_UPDATE  $changed updated    $PLUG_ICON_FAIL  $failed failed"
    fi

    if (( changed )); then
        _plug_info "Restart your shell to use the new versions:  $(_plug_c "1;$PLUG_C_TEXT" 'exec zsh')"
        _plug_load_lock
        (( $#PLUG_LOCK_COMMIT )) &&
            _plug_info "Lockfile not changed. Run  $(_plug_c "1;$PLUG_C_TEXT" 'plug lock')  to record the new versions"
    fi

    (( failed == 0 && rc == 0 ))
}


# =============================================================================
# plug outdated   (check upstream without changing anything)
# =============================================================================

# Prints one line; returns 0 = up to date, 1 = behind, 2 = broken/unreachable.
_plug_outdated_collect() {
    local tmp=$1 name=$2 id=$3
    local dir remote local_commit rc
    local -a w

    _plug_git_dir "$name"; dir=$REPLY

    if [[ ! -r $tmp/$id.rc ]]; then
        _plug_err "${(r:34:)name} not cloned"
        return 2
    fi

    rc=$(<"$tmp/$id.rc")
    if (( rc != 0 )); then
        _plug_warn "${(r:34:)name} could not reach the remote"
        return 2
    fi

    w=( ${=$(<"$tmp/$id.out")} )
    remote=$w[1]
    _plug_commit_of "$dir"; local_commit=$REPLY

    if [[ -n $remote && $remote == $local_commit ]]; then
        _plug_ok "${(r:34:)name} $(_plug_dim 'up to date')"
        return 0
    fi

    _plug_warn "${(r:34:)name} $(_plug_c "$PLUG_C_WARN" "update available  ${local_commit[1,7]}  $PLUG_ICON_ARROW  ${remote[1,7]}")"
    return 1
}

plug_outdated() {
    emulate -L zsh
    setopt local_options no_monitor no_notify

    _plug_need git || return 1
    _plug_load_registry

    _plug_targets "${PLUG_PLUGINS[@]}"
    local -a targets=( "${reply[@]}" )

    if (( ! $#targets )); then
        _plug_info "No git plugins installed"
        return 0
    fi

    local t dir tmp
    local -i i=0 behind=0 current=0 broken=0 rc
    local -a q_pid=() q_id=() q_name=()

    tmp=$(command mktemp -d "${TMPDIR:-/tmp}/plug.XXXXXX") || {
        _plug_err "Could not create a temporary directory"
        return 1
    }
    trap 'command rm -rf -- "$tmp" 2>/dev/null' INT TERM

    _plug_info "$PLUG_ICON_CLOUD  Checking ${#targets} remote(s), $PLUG_JOBS at a time"
    print

    for t in "${targets[@]}"; do
        (( ++i ))
        _plug_git_dir "$t"; dir=$REPLY
        if [[ ! -e $dir/.git ]]; then
            _plug_err "${(r:34:)t} not cloned"
            (( ++broken ))
            continue
        fi

        (
            command sh -c 'cd "$1" && GIT_TERMINAL_PROMPT=0 git ls-remote origin HEAD' sh "$dir" \
                >"$tmp/$i.out" 2>/dev/null
            print -r -- $? >"$tmp/$i.rc"
        ) &

        q_pid+=( $! ); q_id+=( $i ); q_name+=( "$t" )

        while (( $#q_pid >= PLUG_JOBS )); do
            wait "$q_pid[1]" 2>/dev/null
            _plug_outdated_collect "$tmp" "$q_name[1]" "$q_id[1]"
            case $? in 0) (( ++current )) ;; 1) (( ++behind )) ;; *) (( ++broken )) ;; esac
            shift q_pid q_id q_name
        done
    done

    while (( $#q_pid )); do
        wait "$q_pid[1]" 2>/dev/null
        _plug_outdated_collect "$tmp" "$q_name[1]" "$q_id[1]"
        case $? in 0) (( ++current )) ;; 1) (( ++behind )) ;; *) (( ++broken )) ;; esac
        shift q_pid q_id q_name
    done

    command rm -rf -- "$tmp"
    trap - INT TERM

    if (( behind )); then
        _plug_box 221 "$PLUG_ICON_CLOUD  $behind update(s) available    $current up to date"
        _plug_info "Run  $(_plug_c "1;$PLUG_C_TEXT" 'plug update')  to apply them"
    else
        _plug_box 114 "$PLUG_ICON_OK  everything is up to date"
    fi

    return 0
}


# =============================================================================
# plug lock / sync
# =============================================================================

plug_lock() {
    emulate -L zsh
    _plug_need git || return 1
    _plug_load_registry

    _plug_targets "${PLUG_PLUGINS[@]}"
    local -a targets=( "${reply[@]}" )

    if (( ! $#targets )); then
        _plug_info "No git plugins installed"
        return 0
    fi

    local t dir commit branch
    local -i failed=0
    local -a lines=( "# plug.zsh lockfile" "# name|branch|commit" )

    print
    for t in "${targets[@]}"; do
        _plug_git_dir "$t"; dir=$REPLY

        if [[ ! -e $dir/.git ]]; then
            _plug_err "${(r:34:)t} not cloned"
            (( ++failed ))
            continue
        fi

        _plug_commit_of "$dir"; commit=$REPLY
        if [[ -z $commit ]]; then
            _plug_err "${(r:34:)t} could not read commit"
            (( ++failed ))
            continue
        fi

        branch=$(command git -C "$dir" symbolic-ref --short -q HEAD 2>/dev/null)
        lines+=( "$t|${branch:-detached}|$commit" )
        _plug_ok "${(r:34:)t} $(_plug_dim ${commit[1,7]})"
    done

    if (( failed )); then
        _plug_err "Lockfile not written ($failed problem(s))"
        return 1
    fi

    _plug_write "$PLUG_LOCK_FILE" "${lines[@]}"
    _plug_box 114 "$PLUG_ICON_LOCK  Locked ${#targets} target(s)"
}

plug_sync() {
    emulate -L zsh
    _plug_need git || return 1
    _plug_load_registry
    _plug_load_lock

    print
    if (( ! $#PLUG_LOCK_COMMIT )); then
        _plug_err "No lockfile entries. Run: plug lock"
        return 1
    fi

    _plug_targets "${PLUG_PLUGINS[@]}"
    local -a targets=( "${reply[@]}" )

    local t dir commit current
    local -i ok=0 failed=0 skipped=0

    for t in "${targets[@]}"; do
        commit=${PLUG_LOCK_COMMIT[$t]}
        _plug_git_dir "$t"; dir=$REPLY

        if [[ ! -e $dir/.git ]]; then
            if [[ $t == omz ]]; then
                _plug_omz_ensure || { (( ++failed )); continue }
            else
                _plug_clone "$t" || { (( ++failed )); continue }
            fi
        fi

        if [[ -z $commit ]]; then
            _plug_warn "${(r:34:)t} not in lockfile, left unchanged"
            (( ++skipped ))
            continue
        fi

        _plug_commit_of "$dir"; current=$REPLY
        if [[ $current == $commit ]]; then
            _plug_ok "${(r:34:)t} $(_plug_dim "${commit[1,7]}  already in sync")"
            (( ++ok ))
            continue
        fi

        if _plug_spin "$PLUG_ICON_SYNC  Syncing $t" \
                sh -c "$_plug_sh_sync" sh "$PLUG_LOG_FILE" "$dir" "$commit"
        then
            _plug_ok "${(r:34:)t} $(_plug_c "$PLUG_C_INFO" ${commit[1,7]})"
            (( ++ok ))
        else
            _plug_err "${(r:34:)t} could not reach ${commit[1,7]}  (see: plug logs)"
            _plug_log ERROR "sync failed: $t ($commit)"
            (( ++failed ))
        fi
    done

    _plug_build_cache

    if (( failed == 0 )); then
        _plug_box 114 "$PLUG_ICON_SYNC  $ok in sync    $skipped unlocked"
    else
        _plug_box 221 "$PLUG_ICON_SYNC  $ok in sync    $PLUG_ICON_FAIL  $failed failed"
    fi

    (( failed == 0 ))
}


# =============================================================================
# plug reinstall
# =============================================================================

plug_reinstall() {
    emulate -L zsh
    local -i yes=0
    [[ $1 == -y || $1 == --yes ]] && yes=1

    _plug_need git || return 1
    _plug_load_all

    _plug_targets "${PLUG_PLUGINS[@]}"
    local -a targets=( "${reply[@]}" )

    if (( ! $#targets )); then
        _plug_info "No git plugins to reinstall"
        return 0
    fi

    if (( ! yes )) && ! _plug_confirm "Delete and re-clone ${#targets} git target(s)?"; then
        _plug_info "Cancelled"
        return 0
    fi

    command rm -rf -- "$PLUG_PLUGIN_DIR" "$PLUG_OMZ_DIR"
    _plug_init_dirs

    local t
    local -i failed=0
    for t in "${targets[@]}"; do
        if [[ $t == omz ]]; then
            _plug_omz_ensure || (( ++failed ))
        else
            _plug_clone "$t" || (( ++failed ))
        fi
    done

    _plug_build_cache

    if (( failed )); then
        _plug_err "$failed target(s) could not be restored"
        return 1
    fi
    _plug_ok "Reinstalled ${#targets} target(s)"
    _plug_info "Restart your shell:  $(_plug_c "1;$PLUG_C_TEXT" 'exec zsh')"
}


# =============================================================================
# plug selfupdate
# =============================================================================

plug_selfupdate() {
    emulate -L zsh
    _plug_need git || return 1

    local dir=$PLUG_ROOT
    if [[ ! -e $dir/.git ]]; then
        _plug_err "plug.zsh is not inside a git checkout: $dir"
        _plug_info "Install it with:  git clone <url> $dir"
        return 1
    fi

    if _plug_spin "$PLUG_ICON_CLOUD  Updating plug.zsh" \
            sh -c 'cd "$1" && GIT_TERMINAL_PROMPT=0 git pull --ff-only --quiet' sh "$dir"
    then
        _plug_ok "$PLUG_ICON_CLOUD  plug.zsh is up to date"
        _plug_build_cache
        _plug_info "Restart your shell to load the new version:  $(_plug_c "1;$PLUG_C_TEXT" 'exec zsh')"
    else
        _plug_log ERROR "selfupdate failed in $dir"
        _plug_err "Could not update plug.zsh  (see: plug logs)"
        return 1
    fi
}


# =============================================================================
# plug clean
# =============================================================================

plug_clean() {
    emulate -L zsh
    local -i yes=0
    [[ $1 == -y || $1 == --yes ]] && yes=1

    _plug_load_all
    _plug_load_lock

    local d p k
    local -A keep=()
    local -a orphans=() stale=()
    local -i has_omz=0

    for p in "${PLUG_PLUGINS[@]}"; do
        case $p in
            omz:*)   has_omz=1 ;;
            local:*) ;;
            *)       keep[${p//\//__}]=1 ;;
        esac
    done

    for d in $PLUG_PLUGIN_DIR/*(N/); do
        [[ -n ${keep[${d:t}]} ]] || orphans+=( "$d" )
    done

    [[ -e $PLUG_OMZ_DIR ]] && (( ! has_omz )) && orphans+=( "$PLUG_OMZ_DIR" )

    for d in $PLUG_EVAL_DIR/*.zsh(N); do
        (( ${PLUG_EVAL_NAMES[(Ie)${${d:t}%.zsh}]} )) || orphans+=( "$d" )
    done

    for k in ${(k)PLUG_DISABLED} ${(k)PLUG_LAZY} ${(k)PLUG_DEFER} ${(k)PLUG_BRANCH}; do
        _plug_installed "$k" || stale+=( "$k" )
    done
    for k in ${(k)PLUG_LOCK_COMMIT}; do
        [[ $k == omz ]] && { (( has_omz )) && continue }
        _plug_installed "$k" || stale+=( "$k" )
    done

    if (( ! $#orphans && ! $#stale )); then
        _plug_info "Nothing to clean"
        return 0
    fi

    for d in "${orphans[@]}"; do _plug_info "orphaned: ${d/#$HOME/~}"; done
    for k in "${stale[@]}";   do _plug_info "stale entry: $k"; done

    if (( ! yes )) && ! _plug_confirm "Remove these?"; then
        _plug_info "Cancelled"
        return 0
    fi

    for d in "${orphans[@]}"; do command rm -rf -- "$d"; done
    for k in "${stale[@]}"; do
        unset "PLUG_DISABLED[$k]" "PLUG_LAZY[$k]" "PLUG_DEFER[$k]" \
              "PLUG_BRANCH[$k]" "PLUG_LOCK_COMMIT[$k]" "PLUG_LOCK_BRANCH[$k]"
    done

    _plug_save_disabled
    _plug_save_lazy
    _plug_save_defer
    _plug_save_branches
    _plug_save_lock
    _plug_build_cache

    _plug_ok "$PLUG_ICON_CLEAN  Cleaned ${#orphans} item(s), ${#stale} entr(ies)"
}
