# =============================================================================
#  lib/30-cache.zsh — compinit, OMZ environment, startup cache, lazy/defer
# =============================================================================


# =============================================================================
# compinit and Oh My Zsh environment
# =============================================================================

# Runs compinit once. The dump is reused (-C) until the plugin set changes.
_plug_compinit() {
    emulate -L zsh
    (( PLUG_COMPINIT_DONE )) && return 0
    PLUG_COMPINIT_DONE=1

    [[ -d $PLUG_CACHE_DIR ]] || command mkdir -p "$PLUG_CACHE_DIR"

    local dump="$PLUG_CACHE_DIR/zcompdump-$ZSH_VERSION"
    autoload -Uz compinit
    if [[ -s $dump ]]; then
        compinit -C -i -d "$dump"
    else
        compinit -i -d "$dump"
    fi
}

# Environment OMZ plugins expect. Idempotent. The OMZ lib files are sourced
# at the top level of the cache (see _plug_build_cache), not here.
_plug_omz_setup() {
    emulate -L zsh
    (( PLUG_OMZ_READY )) && return 0
    PLUG_OMZ_READY=1

    export ZSH="$PLUG_OMZ_DIR"
    export ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"
    export ZSH_CACHE_DIR="$PLUG_OMZ_CACHE_DIR"

    [[ -d $ZSH_CACHE_DIR/completions ]] ||
        command mkdir -p "$ZSH_CACHE_DIR/completions"

    fpath=( "$ZSH_CACHE_DIR/completions" $fpath )

    autoload -Uz is-at-least add-zsh-hook

    (( PLUG_COMPINIT )) && _plug_compinit
    return 0
}


# =============================================================================
# Profiling hooks (only called when PLUG_PROFILE=1)
# =============================================================================

_plug_prof_begin() { _plug_prof_t0=$EPOCHREALTIME }

_plug_prof_end() {
    local -F ms=$(( (EPOCHREALTIME - _plug_prof_t0) * 1000 ))
    PLUG_PROF_NAMES+=( "$1" )
    PLUG_PROF_TIMES+=( "$ms" )
}

