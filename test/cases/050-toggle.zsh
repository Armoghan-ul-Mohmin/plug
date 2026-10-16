# test/cases/050-toggle.zsh — enable / disable, including no-op detection

t_register case_toggle "enable / disable (no-op detection)"

case_toggle() {
    run 'plug disable user1/plug-a'
    want 'Disabled' 'disable is reported'
    have_file 'disabled.txt is written' "$PLUG_DIR/disabled.txt"

    run '[[ -v _plug_test_user1_plug_a ]] && echo STILLLOAD'
    no 'STILLLOAD' 'disabled plugin is not loaded'

    # Re-disabling must be a no-op and must not rebuild the cache.
    local t1 t2
    t1=$(file_mtime "$PLUG_DIR/cache.zsh")
    command sleep 1
    run 'plug disable user1/plug-a'
    want 'already disabled' 're-disabling is a no-op'
    t2=$(file_mtime "$PLUG_DIR/cache.zsh")
    [[ $t1 == $t2 ]] && pass 'no-op disable does not rebuild the cache' \
                     || fail 'no-op disable does not rebuild the cache'

    run 'plug enable user1/plug-a'
    want 'Enabled' 'enable is reported'
    run '[[ -v _plug_test_user1_plug_a ]] && echo BACK'
    want 'BACK' 're-enabled plugin loads at startup'
}
