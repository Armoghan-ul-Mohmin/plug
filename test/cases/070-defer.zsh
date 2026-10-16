# test/cases/070-defer.zsh — turbo (deferred) loading after the first prompt

t_register case_defer "defer (turbo loading)"

case_defer() {
    run 'plug defer user2/plug-c 50'
    want 'after your first prompt' 'defer is reported'
    file_has_line 'deferred.txt records the entry' "$PLUG_DIR/deferred.txt" 'user2/plug-c 50'
    file_has 'cache schedules the load via precmd' "$PLUG_DIR/cache.zsh" '_plug_pd_user2_plug_c'

    run '[[ ! -v _plug_test_user2_plug_c ]] && echo NOTYET; _plug_defer_fire user2/plug-c; [[ -v _plug_test_user2_plug_c ]] && echo TURBO'
    want 'NOTYET' 'deferred plugin is not loaded at startup'
    want 'TURBO'  'deferred plugin loads when fired'

    run 'plug defer user2/plug-c abc'
    want 'milliseconds' 'defer rejects a non-numeric delay'

    run 'plug undefer user2/plug-c'
    want 'startup' 'undefer is reported'
    run 'plug undefer user2/plug-c'
    want 'not deferred' 'undefer on a non-deferred plugin errors'

    run 'plug defer user2/plug-c 2000'
    want 'after your first prompt' 'defer >= 1s is accepted'
    file_has 'defer >= 1s uses zsh/sched' "$PLUG_DIR/cache.zsh" 'zsh/sched'
    run 'plug undefer user2/plug-c'
}
