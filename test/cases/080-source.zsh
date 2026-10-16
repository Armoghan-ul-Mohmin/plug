# test/cases/080-source.zsh — load a plugin into the current shell

t_register case_source "source into the current shell"

case_source() {
    run 'plug source user1/plug-b; [[ -v _plug_test_user1_plug_b ]] && echo SOURCED'
    want 'SOURCED' 'source loads the plugin into the current shell'
}
