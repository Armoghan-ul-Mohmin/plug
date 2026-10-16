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

typeset -g PLUG_ICON_OK=$''
typeset -g PLUG_ICON_FAIL=$''
typeset -g PLUG_ICON_INFO=$''
typeset -g PLUG_ICON_WARN=$''
typeset -g PLUG_ICON_PLUGIN=$''
typeset -g PLUG_ICON_GIT=$''
typeset -g PLUG_ICON_UPDATE=$''
typeset -g PLUG_ICON_REMOVE=$''
typeset -g PLUG_ICON_INSTALL=$''
typeset -g PLUG_ICON_DOCTOR=$''
typeset -g PLUG_ICON_CLEAN=$''
typeset -g PLUG_ICON_FOLDER=$''
typeset -g PLUG_ICON_FILE=$''
typeset -g PLUG_ICON_CLOCK=$''
typeset -g PLUG_ICON_DISABLED=$''
typeset -g PLUG_ICON_LAZY=$''
typeset -g PLUG_ICON_LOG=$''
typeset -g PLUG_ICON_CACHE=$''
typeset -g PLUG_ICON_LOCK=$''
typeset -g PLUG_ICON_SYNC=$''
typeset -g PLUG_ICON_HEALTH=$''
typeset -g PLUG_ICON_PROFILE=$''
typeset -g PLUG_ICON_ARROW=$''
typeset -g PLUG_ICON_ADD=$''
typeset -g PLUG_ICON_EVAL=$''
typeset -g PLUG_ICON_COMP=$''
typeset -g PLUG_ICON_EDIT=$''
typeset -g PLUG_ICON_CLOUD=$''
typeset -g PLUG_ICON_DEFER=$''
typeset -g PLUG_ICON_BRANCH=$''


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

_plug_say() {
    local code=$1 icon=$2; shift 2
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
