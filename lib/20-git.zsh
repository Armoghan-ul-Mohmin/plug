# =============================================================================
#  lib/20-git.zsh — git plumbing, clone, Oh My Zsh checkout, update scripts
# =============================================================================


typeset -g _plug_sh_git='log=$1; shift; export GIT_TERMINAL_PROMPT=0; { printf "+ git %s\n" "$*"; git "$@"; } >>"$log" 2>&1'

typeset -g _plug_sh_omz='log=$1; export GIT_TERMINAL_PROMPT=0; { git clone --depth 1 --filter=blob:none --sparse --single-branch "$2" "$3" && git -C "$3" sparse-checkout set lib plugins; } >>"$log" 2>&1'

# Fast-forwards a shallow clone to the tip of a branch and prints
# "<old> <new>" short hashes. Also repairs a detached HEAD left by `plug sync`.
# $1 = dir, $2 = optional pinned branch.
typeset -g _plug_sh_update='
dir=$1
branch=$2
cd "$dir" || exit 1
export GIT_TERMINAL_PROMPT=0
old=$(git rev-parse --short HEAD 2>/dev/null)
if [ -n "$branch" ]; then
    git fetch --quiet --depth=1 origin "$branch" &&
    git checkout --quiet -f -B "$branch" FETCH_HEAD || exit 1
else
    b=$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null)
    b=${b#origin/}
    if [ -n "$b" ]; then
        git fetch --quiet --depth=1 origin "$b" &&
        git checkout --quiet -f -B "$b" FETCH_HEAD || exit 1
    else
        git fetch --quiet --depth=1 origin HEAD &&
        git checkout --quiet -f --detach FETCH_HEAD || exit 1
    fi
fi
new=$(git rev-parse --short HEAD 2>/dev/null)
echo "$old $new"
'

# Moves a clone to an exact commit (detached).
typeset -g _plug_sh_sync='
log=$1; dir=$2; commit=$3
export GIT_TERMINAL_PROMPT=0
{
    cd "$dir" || exit 1
    git cat-file -e "$commit^{commit}" 2>/dev/null ||
        git fetch --quiet --depth=1 origin "$commit" ||
        git fetch --quiet --unshallow origin ||
        git fetch --quiet origin
    git checkout --quiet -f --detach "$commit"
} >>"$log" 2>&1
'

# _plug_git <spinner title> <git args...>
_plug_git() {
    local title=$1; shift
    _plug_init_dirs
    _plug_spin "$title" sh -c "$_plug_sh_git" sh "$PLUG_LOG_FILE" "$@"
}

_plug_clone() {
    local repo=$1 dir branch
    _plug_dir "$repo"; dir=$REPLY
    branch=${PLUG_BRANCH[$repo]}

    [[ -d $dir/.git ]] && return 0
    [[ -e $dir ]] && command rm -rf -- "$dir"

    local -a args=( clone --depth 1 --single-branch )
    [[ -n $branch ]] && args+=( -b "$branch" )

    if ! _plug_git "$PLUG_ICON_GIT  Cloning $repo${branch:+@$branch}" \
            "${args[@]}" "$PLUG_GIT_BASE/$repo.git" "$dir"
    then
        _plug_log ERROR "clone failed: $repo"
        _plug_err "Failed to clone $repo  (see: plug logs)"
        command rm -rf -- "$dir"
        return 1
    fi
}

_plug_omz_ensure() {
    [[ -e $PLUG_OMZ_DIR/.git ]] && return 0
    _plug_need git || return 1
    _plug_init_dirs
    [[ -e $PLUG_OMZ_DIR ]] && command rm -rf -- "$PLUG_OMZ_DIR"

    if ! _plug_spin "$PLUG_ICON_GIT  Cloning Oh My Zsh (lib + plugins only)" \
            sh -c "$_plug_sh_omz" sh "$PLUG_LOG_FILE" "$PLUG_OMZ_URL" "$PLUG_OMZ_DIR"
    then
        _plug_log ERROR "clone failed: Oh My Zsh"
        _plug_err "Failed to clone Oh My Zsh  (sparse checkout needs git 2.25+; see: plug logs)"
        command rm -rf -- "$PLUG_OMZ_DIR"
        return 1
    fi
}

# Collapses a list of plugin names for git operations: all omz:* become one
# "omz" target and local files are skipped.   _plug_targets <name>...  ->  reply
_plug_targets() {
    emulate -L zsh
    local p
    local -i seen=0
    reply=()
    for p in "$@"; do
        case $p in
            local:*) ;;
            omz:*)
                (( seen )) && continue
                seen=1
                reply+=( omz )
                ;;
            omz)
                (( seen )) && continue
                seen=1
                reply+=( omz )
                ;;
            *) reply+=( "$p" ) ;;
        esac
    done
}
