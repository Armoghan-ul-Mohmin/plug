# test/cases/060-lazy.zsh — lazy loading on first use of a trigger command

t_register case_lazy "lazy loading"

case_lazy() {
    run 'plug lazy user1/plug-b faketool'
    want 'will load on first use' 'lazy is reported'
    file_has_line 'lazy.txt records the entry' "$PLUG_DIR/lazy.txt" 'user1/plug-b faketool'

    run '[[ ! -v _plug_test_user1_plug_b ]] && echo NOTLOADED; faketool >/dev/null 2>&1; [[ -v _plug_test_user1_plug_b ]] && echo LAZYLOADED'
    want 'NOTLOADED'  'lazy plugin is not loaded at startup'
    want 'LAZYLOADED' 'lazy plugin loads on first trigger'

    run 'plug unlazy user1/plug-b'
    want 'startup' 'unlazy is reported'
    run '[[ -v _plug_test_user1_plug_b ]] && echo EAGER'
    want 'EAGER' 'unlazy plugin loads at startup'

    run 'plug lazy user1/plug-b'
    want 'Usage' 'lazy without a command shows usage'
}
