#!/usr/bin/env zsh
# =============================================================================
#  test/run-tests.zsh — plug.zsh end-to-end test runner
# =============================================================================
#
#  Usage:
#      zsh test/run-tests.zsh                 # run every case
#      zsh test/run-tests.zsh install lazy    # only cases matching these globs
#      zsh test/run-tests.zsh --list          # list cases without running them
#
#  Everything runs offline in a throwaway sandbox (local bare git remotes and a
#  hand-built Oh My Zsh). Your real $HOME, .zshrc and $PLUG_DIR are never used.
#
#  Cases live in test/cases/*.zsh, one file per feature. See test/README.md.
# =============================================================================

emulate -L zsh
zmodload zsh/datetime
clear

REPO=${0:A:h:h}
export REPO
export TEST_ROOT=${TMPDIR:-/tmp}/plug.zsh-tests.$$
export HOME=$TEST_ROOT/home
export PLUG_DIR=$TEST_ROOT/data
export PLUG_GIT_BASE=$TEST_ROOT/base
export PLUG_OMZ_URL=$TEST_ROOT/omz.git
export ZDOTDIR=$TEST_ROOT/zdot

# Never run commit/push hooks (gitleaks, etc.) in the throwaway sandbox repos.
export GIT_CONFIG_COUNT=2
export GIT_CONFIG_KEY_0=core.hooksPath
export GIT_CONFIG_VALUE_0=/dev/null
export GIT_CONFIG_KEY_1=commit.gpgsign
export GIT_CONFIG_VALUE_1=false

cleanup() { command rm -rf "$TEST_ROOT" }
trap cleanup EXIT INT TERM

source "$REPO/test/lib/framework.zsh"
t_color_init

# ---------------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------------
local -a filters=()
local -i list_only=0
local a
for a in "$@"; do
    case $a in
        -l|--list) list_only=1 ;;
        -h|--help)
            print -r -- "usage: zsh test/run-tests.zsh [--list] [filter ...]"
            print -r -- "  filter  glob(s) matched against case function names and titles"
            exit 0 ;;
        *) filters+=( "$a" ) ;;
    esac
done

# ---------------------------------------------------------------------------
# Load every case (they only register themselves)
# ---------------------------------------------------------------------------
local f
for f in "$REPO"/test/cases/*.zsh(N); do
    source "$f"
done

# Apply filters (glob-matched against function name and title).
local -a selected=()
local fn title pat match
for fn in "${T_ORDER[@]}"; do
    title=${T_TITLES[$fn]}
    if (( ! $#filters )); then
        selected+=( "$fn" )
        continue
    fi
    match=0
    for pat in "${filters[@]}"; do
        [[ $fn == *${~pat}* || $title == *${~pat}* ]] && match=1
    done
    (( match )) && selected+=( "$fn" )
done

if (( list_only )); then
    print -r -- "available test cases (${#T_ORDER}):"
    for fn in "${T_ORDER[@]}"; do
        print -r -- "  $(printf '%-24s' "${fn#case_}") ${T_TITLES[$fn]}"
    done
    exit 0
fi

if (( ! $#selected )); then
    print -u2 -r -- "no test cases matched: ${(j:, :)filters}"
    exit 1
fi

t_banner "plug.zsh  ·  test suite" \
    "offline  ·  sandboxed  ·  ${#selected} case(s)"

# ---------------------------------------------------------------------------
# Build the sandbox
# ---------------------------------------------------------------------------
if (( $+commands[gum] )) && [[ -t 1 ]] && (( T_COLOR )); then
    if ! command gum spin --spinner dot --title "Preparing sandbox (local remotes, fake Oh My Zsh) …" \
            -- zsh -c "source '$REPO/test/lib/sandbox.zsh'; sandbox_build"
    then
        print -u2 -r -- "sandbox setup failed"
        exit 1
    fi
else
    print -r -- "$(t_dim "$T_I_RUN  preparing sandbox …")"
    source "$REPO/test/lib/sandbox.zsh"
    sandbox_build || { print -u2 -r -- "sandbox setup failed"; exit 1; }
fi

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
local -F t0=$EPOCHREALTIME
local -i idx=0 total=$#selected p0 f0
for fn in "${selected[@]}"; do
    (( ++idx ))
    _t_case_title=${T_TITLES[$fn]}
    t_section "$idx" "$total" "$_t_case_title"
    p0=$T_PASS; f0=$T_FAIL
    "$fn"
    t_case_footer $(( T_PASS - p0 )) $(( T_FAIL - f0 ))
done

t_summary $(( EPOCHREALTIME - t0 ))
exit $?
