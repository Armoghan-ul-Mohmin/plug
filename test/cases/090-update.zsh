# test/cases/090-update.zsh — update and outdated (with a new upstream commit)

t_register case_update "update / outdated"

case_update() {
    run 'plug update'
    want 'up to date' 'update reports an up-to-date plugin set'

    # Push a new commit to plug-a upstream.
    local up=$TEST_ROOT/work/user1__plug-a
    print -r -- "x=1" > "$up/extra.zsh"
    command git -C "$up" add .
    command git -C "$up" commit -qm second
    command git -C "$up" push -q origin main

    run 'plug update user1/plug-a'
    want 'updated' 'update pulls a new upstream commit'

    run 'plug outdated'
    want 'up to date' 'outdated reports nothing behind'

    # Make plug-b behind.
    local upb=$TEST_ROOT/work/user1__plug-b
    print -r -- "y=1" > "$upb/extra.zsh"
    command git -C "$upb" add .
    command git -C "$upb" commit -qm second
    command git -C "$upb" push -q origin main

    run 'plug outdated'
    want 'update available' 'outdated detects a plugin behind'

    run 'plug outdated user1/plug-b'
    want 'update available' 'outdated ignores extra args and still runs'
}
