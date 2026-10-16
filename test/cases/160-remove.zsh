# test/cases/160-remove.zsh — remove a plugin (with -y)

t_register case_remove "remove"

case_remove() {
    have_dir 'plug-c is installed before removal' "$PLUG_DIR/plugins/user2__plug-c"

    run 'plug remove -y user2/plug-c'
    want 'Removed' 'remove reports success'
    absent_file 'the git clone is deleted' "$PLUG_DIR/plugins/user2__plug-c"

    run 'plug list'
    no 'plug-c' 'the removed plugin no longer appears in list'

    run 'plug remove -y user2/nope'
    want 'not installed' 'removing an unknown plugin errors'
    expect 'removing an unknown plugin exits non-zero' '[[ $T_RC -ne 0 ]]'
}
