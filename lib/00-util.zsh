# =============================================================================
#  lib/00-util.zsh — palette, output, gum helpers, logging
# =============================================================================


# =============================================================================
# Palette (256 colour) and Nerd Font icons
# =============================================================================

typeset -g PLUG_C_ACCENT='38;5;141'
typeset -g PLUG_C_OK='38;5;114'
typeset -g PLUG_C_WARN='38;5;221'
typeset -g PLUG_C_ERR='38;5;204'
typeset -g PLUG_C_INFO='38;5;117'
typeset -g PLUG_C_DIM='38;5;244'
typeset -g PLUG_C_TEXT='38;5;252'

typeset -g PLUG_ICON_OK=$'\uf00c'
typeset -g PLUG_ICON_FAIL=$'\uf00d'
typeset -g PLUG_ICON_INFO=$'\uf05a'
typeset -g PLUG_ICON_WARN=$'\uf071'
typeset -g PLUG_ICON_PLUGIN=$'\uf1e6'
typeset -g PLUG_ICON_GIT=$'\uf1d3'
typeset -g PLUG_ICON_UPDATE=$'\uf021'
typeset -g PLUG_ICON_REMOVE=$'\uf1f8'
typeset -g PLUG_ICON_INSTALL=$'\uf019'
typeset -g PLUG_ICON_DOCTOR=$'\uf0f1'
typeset -g PLUG_ICON_CLEAN=$'\uf12d'
typeset -g PLUG_ICON_FOLDER=$'\uf07b'
typeset -g PLUG_ICON_FILE=$'\uf15b'
typeset -g PLUG_ICON_CLOCK=$'\uf017'
typeset -g PLUG_ICON_DISABLED=$'\uf05e'
typeset -g PLUG_ICON_LAZY=$'\uf236'
typeset -g PLUG_ICON_LOG=$'\uf15c'
typeset -g PLUG_ICON_CACHE=$'\uf1c0'
typeset -g PLUG_ICON_LOCK=$'\uf023'
typeset -g PLUG_ICON_SYNC=$'\uf0ec'
typeset -g PLUG_ICON_HEALTH=$'\uf21e'
typeset -g PLUG_ICON_PROFILE=$'\uf0e4'
typeset -g PLUG_ICON_ARROW=$'\uf054'
typeset -g PLUG_ICON_ADD=$'\uf067'
typeset -g PLUG_ICON_EVAL=$'\uf120'
typeset -g PLUG_ICON_COMP=$'\uf085'
typeset -g PLUG_ICON_EDIT=$'\uf040'
typeset -g PLUG_ICON_CLOUD=$'\uf0ed'
typeset -g PLUG_ICON_DEFER=$'\uf252'
typeset -g PLUG_ICON_BRANCH=$'\uf126'


# =============================================================================
# Output helpers (gum is required for the `plug` command)
# =============================================================================

# Colour is decided once per command (see plug()), because `[[ -t 1 ]]` is
# false inside $( ... ).
_plug_c() {
    local code=$1; shift
    if (( _plug_color )); then
        print -rn -- $'\e['"$code"'m'"$*"$'\e[0m'
    else
        print -rn -- "$*"
    fi
}

_plug_dim() { _plug_c "$PLUG_C_DIM" "$@" }

# _plug_force counts active requests to show output regardless of PLUG_QUIET.
# Read-only report commands (doctor, status, list, …) set it so that silencing
# .zshrc chatter never hides diagnostics a user asked for interactively.
typeset -gi _plug_force=0

_plug_say() {
    local code=$1 icon=$2; shift 2
    # Suppress ok/info when quiet; keep warn/err
    if (( PLUG_QUIET && ! _plug_force )); then
        case $icon in
            "$PLUG_ICON_OK"|"$PLUG_ICON_INFO") return 0 ;;
        esac
    fi
    print -r -- "$(_plug_c "1;$code" "$icon")  $*"
}

_plug_ok()   { _plug_say "$PLUG_C_OK"   "$PLUG_ICON_OK"   "$@" }
_plug_info() { _plug_say "$PLUG_C_INFO" "$PLUG_ICON_INFO" "$@" }
_plug_warn() { _plug_say "$PLUG_C_WARN" "$PLUG_ICON_WARN" "$@" }
_plug_err()  { _plug_say "$PLUG_C_ERR"  "$PLUG_ICON_FAIL" "$@" >&2 }

_plug_tty() { [[ -t 1 ]] }

# Decide colour once: tty, not disabled, sane terminal.
_plug_color_init() {
    _plug_color=0
    [[ -t 1 && -z $NO_COLOR && $TERM != dumb ]] && _plug_color=1
}

# _plug_rule <width>
_plug_rule() {
    local e=
    print -r -- "  $(_plug_dim ${(l:$1::─:)e})"
}

_plug_section() {
    print
    print -r -- "$(_plug_c "1;$PLUG_C_ACCENT" "$1  $2")"
}

_plug_banner() {
    local sub=${1:-fast  ·  minimal  ·  beautiful}
    command gum style --border rounded --border-foreground 141 \
        --padding '0 3' --margin '1 0' \
        "$(_plug_c "1;$PLUG_C_ACCENT" "$PLUG_ICON_PLUGIN  plug")  $(_plug_dim "v$PLUG_VERSION")" \
        "$(_plug_dim "$sub")" </dev/null
}

# _plug_box <gum colour number> <line>...
_plug_box() {
    local colour=$1; shift
    command gum style --border rounded --border-foreground "$colour" \
        --padding '0 2' --margin '1 0 0 0' "$@" </dev/null
}

# Spinner for external commands (gum cannot run shell functions).
_plug_spin() {
    local title=$1; shift
    if _plug_tty; then
        command gum spin --spinner dot --title "$title" -- "$@" </dev/null
    else
        print -r -- "$title" >&2
        "$@" </dev/null
    fi
}

_plug_confirm() {
    [[ -t 0 && -t 1 ]] || return 1
    command gum confirm "$1"
}

_plug_need() {
    (( $+commands[$1] )) && return 0
    _plug_err "Required command not found: $1"
    return 1
}


# =============================================================================
# Logging
# =============================================================================

_plug_log() {
    emulate -L zsh
    local level=$1; shift
    [[ -d $PLUG_DIR ]] || command mkdir -p "$PLUG_DIR" 2>/dev/null

    local -a big=( $PLUG_LOG_FILE(N.L+$PLUG_MAX_LOG_SIZE) )
    (( $#big )) && command mv -f "$PLUG_LOG_FILE" "$PLUG_LOG_FILE.old" 2>/dev/null

    local ts
    zmodload -F zsh/datetime b:strftime 2>/dev/null
    strftime -s ts '%Y-%m-%d %H:%M:%S' 2>/dev/null

    print -r -- "[$ts] [$level] $*" >> "$PLUG_LOG_FILE" 2>/dev/null
}
