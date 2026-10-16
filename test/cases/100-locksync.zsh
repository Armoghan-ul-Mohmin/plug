# test/cases/100-locksync.zsh — lock exact commits and restore them with sync

t_register case_locksync "lock / sync"

case_locksync() {
    run 'plug lock'
    want 'Locked' 'lock writes the lockfile'
    have_file 'lockfile exists' "$PLUG_DIR/lock"

    run 'plug sync'
    want 'in sync' 'sync after lock is a no-op'

    # Introduce drift: add a local commit on top of the locked one.
    # (Clones are shallow, so we cannot rewind with HEAD~1.)
    local bug=$PLUG_DIR/plugins/user1__plug-b
    command git -C "$bug" -c user.email=t@t -c user.name=t commit -q --allow-empty -m drift

    run 'plug sync'
    want 'in sync' 'sync restores the locked commit'
}
