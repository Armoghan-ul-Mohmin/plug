#!/usr/bin/env zsh
# =============================================================================
#  plug.zsh — fast, beautiful, modular Zsh plugin manager              v1.0.1
# =============================================================================
#
#  Usage (in ~/.zshrc, BEFORE any compinit of your own):
#
#      source /path/to/plug.zsh        # keep the whole repo, lib/ sits next to it
#
#  What makes it fast
#    * Startup is `source cache.zsh`: literal `source /path` lines. No parsing,
#      no git, no gum, no subprocesses. Freshness is checked with `-nt` tests.
#    * Every command that changes state rebuilds the cache.
#    * Plugins are sourced at the TOP LEVEL of the cache (never inside a
#      function), so `typeset`, `local` and options behave like a hand-written
#      .zshrc.
#    * Turbo (defer) plugins load after the first prompt via zsh/sched or a
#      one-shot precmd hook, keeping perceived startup instant.
#
#  What you can manage
#    user/repo            GitHub plugin               plug install user/repo
#    user/repo@branch     pinned to a branch          plug install user/repo@dev
#    omz:name             Oh My Zsh plugin            plug install omz git sudo
#    your own files       .zsh file or directory      plug add ~/dotfiles/aliases.zsh
#    completions          _tool files, or generated   plug completion gen kubectl kubectl completion zsh
#    cached tool init     zoxide, starship, fzf ...   plug eval add zoxide zoxide init zsh
#    deferred (turbo)     load after first prompt     plug defer user/repo 1000
#
#  Settings (set BEFORE sourcing — every one of them is honoured)
#    PLUG_DIR            data directory      (~/.local/share/zsh)
#    PLUG_JOBS           parallel git jobs   (4)
#    PLUG_COMPINIT       1 = run compinit when needed (default 1, 0 = you do it)
#    PLUG_OMZ_LIB        OMZ lib files       (functions git clipboard)
#    PLUG_MAX_LOG_SIZE   log rotation size   (1048576)
#    PLUG_NO_AUTOLOAD    non-empty = only define functions, load nothing
#    PLUG_QUIET           1 = suppress info/ok messages
#
#  Requirements: zsh 5.3+, git (2.25+ for Oh My Zsh), gum (for the plug command;
#  your shell still starts fine without it, plugins load from the cache).
# =============================================================================


# =============================================================================
# Configuration  (all values respect anything you exported before sourcing)
# =============================================================================

typeset -g PLUG_VERSION="1.0.1"
typeset -g PLUG_SELF="${${(%):-%x}:A}"
typeset -g PLUG_ROOT="${PLUG_SELF:h}"

# Sourcing the same plug.zsh twice in one shell is a no-op (the state arrays
# below would otherwise be wiped and the plugins loaded a second time).
if [[ -n ${PLUG_LOADED_SELF-} && ${PLUG_LOADED_SELF} == $PLUG_SELF ]]; then
    return 0
fi
typeset -g PLUG_LOADED_SELF="$PLUG_SELF"

: ${PLUG_DIR:="$HOME/.local/share/zsh"}
typeset -g PLUG_DIR

: ${PLUG_PLUGIN_DIR:="$PLUG_DIR/plugins"}
: ${PLUG_PLUGIN_FILE:="$PLUG_DIR/plugins.txt"}
: ${PLUG_DISABLED_FILE:="$PLUG_DIR/disabled.txt"}
: ${PLUG_LAZY_FILE:="$PLUG_DIR/lazy.txt"}
: ${PLUG_DEFER_FILE:="$PLUG_DIR/deferred.txt"}
: ${PLUG_BRANCH_FILE:="$PLUG_DIR/branches.txt"}
: ${PLUG_EVAL_FILE:="$PLUG_DIR/evals.txt"}
: ${PLUG_EVAL_DIR:="$PLUG_DIR/evals"}
: ${PLUG_COMP_DIR:="$PLUG_DIR/completions"}
: ${PLUG_LOCK_FILE:="$PLUG_DIR/lock"}
: ${PLUG_CACHE_FILE:="$PLUG_DIR/cache.zsh"}
: ${PLUG_LOG_FILE:="$PLUG_DIR/plug.log"}
: ${PLUG_OMZ_DIR:="$PLUG_DIR/omz"}
typeset -g PLUG_PLUGIN_DIR PLUG_PLUGIN_FILE PLUG_DISABLED_FILE PLUG_LAZY_FILE
typeset -g PLUG_DEFER_FILE PLUG_BRANCH_FILE PLUG_EVAL_FILE PLUG_EVAL_DIR
typeset -g PLUG_COMP_DIR PLUG_LOCK_FILE PLUG_CACHE_FILE PLUG_LOG_FILE PLUG_OMZ_DIR