_plug_prof_report() {
    emulate -L zsh
    _plug_color_init

    if (( ! $#PLUG_PROF_NAMES )); then
        _plug_info "Nothing was loaded at startup"
        return 0
    fi

    local -a rows=()
    local -F total=0 max=0 ms
    local -i i n
    local row bar col name e=

    for (( i = 1; i <= $#PLUG_PROF_NAMES; i++ )); do
        ms=$PLUG_PROF_TIMES[$i]
        rows+=( "$(printf '%09.3f' $ms)|$i" )
        (( total += ms ))
        (( ms > max )) && max=$ms
    done

    print
    print -r -- "  $(_plug_c "1;$PLUG_C_ACCENT" "$PLUG_ICON_PROFILE  Startup profile")"
    print
    for row in ${(On)rows}; do
        i=${row#*|}
        ms=$PLUG_PROF_TIMES[$i]
        name=$PLUG_PROF_NAMES[$i]
        n=1
        (( max > 0 )) && n=$(( ms / max * 24 ))
        (( n < 1 )) && n=1
        bar=${(l:$n::█:)e}

        if   (( ms >= 20 )); then col=$PLUG_C_ERR
        elif (( ms >= 5  )); then col=$PLUG_C_WARN
        else col=$PLUG_C_OK; fi

        print -r -- "  ${(r:36:)name} $(printf '%8.2f' $ms) ms  $(_plug_c $col $bar)"
    done
    print
    print -r -- "  $(_plug_dim "$PLUG_ICON_CLOCK  total")  $(_plug_c "1;$PLUG_C_TEXT" "$(printf '%.2f' $total) ms")"
    print
}


# =============================================================================
# Startup cache
# =============================================================================

# Cheap freshness test: only file-time comparisons, no forks.
_plug_cache_ok() {
    [[ -s $PLUG_CACHE_FILE ]] || return 1
    [[ $PLUG_PLUGIN_FILE   -nt $PLUG_CACHE_FILE ]] && return 1
    [[ $PLUG_DISABLED_FILE -nt $PLUG_CACHE_FILE ]] && return 1
    [[ $PLUG_LAZY_FILE     -nt $PLUG_CACHE_FILE ]] && return 1
    [[ $PLUG_DEFER_FILE    -nt $PLUG_CACHE_FILE ]] && return 1
    [[ $PLUG_BRANCH_FILE   -nt $PLUG_CACHE_FILE ]] && return 1
    [[ $PLUG_EVAL_FILE     -nt $PLUG_CACHE_FILE ]] && return 1
    [[ $PLUG_SELF          -nt $PLUG_CACHE_FILE ]] && return 1

    local f
    for f in "$PLUG_ROOT"/lib/*.zsh(N); do
        [[ $f -nt $PLUG_CACHE_FILE ]] && return 1
    done
    return 0
}

# Writes the completion for the `plug` command into the managed completions
# directory, which is always on fpath.
_plug_write_completion() {
    emulate -L zsh
    local file="$PLUG_COMP_DIR/_plug"
    [[ -d $PLUG_COMP_DIR ]] || return 1

    command cat > "$file.tmp.$$" <<'PLUG_COMPLETION_EOF'
#compdef plug
local -a subs opts
local sub=${words[2]}

if (( CURRENT == 2 )); then
    subs=(
        'install:install plugins (user/repo, user/repo@branch or omz:name)'
        'browse:browse popular GitHub plugins'
        'omz:browse all installed Oh My Zsh plugins'
        'add:add your own zsh files or directories'
        'remove:remove plugins'
        'enable:enable plugins'
        'disable:disable plugins'
        'lazy:load a plugin on first use of a command'
        'unlazy:load a plugin at startup again'
        'defer:load a plugin a moment after the first prompt (turbo)'
        'undefer:load a deferred plugin at startup again'
        'source:load a plugin into the current shell right now'
        'update:update plugins in parallel'
        'outdated:show plugins with upstream changes'
        'lock:record exact commits'
        'sync:restore recorded commits'
        'status:dashboard'
        'list:names and states'
        'doctor:deep health check'
        'profile:measure startup cost'
        'eval:cache the output of tool init commands'
        'completion:manage custom completions'
        'edit:edit a registry file'
        'logs:show the log'
        'cache:manage the startup cache'
        'clean:remove orphans and stale entries'
        'reinstall:re-clone everything'
        'selfupdate:update plug.zsh itself'
        'info:paths and settings'
        'menu:interactive menu'
        'reload:restart the shell'
        'help:show help'
    )
    _describe -t commands 'plug command' subs
    return
fi

case $sub in
    remove|rm|uninstall|enable|en|disable|dis|update|up|upgrade|lazy|unlazy|defer|undefer|source)
        _plug_load_registry
        compadd -a PLUG_PLUGINS
        ;;
    add)
        _files
        ;;
    edit)
        compadd plugins lazy disabled deferred branches evals
        ;;
    cache)
        compadd rebuild clear show
        ;;
    logs)
        compadd clear
        ;;
    completion)
        if (( CURRENT == 3 )); then
            compadd add gen list remove
        elif [[ ${words[3]} == add ]]; then
            _files
        elif [[ ${words[3]} == remove ]]; then
            compadd -- $PLUG_COMP_DIR/_*(N:t)
        fi
        ;;
    eval)
        if (( CURRENT == 3 )); then
            compadd add remove list refresh
        elif [[ ${words[3]} == (remove|refresh) ]]; then
            _plug_load_evals
            compadd -a PLUG_EVAL_NAMES
        fi
        ;;
esac
PLUG_COMPLETION_EOF

    command mv -f "$file.tmp.$$" "$file"
}

_plug_build_cache() {
    emulate -L zsh
    setopt extended_glob

    _plug_init_dirs
    _plug_load_all

    local p kind dir name src c cmds n ms id sec
    local -i need_omz=0 want_comp=0
    local -a fp=( "$PLUG_COMP_DIR" )
    local -a out=() lazy=() deferred=() sn=() sf=() sm=() ev=() comp=()

    for p in "${PLUG_PLUGINS[@]}"; do
        [[ -n ${PLUG_DISABLED[$p]} ]] && continue

        _plug_kind "$p"; kind=$REPLY
        _plug_dir "$p"; dir=$REPLY

        # ---- your own files and directories ---------------------------------
        if [[ $kind == local ]]; then
            if [[ ! -e $dir ]]; then
                _plug_log WARN "local path missing, skipped: $dir"
                continue
            fi

            if [[ -d $dir ]]; then
                fp+=( "$dir" )
                _plug_find_source "$dir" "${dir:t}"; src=$REPLY
                if [[ -n $src ]]; then
                    sn+=( "$p" ); sf+=( "$src" ); sm+=( file )
                else
                    # No plugin-style entry point: source every *.zsh at startup.
                    sn+=( "$p" ); sf+=( "$dir" ); sm+=( glob )
                fi
            elif [[ ${dir:t} == _* ]]; then
                fp+=( "${dir:h}" )
            else
                sn+=( "$p" ); sf+=( "$dir" ); sm+=( file )
            fi
            continue
        fi

        # ---- git and Oh My Zsh plugins --------------------------------------
        if [[ ! -d $dir ]]; then
            _plug_log WARN "plugin directory missing, skipped: $p"
            continue
        fi

        _plug_plugin_name "$p"; name=$REPLY
        _plug_find_source "$dir" "$name"; src=$REPLY

        # Completions: OMZ always adds the plugin dir; others only when the
        # plugin ships completion files.
        if [[ $kind == omz ]]; then
            fp+=( "$dir" )
        else
            comp=( $dir/_*(N[1]) )
            (( $#comp )) && fp+=( "$dir" )
            comp=( $dir/src/_*(N[1]) )
            (( $#comp )) && fp+=( "$dir/src" )
        fi

        if [[ -n ${PLUG_LAZY[$p]} ]]; then
            lazy+=( "$p" )
            continue
        fi

        if [[ -n ${PLUG_DEFER[$p]} ]]; then
            deferred+=( "$p" )
            continue
        fi

        [[ $kind == omz ]] && need_omz=1
        [[ -n $src ]] || continue

        sn+=( "$p" ); sf+=( "$src" ); sm+=( file )
    done

    # ---- cached tool inits --------------------------------------------------
    for n in "${PLUG_EVAL_NAMES[@]}"; do
        if [[ -r $PLUG_EVAL_DIR/$n.zsh ]]; then
            ev+=( "$n" )
        else
            _plug_log WARN "eval output missing, skipped: $n (run: plug eval refresh $n)"
        fi
    done

    # compinit only when something actually needs it.
    comp=( $PLUG_COMP_DIR/_*(N) )
    (( $#comp > 1 || $#fp > 1 || $#ev )) && want_comp=1

    out+=(
        "# plug.zsh startup cache. Generated automatically: do not edit."
        "(( PLUG_PROFILE )) && zmodload zsh/datetime"
        ""
        "fpath=( ${(j: :)${(@qq)fp}} \$fpath )"
        ""
    )

    if (( need_omz )); then
        out+=(
            "_plug_omz_setup"
            'for _plug_l in ${=PLUG_OMZ_LIB}; do [[ -r $ZSH/lib/$_plug_l.zsh ]] && source $ZSH/lib/$_plug_l.zsh; done'
            "unset _plug_l"
            "PLUG_OMZ_LIBS=1"
            ""
        )
    elif (( want_comp && PLUG_COMPINIT )); then
        out+=( "_plug_compinit" "" )
    fi

    local i
    for (( i = 1; i <= $#sn; i++ )); do
        out+=( "(( PLUG_PROFILE )) && _plug_prof_begin ${(qq)sn[i]}" )
        if [[ $sm[i] == glob ]]; then
            out+=(
                "for _plug_f in ${(qq)sf[i]}/*.zsh(N-.); do "'[[ ${_plug_f:t} == _* ]] || source "$_plug_f"; done; unset _plug_f'
            )
        else
            out+=( "[[ -r ${(qq)sf[i]} ]] && source ${(qq)sf[i]}" )
        fi
        out+=(
            "PLUG_LOADED[${(qq)sn[i]}]=1"
            "(( PLUG_PROFILE )) && _plug_prof_end ${(qq)sn[i]}"
            ""
        )
    done

    for n in "${ev[@]}"; do
        local evfile="$PLUG_EVAL_DIR/$n.zsh"
        out+=(
            "(( PLUG_PROFILE )) && _plug_prof_begin ${(qq)n}"
            "[[ -r ${(qq)evfile} ]] && source ${(qq)evfile}"
            "(( PLUG_PROFILE )) && _plug_prof_end ${(qq)n}"
            ""
        )
    done

    # Lazy plugins: a stub function per trigger command.
    local re='^[A-Za-z0-9_.+-]+$'
    for p in "${lazy[@]}"; do
        cmds=${PLUG_LAZY[$p]}
        for c in ${=cmds}; do
            [[ $c =~ $re ]] || continue
            out+=( "function $c { _plug_lazy_fire ${(qq)p} $cmds || return \$?; $c \"\$@\" }" )
        done
    done

    # Deferred (turbo) plugins: load shortly after the first prompt.
    if (( $#deferred )); then
        out+=( "" )
        for p in "${deferred[@]}"; do
            ms=${PLUG_DEFER[$p]}
            [[ $ms == <-> ]] || ms=1000
            id=${${p//[^A-Za-z0-9_]/_}}
            if (( ms < 1000 )); then
                out+=(
                    "function _plug_pd_$id { add-zsh-hook -d precmd _plug_pd_$id 2>/dev/null; _plug_defer_fire ${(qq)p} }"
                    "autoload -Uz add-zsh-hook 2>/dev/null && add-zsh-hook precmd _plug_pd_$id"
                )
            else
                sec=$(( (ms + 999) / 1000 ))
                out+=(
                    "zmodload zsh/sched 2>/dev/null && sched +$sec _plug_defer_fire ${(qq)p}"
                )
            fi
        done
        out+=( "" )
    fi

    local tmp="$PLUG_CACHE_FILE.tmp.$$"
    print -rl -- "${out[@]}" > "$tmp" || return 1
    command mv -f "$tmp" "$PLUG_CACHE_FILE"

    _plug_write_completion

    # compinit's dump depends on the plugin set.
    command rm -f $PLUG_CACHE_DIR/zcompdump-*(N) 2>/dev/null
    return 0
}

# Load one plugin into the current shell (used by lazy and defer).
_plug_load_one() {
    emulate -L zsh
    local repo=$1 dir name src l

    [[ -n ${PLUG_LOADED[$repo]} ]] && return 0

    _plug_dir "$repo"; dir=$REPLY
    if [[ ! -d $dir ]]; then
        _plug_log ERROR "plugin missing: $repo"
        print -u2 -r -- "plug: plugin is not installed: $repo"
        return 1
    fi

    if [[ $repo == omz:* ]]; then
        _plug_omz_setup
        if (( ! PLUG_OMZ_LIBS )); then
            for l in ${=PLUG_OMZ_LIB}; do
                [[ -r $ZSH/lib/$l.zsh ]] && source "$ZSH/lib/$l.zsh"
            done
            PLUG_OMZ_LIBS=1
        fi
    fi

    _plug_plugin_name "$repo"; name=$REPLY
    _plug_find_source "$dir" "$name"; src=$REPLY
    [[ -n $src ]] && source "$src"

    PLUG_LOADED[$repo]=1
    return 0
}

# Called by the stub functions in the cache.
_plug_lazy_fire() {
    local repo=$1 c
    shift
    for c in "$@"; do unfunction "$c" 2>/dev/null; done
    _plug_load_one "$repo"
}

# Called by zsh/sched or the one-shot precmd hook for deferred plugins.
_plug_defer_fire() {
    _plug_load_one "$1"
}
