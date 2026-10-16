# =============================================================================
#  test/lib/framework.zsh — a tiny, colourful test framework for plug.zsh
# =============================================================================
#
#  Design goals: no dependencies (except gum for the banner/spinner, which
#  plug.zsh needs anyway), pretty output with colour + icons, and a flat,
#  readable API so a case file reads like a checklist.
#
#  A case file (test/cases/NNN-name.zsh) registers one function:
#
#      t_register case_name "human readable title"
#      case_name() {
#          run 'plug install user/repo'
#          want 'Installed' 'install reports success'
#          no  'Error'     'install prints no error'
#          have_file 'clone exists' "$PLUG_DIR/plugins/user__repo/.git"
#      }
#
#  The runner (test/run-tests.zsh) sources every case, then calls them in order.
#
# =============================================================================

emulate -L zsh

# ---------------------------------------------------------------------------
# Palette (256 colour) and icons
# ---------------------------------------------------------------------------
typeset -g T_ACCENT='38;5;141'
typeset -g T_OK='38;5;114'
typeset -g T_FAIL='38;5;204'
typeset -g T_SKIP='38;5;221'
typeset -g T_INFO='38;5;117'
typeset -g T_DIM='38;5;244'
typeset -g T_TEXT='38;5;252'

typeset -g T_I_OK=$'\uf00c'
typeset -g T_I_FAIL=$'\uf00d'
typeset -g T_I_SKIP=$'\uf05a'
typeset -g T_I_SEC=$'\uf0da'
typeset -g T_I_PLUG=$'\uf1e6'
typeset -g T_I_RUN=$'\uf04b'

typeset -gi T_COLOR=0

# Colour once: tty (or forced), and NO_COLOR not set. ASCII fallback icons when
# TEST_ASCII is set (terminals without a Nerd Font).
t_color_init() {
    T_COLOR=0
    if [[ -z $NO_COLOR ]] && { [[ -t 1 ]] || [[ -n $CLICOLOR_FORCE ]] || [[ -n $TEST_COLOR ]]; }; then
        T_COLOR=1
    fi
    if [[ -n $TEST_ASCII ]]; then
        T_I_OK='ok'; T_I_FAIL='x'; T_I_SKIP='-'; T_I_SEC='>'; T_I_PLUG='*'; T_I_RUN='>'
    fi
}

# t_c <ansi-code> <text...>
t_c() {
    local code=$1; shift
    if (( T_COLOR )); then
        print -rn -- $'\e['"$code"'m'"$*"$'\e[0m'
    else
        print -rn -- "$*"
    fi
}
t_dim()  { t_c "$T_DIM" "$@"; }
t_bold() { t_c "1;$T_ACCENT" "$@"; }

# ---------------------------------------------------------------------------
# Results
# ---------------------------------------------------------------------------
typeset -gi T_PASS=0 T_FAIL=0 T_SKIP=0
typeset -ga T_FAILED=()
typeset -g  T_OUT=
typeset -gi T_RC=0
typeset -g  _t_case_title=

# pass / fail / skip record a single check. `fail` remembers the case for the
# final report so failures are easy to find.
pass() { (( ++T_PASS )); print -r -- "  $(t_c "1;$T_OK" "$T_I_OK") $1"; }

fail() {
    (( ++T_FAIL ))
    T_FAILED+=( "${_t_case_title:-?}  ::  $1" )
    print -r -- "  $(t_c "1;$T_FAIL" "$T_I_FAIL") $(t_c "1;$T_FAIL" "$1")"
}

skip() {
    (( ++T_SKIP ))
    print -r -- "  $(t_c "$T_SKIP" "$T_I_SKIP") $(t_dim "$1 (skipped)")"
}

# _t_dump — print captured command output, indented and dim, on failure.
_t_dump() {
    local line
    [[ -n $T_OUT ]] || { print -r -- "$(t_dim '      <no output>')"; return; }
    while IFS= read -r line; do
        print -r -- "      $(t_dim "$line")"
    done <<< "$T_OUT"
}

# ---------------------------------------------------------------------------
# Running commands in the sandbox
# ---------------------------------------------------------------------------
# run "<shell command>"  ->  $T_OUT (stdout+stderr), $T_RC (exit code)
run() { T_OUT=$(command zsh -i -c "$1" 2>&1); T_RC=$?; }

# has <substring>  ->  true when $T_OUT contains it
has() { [[ $T_OUT == *$1* ]] }

# want <substring> <description>
want() {
    if has "$1"; then
        pass "$2"
    else
        fail "$2"
        print -r -- "    $(t_dim "expected to find: $1")"
        _t_dump
    fi
}

# no <substring> <description>
no() {
    if has "$1"; then
        fail "$2 (unexpectedly found)"
        _t_dump
    else
        pass "$2"
    fi
}

