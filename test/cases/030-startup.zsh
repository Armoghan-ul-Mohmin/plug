# test/cases/030-startup.zsh — plugins are sourced at shell startup

t_register case_startup "startup loading"

case_startup() {
    run '[[ -v _plug_test_user1_plug_a ]] && echo AOK; [[ -v _plug_test_omz_docker ]] && echo OMZOK'
    want 'AOK'   'git plugin loads at startup'
    want 'OMZOK' 'omz plugin loads at startup'
}