: ${PLUG_CACHE_DIR:="$HOME/.cache/zsh/plug"}
: ${PLUG_GIT_BASE:="https://github.com"}
: ${PLUG_OMZ_URL:="https://github.com/ohmyzsh/ohmyzsh.git"}
: ${PLUG_OMZ_CACHE_DIR:="$PLUG_CACHE_DIR/omz"}
: ${PLUG_OMZ_LIB:="functions git clipboard"}
typeset -g PLUG_CACHE_DIR PLUG_GIT_BASE PLUG_OMZ_URL PLUG_OMZ_CACHE_DIR PLUG_OMZ_LIB

: ${PLUG_COMPINIT:=${PLUG_OMZ_COMPINIT:-1}}
: ${PLUG_JOBS:=4}
: ${PLUG_MAX_LOG_SIZE:=1048576}
: ${PLUG_PROFILE:=0}
: ${PLUG_QUIET:=0}
typeset -gi PLUG_COMPINIT PLUG_JOBS PLUG_MAX_LOG_SIZE PLUG_PROFILE

typeset -ga PLUG_BROWSE_ITEMS=(
    'zsh-users/zsh-autosuggestions|fish-like suggestions for zsh'
    'zsh-users/zsh-syntax-highlighting|syntax highlighting for commands'
    'zsh-users/zsh-completions|additional zsh completions'
    'Aloxaf/fzf-tab|replace zsh completion menu with fzf'
    'zdharma-continuum/fast-syntax-highlighting|fast syntax highlighting'
    'MichaelAquilina/zsh-you-should-use|reminds you of existing aliases'
    'marlonrichert/zsh-autocomplete|real-time type-ahead completion'
    'romkatv/powerlevel10k|fast and highly customizable prompt'
    'zsh-users/zsh-history-substring-search|search history by substring'
    'chisui/zsh-nix-shell|nix-shell integration for zsh'
)


# =============================================================================
# State
# =============================================================================

typeset -ga PLUG_PLUGINS=()                 # registry, in load order
typeset -gA PLUG_DISABLED=()                # name -> 1
typeset -gA PLUG_LAZY=()                    # name -> "cmd cmd ..."
typeset -gA PLUG_DEFER=()                   # name -> milliseconds after prompt
typeset -gA PLUG_BRANCH=()                  # name -> pinned branch
typeset -gA PLUG_LOADED=()                  # name -> 1 (this shell)
typeset -gA PLUG_LOCK_COMMIT=()             # key  -> commit
typeset -gA PLUG_LOCK_BRANCH=()             # key  -> branch
typeset -ga PLUG_EVAL_NAMES=()              # cached tool inits, in order
typeset -gA PLUG_EVAL_CMDS=()               # name -> command

typeset -gi PLUG_OMZ_READY=0
typeset -gi PLUG_OMZ_LIBS=0
typeset -gi PLUG_COMPINIT_DONE=0

typeset -ga PLUG_PROF_NAMES=()
typeset -ga PLUG_PROF_TIMES=()
typeset -g  _plug_prof_t0=0
typeset -gi _plug_color=0
typeset -gi _plug_d_err=0
typeset -gi _plug_d_warn=0


# =============================================================================
# Load the library (this file is only the entry point)
# =============================================================================

if [[ ! -d $PLUG_ROOT/lib ]]; then
    print -u2 -r -- "plug.zsh: lib/ not found next to plug.zsh (expected: $PLUG_ROOT/lib)"
    print -u2 -r -- "          Keep the whole plug.zsh repository, not just the single file."
    return 1
fi

for _plug_lib in "$PLUG_ROOT"/lib/*.zsh(N); do
    source "$_plug_lib"
done
unset _plug_lib


# =============================================================================
# Startup
# =============================================================================
#
# Fast path: a handful of `-nt` tests and one `source`. This runs at the top
# level of your .zshrc, so plugins are sourced exactly as if you had written
# the `source` lines yourself. gum is NOT needed here.

if [[ -z $PLUG_NO_AUTOLOAD ]]; then
    _plug_cache_ok || _plug_build_cache >/dev/null 2>&1
    [[ -r $PLUG_CACHE_FILE ]] && source "$PLUG_CACHE_FILE"
fi