# expect <description> <shell-test...>   — evaluates the test in this shell
expect() {
    local desc=$1; shift
    if eval "$*" >/dev/null 2>&1; then pass "$desc"; else fail "$desc"; fi
}

# ---------------------------------------------------------------------------
# Filesystem assertions
# ---------------------------------------------------------------------------
have_file()    { [[ -e $2 ]] && pass "$1" || fail "$1  ($2 is missing)"; }
have_dir()     { [[ -d $2 ]] && pass "$1" || fail "$1  ($2 is not a directory)"; }
absent_file()  { [[ ! -e $2 ]] && pass "$1" || fail "$1  ($2 still exists)"; }
file_has()     { command grep -q -- "$3" "$2" 2>/dev/null && pass "$1" || fail "$1  ('$3' not in ${2:t})"; }
file_has_line(){ command grep -qxF -- "$3" "$2" 2>/dev/null && pass "$1" || fail "$1  (no line '$3' in ${2:t})"; }
file_lacks()   { command grep -q -- "$3" "$2" 2>/dev/null && fail "$1  ('$3' unexpectedly in ${2:t})" || pass "$1"; }

# file_mtime <path>  ->  prints epoch seconds (portable across GNU and BSD stat).
file_mtime() {
    command stat -c %Y "$1" 2>/dev/null || command stat -f %m "$1"
}

# ---------------------------------------------------------------------------
# Structure printed by the runner
# ---------------------------------------------------------------------------
t_rule() { local e=; print -r -- "  $(t_dim "${(l:64::─:)e}")"; }

t_banner() {
    local title=${1:-"plug.zsh"} sub=${2:-"test suite"}
    if (( T_COLOR )) && (( $+commands[gum] )) && [[ -t 1 ]]; then
        command gum style --border rounded --border-foreground 141 \
            --padding '0 3' --margin '1 0' \
            "$(t_bold "$T_I_PLUG  $title")" "$(t_dim "$sub")" </dev/null
    else
        print
        print -r -- "$(t_bold "$T_I_PLUG  $title")"
        print -r -- "$(t_dim "  $sub")"
        print
    fi
}

# t_section <index> <total> <title>
t_section() {
    print
    print -r -- "$(t_c "1;$T_ACCENT" "$T_I_SEC ${3}")  $(t_dim "[$1/$2]")"
    t_rule
}

# A short per-case footer, printed by the runner.
t_case_footer() {   # <passed-in-case> <failed-in-case>
    if (( $2 == 0 )); then
        print -r -- "  $(t_dim "summary: $1 check(s) passed")"
    else
        print -r -- "  $(t_c "1;$T_FAIL" "summary: $2 failed, $1 passed")"
    fi
}

# t_summary [<elapsed-seconds>]   ->  returns 0 when everything passed
t_summary() {
    local -F elapsed=${1:-0}
    local total=$(( T_PASS + T_FAIL + T_SKIP ))
    print

    if (( T_FAIL == 0 )); then
        local msg="$T_I_OK  $T_PASS passed"
        (( T_SKIP )) && msg+="    $T_SKIP skipped"
        msg+="    (${total} checks in $(printf '%.2f' $elapsed)s)"
        if (( T_COLOR )) && (( $+commands[gum] )) && [[ -t 1 ]]; then
            command gum style --border rounded --border-foreground 114 \
                --padding '0 3' --margin '1 0' "$(t_c "1;$T_OK" "$msg")" </dev/null
        else
            print -r -- "$(t_c "1;$T_OK" "$msg")"
        fi
        return 0
    fi

    print -r -- "$(t_c "1;$T_FAIL" "$T_I_FAIL  Failed checks")"
    local f
    for f in "${T_FAILED[@]}"; do
        print -r -- "  $(t_c "1;$T_FAIL" "$T_I_FAIL") $f"
    done
    print

    local msg="$T_I_FAIL  $T_FAIL failed    $T_I_OK  $T_PASS passed"
    (( T_SKIP )) && msg+="    $T_I_SKIP  $T_SKIP skipped"
    msg+="    (${total} checks in $(printf '%.2f' $elapsed)s)"
    if (( T_COLOR )) && (( $+commands[gum] )) && [[ -t 1 ]]; then
        command gum style --border rounded --border-foreground 204 \
            --padding '0 3' --margin '1 0' "$(t_c "1;$T_FAIL" "$msg")" </dev/null
    else
        print -r -- "$(t_c "1;$T_FAIL" "$msg")"
    fi
    return 1
}

# ---------------------------------------------------------------------------
# Case registry (used by test/cases/*.zsh)
# ---------------------------------------------------------------------------
typeset -ga T_ORDER=()
typeset -gA T_TITLES=()

# t_register <function-name> <title>
t_register() {
    T_ORDER+=( "$1" )
    T_TITLES[$1]=$2
}
