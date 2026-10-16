# =============================================================================
#  lib/10-core.zsh — names, paths, registry storage, lock access
# =============================================================================


# =============================================================================
# Names and paths
# =============================================================================

_plug_is_omz() { [[ $1 == omz || $1 == omz:* ]] }

# _plug_kind <name>  ->  REPLY   (git | omz | local)
_plug_kind() {
    case $1 in
        omz|omz:*) REPLY=omz ;;
        local:*)   REPLY=local ;;
        *)         REPLY=git ;;
    esac
}

# _plug_norm <input>  ->  REPLY
#   OMZ:git -> omz:git     URL -> user/repo     ~/x, /x, ./x -> local:/abs/x
_plug_norm() {
    local n=$1
    case $n in
        local:*)
            REPLY=$n
            return 0
            ;;
        /*|./*|../*|'~'|'~/')
            n=${n/#\~/$HOME}
            REPLY="local:${n:A}"
            return 0
            ;;
    esac
    n=${n#https://github.com/}
    n=${n%/}
    n=${n%.git}
    [[ ${n:l} == omz:* ]] && n="omz:${n#*:}"
    REPLY=$n
}

_plug_valid() {
    local re
    case $1 in
        local:/*) return 0 ;;
        omz:*)    re='^omz:[A-Za-z0-9][A-Za-z0-9_.+-]*$' ;;
        *)        re='^[A-Za-z0-9_][A-Za-z0-9_.-]*/[A-Za-z0-9_][A-Za-z0-9_.-]*$' ;;
    esac
    [[ $1 =~ $re ]]
}

# _plug_dir <name>  ->  REPLY    directory (or file) that holds the plugin
_plug_dir() {
    case $1 in
        omz:*)   REPLY="$PLUG_OMZ_DIR/plugins/${1#omz:}" ;;
        local:*) REPLY="${1#local:}" ;;
        *)       REPLY="$PLUG_PLUGIN_DIR/${1//\//__}" ;;
    esac
}

# _plug_git_dir <name|omz>  ->  REPLY    directory that holds the .git
_plug_git_dir() {
    if _plug_is_omz "$1"; then
        REPLY=$PLUG_OMZ_DIR
    elif [[ $1 == local:* ]]; then
        REPLY="${1#local:}"
    else
        REPLY="$PLUG_PLUGIN_DIR/${1//\//__}"
    fi
}

# Name as shown to people (local paths are shortened with ~).
_plug_display() {
    if [[ $1 == local:* ]]; then
        REPLY="${1#local:}"
        REPLY="${REPLY/#$HOME/~}"
    else
        REPLY=$1
    fi
}

# Key used in the lockfile (all OMZ plugins share one checkout).
_plug_lock_key() {
    if _plug_is_omz "$1"; then REPLY=omz; else REPLY=$1; fi
}

_plug_installed() { (( ${PLUG_PLUGINS[(Ie)$1]} )) }

