#!/usr/bin/env zsh
# =============================================================================
#  plug.zsh — fast, beautiful, modular Zsh plugin manager              v1.0.0
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
#
#  Requirements: zsh 5.3+, git (2.25+ for Oh My Zsh), gum (for the plug command;
#  your shell still starts fine without it, plugins load from the cache).
# =============================================================================


# =============================================================================
# Configuration  (all values respect anything you exported before sourcing)
# =============================================================================

typeset -g PLUG_VERSION="1.0.0"
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

: ${PLUG_JOBS:=4}
: ${PLUG_COMPINIT:=1}
: ${PLUG_OMZ_LIB:="functions git clipboard"}
: ${PLUG_MAX_LOG_SIZE:=1048576}
: ${PLUG_NO_AUTOLOAD:=}

typeset -g PLUG_PLUGIN_DIR="$PLUG_DIR/plugins"
typeset -g PLUG_PLUGIN_FILE="$PLUG_DIR/plugins.txt"
typeset -g PLUG_DISABLED_FILE="$PLUG_DIR/disabled.txt"
typeset -g PLUG_LAZY_FILE="$PLUG_DIR/lazy.txt"
typeset -g PLUG_DEFER_FILE="$PLUG_DIR/deferred.txt"
typeset -g PLUG_BRANCH_FILE="$PLUG_DIR/branches.txt"
typeset -g PLUG_EVAL_FILE="$PLUG_DIR/evals.txt"
typeset -g PLUG_EVAL_DIR="$PLUG_DIR/evals"
typeset -g PLUG_COMP_DIR="$PLUG_DIR/completions"
typeset -g PLUG_LOCK_FILE="$PLUG_DIR/lock"
typeset -g PLUG_CACHE_FILE="$PLUG_DIR/cache.zsh"
typeset -g PLUG_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/plug"

# Source modules in numeric order.
local f
for f in "$PLUG_ROOT"/lib/*.zsh(N); do
    source "$f"
done

# Fast path: source generated cache if it exists and is newer than plugins.
if [[ -r $PLUG_CACHE_FILE && $PLUG_CACHE_FILE -nt $PLUG_PLUGIN_FILE ]]; then
    source "$PLUG_CACHE_FILE"
fi
