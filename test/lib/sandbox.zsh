# =============================================================================
#  test/lib/sandbox.zsh — build the isolated test sandbox
# =============================================================================
#
#  Everything lives under $TEST_ROOT (a throwaway dir): local bare git repos
#  stand in for GitHub, a hand-built repository stands in for Oh My Zsh, and a
#  private $HOME/$ZDOTDIR keeps the real environment untouched.
#
#  The runner exports these before calling sandbox_build:
#     REPO TEST_ROOT HOME PLUG_DIR PLUG_GIT_BASE PLUG_OMZ_URL ZDOTDIR
#
#  This file is self-contained so it can be run under `gum spin` in a subprocess.
# =============================================================================

emulate -L zsh

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

# make_repo <owner/repo> <marker-varname>
#   Creates a repo whose <name>.plugin.zsh sets <marker-varname> so the test can
#   detect that it was sourced.
make_repo() {
    local rel=$1 var=$2
    local dir=$TEST_ROOT/work/${rel//\//__}
    command rm -rf "$dir"; command mkdir -p "$dir"
    command git -C "$dir" init -q
    command git -C "$dir" config user.email t@t
    command git -C "$dir" config user.name t
    print -r -- "$var=1" > "$dir/${rel##*/}.plugin.zsh"
    command git -C "$dir" add .
    command git -C "$dir" commit -qm init
    command git -C "$dir" branch -M main
    command git clone -q --bare "$dir" "$PLUG_GIT_BASE/$rel.git"
    command git -C "$dir" remote add origin "$PLUG_GIT_BASE/$rel.git"
    command git -C "$dir" push -q -u origin main
}

# make_omz — a minimal Oh My Zsh checkout (lib/ + a few plugins/) as a bare repo.
make_omz() {
    local dir=$TEST_ROOT/work/omz
    command rm -rf "$dir"
    command mkdir -p "$dir/lib" "$dir/plugins/git" "$dir/plugins/docker" "$dir/plugins/sudo"
    print -r -- "# oh-my-zsh bootstrap" > "$dir/oh-my-zsh.sh"
    local l p
    for l in functions git clipboard; do print -r -- "# lib $l" > "$dir/lib/$l.zsh"; done
    for p in git docker sudo; do
        print -r -- "_plug_test_omz_$p=1" > "$dir/plugins/$p/$p.plugin.zsh"
    done
    command git -C "$dir" init -q
    command git -C "$dir" config user.email t@t
    command git -C "$dir" config user.name t
    command git -C "$dir" add .
    command git -C "$dir" commit -qm init
    command git -C "$dir" branch -M main
    command git clone -q --bare "$dir" "$PLUG_OMZ_URL"
}

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------
sandbox_build() {
    command rm -rf "$TEST_ROOT"
    command mkdir -p "$HOME" "$ZDOTDIR" "$PLUG_GIT_BASE/user1" "$PLUG_GIT_BASE/user2"

    make_repo user1/plug-a _plug_test_user1_plug_a
    make_repo user1/plug-b _plug_test_user1_plug_b
    make_repo user2/plug-c _plug_test_user2_plug_c
    make_omz

    # Install plug.zsh + lib into the sandbox (mirrors a real checkout).
    command cp "$REPO/plug.zsh" "$TEST_ROOT/plug.zsh"
    command rm -rf "$TEST_ROOT/lib"
    command cp -r "$REPO/lib" "$TEST_ROOT/lib"

    # Every `zsh -i` used by the tests sources this.
    command cat > "$ZDOTDIR/.zshrc" <<EOF
export PLUG_DIR=$PLUG_DIR
export PLUG_GIT_BASE=$PLUG_GIT_BASE
export PLUG_OMZ_URL=$PLUG_OMZ_URL
source $TEST_ROOT/plug.zsh
EOF
}

sandbox_cleanup() { command rm -rf "$TEST_ROOT"; }