# _plug_find_source <dir> <name>  ->  REPLY (empty when there is nothing)
_plug_find_source() {
    emulate -L zsh
    local dir=$1 name=$2 f
    local -a g
    REPLY=

    f="$dir/$name.plugin.zsh"
    [[ -f $f ]] && { REPLY=$f; return 0 }

    g=( $dir/*.plugin.zsh(N[1]) )
    (( $#g )) && { REPLY=$g[1]; return 0 }

    # Oh My Zsh plugins only ever use <name>.plugin.zsh.
    [[ $dir == $PLUG_OMZ_DIR/* ]] && return 1

    for f in "$dir/$name.zsh" "$dir/init.zsh" "$dir/plugin.zsh" \
             "$dir/$name.zsh-theme"; do
        [[ -f $f ]] && { REPLY=$f; return 0 }
    done

    g=( $dir/*.zsh-theme(N[1]) )
    (( $#g )) && { REPLY=$g[1]; return 0 }

    return 1
}

# _plug_plugin_name <name>  ->  REPLY   (name used for source detection)
_plug_plugin_name() {
    if [[ $1 == omz:* ]]; then
        REPLY=${1#omz:}
    else
        REPLY=${${1:t}%.git}
    fi
}

_plug_commit_of() {
    REPLY=$(command git -C "$1" rev-parse HEAD 2>/dev/null)
}


# =============================================================================
# Storage: registry, disabled, lazy, defer, branches, evals, lock
# =============================================================================

_plug_init_dirs() {
    [[ -d $PLUG_PLUGIN_DIR && -d $PLUG_EVAL_DIR && -d $PLUG_COMP_DIR ]] ||
        command mkdir -p "$PLUG_PLUGIN_DIR" "$PLUG_EVAL_DIR" "$PLUG_COMP_DIR"
}

# _plug_read <file>  ->  reply   (trimmed lines, comments and blanks removed)
_plug_read() {
    emulate -L zsh
    setopt extended_glob
    reply=()
    [[ -r $1 ]] || return 0

    local line
    local -a raw=( "${(@f)$(<$1)}" )

    for line in "${raw[@]}"; do
        line=${${line##[[:space:]]##}%%[[:space:]]##}
        [[ -z $line || $line == \#* ]] && continue
        reply+=( "$line" )
    done
}

# _plug_write <file> <line>...   (atomic)
_plug_write() {
    emulate -L zsh
    local file=$1; shift
    local tmp="$file.tmp.$$"

    _plug_init_dirs
    : > "$tmp" || return 1
    (( $# )) && print -rl -- "$@" >> "$tmp"
    command mv -f "$tmp" "$file"
}

_plug_load_registry() {
    _plug_read "$PLUG_PLUGIN_FILE"
    PLUG_PLUGINS=( ${(u)reply} )
}

_plug_load_disabled() {
    emulate -L zsh
    local line
    PLUG_DISABLED=()
    _plug_read "$PLUG_DISABLED_FILE"
    for line in "${reply[@]}"; do PLUG_DISABLED[$line]=1; done
}

# lazy.txt line:  <name> <command> [<command>...]
_plug_load_lazy() {
    emulate -L zsh
    local line
    PLUG_LAZY=()
    _plug_read "$PLUG_LAZY_FILE"
    for line in "${reply[@]}"; do
        [[ $line == *' '* ]] || continue
        PLUG_LAZY[${line%% *}]=${line#* }
    done
}

# deferred.txt line:  <name> <milliseconds>
_plug_load_defer() {
    emulate -L zsh
    local line
    PLUG_DEFER=()
    _plug_read "$PLUG_DEFER_FILE"
    for line in "${reply[@]}"; do
        [[ $line == *' '* ]] || continue
        PLUG_DEFER[${line%% *}]=${line#* }
    done
}

# branches.txt line:  <name> <branch>
_plug_load_branches() {
    emulate -L zsh
    local line
    PLUG_BRANCH=()
    _plug_read "$PLUG_BRANCH_FILE"
    for line in "${reply[@]}"; do
        [[ $line == *' '* ]] || continue
        PLUG_BRANCH[${line%% *}]=${line#* }
    done
}

# evals.txt line:  <name> <command...>
_plug_load_evals() {
    emulate -L zsh
    local line
    PLUG_EVAL_NAMES=()
    PLUG_EVAL_CMDS=()
    _plug_read "$PLUG_EVAL_FILE"
    for line in "${reply[@]}"; do
        [[ $line == *' '* ]] || continue
        PLUG_EVAL_NAMES+=( "${line%% *}" )
        PLUG_EVAL_CMDS[${line%% *}]=${line#* }
    done
}

# lock line:  <name>|<branch>|<commit>
_plug_load_lock() {
    emulate -L zsh
    local line
    local -a f
    PLUG_LOCK_COMMIT=()
    PLUG_LOCK_BRANCH=()
    _plug_read "$PLUG_LOCK_FILE"
    for line in "${reply[@]}"; do
        f=( "${(@s:|:)line}" )
        [[ -n $f[1] && -n $f[3] ]] || continue
        PLUG_LOCK_BRANCH[$f[1]]=$f[2]
        PLUG_LOCK_COMMIT[$f[1]]=$f[3]
    done
}

_plug_load_all() {
    _plug_load_registry
    _plug_load_disabled
    _plug_load_lazy
    _plug_load_defer
    _plug_load_branches
    _plug_load_evals
}

_plug_save_registry() { _plug_write "$PLUG_PLUGIN_FILE" "${PLUG_PLUGINS[@]}" }
_plug_save_disabled() { _plug_write "$PLUG_DISABLED_FILE" "${(@ko)PLUG_DISABLED}" }

_plug_save_lazy() {
    emulate -L zsh
    local k
    local -a lines=()
    for k in "${(@ko)PLUG_LAZY}"; do lines+=( "$k ${PLUG_LAZY[$k]}" ); done
    _plug_write "$PLUG_LAZY_FILE" "${lines[@]}"
}

_plug_save_defer() {
    emulate -L zsh
    local k
    local -a lines=()
    for k in "${(@ko)PLUG_DEFER}"; do lines+=( "$k ${PLUG_DEFER[$k]}" ); done
    _plug_write "$PLUG_DEFER_FILE" "${lines[@]}"
}

_plug_save_branches() {
    emulate -L zsh
    local k
    local -a lines=()
    for k in "${(@ko)PLUG_BRANCH}"; do lines+=( "$k ${PLUG_BRANCH[$k]}" ); done
    _plug_write "$PLUG_BRANCH_FILE" "${lines[@]}"
}

_plug_save_evals() {
    emulate -L zsh
    local k
    local -a lines=()
    for k in "${PLUG_EVAL_NAMES[@]}"; do lines+=( "$k ${PLUG_EVAL_CMDS[$k]}" ); done
    _plug_write "$PLUG_EVAL_FILE" "${lines[@]}"
}

_plug_save_lock() {
    emulate -L zsh
    local k
    local -a lines=( "# plug.zsh lockfile" "# name|branch|commit" )
    for k in "${(@ko)PLUG_LOCK_COMMIT}"; do
        lines+=( "$k|${PLUG_LOCK_BRANCH[$k]}|${PLUG_LOCK_COMMIT[$k]}" )
    done
    _plug_write "$PLUG_LOCK_FILE" "${lines[@]}"
}

# Forget everything stored about a plugin.
_plug_forget() {
    local p=$1 k
    PLUG_PLUGINS=( "${PLUG_PLUGINS[@]:#${(b)p}}" )
    unset "PLUG_DISABLED[$p]" "PLUG_LAZY[$p]" "PLUG_DEFER[$p]" "PLUG_BRANCH[$p]" "PLUG_LOADED[$p]"
    _plug_lock_key "$p"; k=$REPLY
    # The shared omz lock entry stays while another omz plugin remains.
    if ! _plug_is_omz "$p" || (( ! ${#${(M)PLUG_PLUGINS:#omz:*}} )); then
        unset "PLUG_LOCK_COMMIT[$k]" "PLUG_LOCK_BRANCH[$k]"
    fi
}
